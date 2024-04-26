#include "types.h"
#include "platform.h"


#define UART_REG(reg) ((volatile uint8_t *)(UART0 + reg))
/*
 * POWER UP DEFAULTS
 * IER = 0: TX/RX holding register interrupts are both disabled
 * ISR = 1: no interrupt penting
 * LCR = 0
 * MCR = 0
 * LSR = 60 HEX
 * MSR = BITS 0-3 = 0, BITS 4-7 = inputs
 * FCR = 0
 * TX = High
 * OP1 = High
 * OP2 = High
 * RTS = High
 * DTR = High
 * RXRDY = High
 * TXRDY = Low
 * INT = Low
 */

/*
 * LINE STATUS REGISTER (LSR)
 * LSR BIT 0:
 * 0 = no data in receive holding register or FIFO.
 * 1 = data has been receive and saved in the receive holding register or FIFO.
 * ......
 * LSR BIT 5:
 * 0 = transmit holding register is full. 16550 will not accept any data for transmission.
 * 1 = transmitter hold register (or FIFO) is empty. CPU can load the next character.
 * ......
 */

// uint8_t rbr; /* receive register */
// uint8_t thr; /* transmit holding register */
// uint8_t tsr; /* transmit shift register */
// uint8_t ier;
// uint8_t iir; /* read only */
// uint8_t lcr;
// uint8_t mcr;
// uint8_t lsr; /* read only */
// uint8_t msr; /* read only */
// uint8_t scr;
// uint8_t fcr;

#define UART_RBR 0  // Receive Holding Register (read mode)
#define UART_THR 0  // Transmit holding register (wirte mode)
#define UART_DLL 0  // LSB of Divisor Latch (write mode), when the internal baud rate counter latch enable (DLAB).
#define UART_DLM 1  // MSB of Divisor Latch (write mode), when the internal baud rate counter latch enable (DLAB).
#define UART_IER 1  // Interrupt Enable Register
// #define UART_IIR    // read only, INTERRUPT IDENTIFICATION REG
#define UART_FCR 2  //
#define UART_ISR 2  //
#define UART_LCR 3  // Line Control Register
#define UART_MCR 4  //
#define UART_LSR 5  // Line Status Register
#define UART_MSR 6  // Modem Status Register
#define UART_SPR 7  // ScratchPad Register

#define read_reg(reg) (*UART_REG(reg))
#define write_reg(reg, val) (*UART_REG(reg)=val)

	/*
	 * Setting baud rate. Just a demo here if we care about the divisor,
	 * but for our purpose [QEMU-virt], it's not going to be what we expected.
	 *
	 * Notice that the divisor register DLL (divisor latch least) and DLM (divisor
	 * latch most) have the same base address as the receiver/transmitter and the
	 * interrupt enable register. To change what the base address points to, we
	 * open the "divisor latch" by writing 1 into the Divisor Latch Access Bit
	 * (DLAB), which is bit index 7 of the Line Control Register (LCR).
	 *
	 * Regarding the baud rate value, see [1] "BAUD RATE GENERATOR PROGRAMMING TABLE".
	 * We use 38.4K when 1.8432 MHZ crystal, so the corresponding value is 3.
	 * And due to the divisor register is two bytes (16 bits), so we need to
	 * split the value of 3(0x0003) into two bytes, DLL stores the low byte,
	 * DLM stores the high byte.
	 */

void uart_init(){
    uint16_t divisor = 1843200/(38400*16);

    write_reg(UART_IER, 0x00);

    uint8_t lcr = read_reg(UART_LCR);// 先读出lcr寄存器的值，需要保存不需要置位的值
    write_reg(UART_LCR, lcr|(1<<7));
    write_reg(UART_DLL, (uint8_t)(divisor&0xff));
    write_reg(UART_DLM, (uint8_t)(divisor>>8));
    /*
	 * Continue setting the asynchronous data communication format.
	 * - number of the word length: 8 bits
	 * - number of stop bits：1 bit when word length is 8 bits
	 * - no parity
	 * - no break control
	 * - disabled baud latch
	 */
    write_reg(UART_LCR, 0X03);// 不需要保存其他值了
}

#define LSR_RX_READY (1 << 0)
#define LSR_TX_IDLE (1<<5)
void uart_putc(char ch){
    while((read_reg(UART_LSR)&LSR_TX_IDLE) == 0);
    write_reg(UART_THR, ch);
}

void uart_puts(char *string){
    while(*string)
        uart_putc(*string++);
}
