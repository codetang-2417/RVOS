#include "platform.h"
    .global _start

	# size of each hart's stack is 1024 bytes
	.set	STACK_SIZE, 1024

    .text
_start:
    csrr t0,mhartid # 读取hartid，通常以0开始
    mv tp,t0        # 待定，为什么需要移到tp
    bnez tp,park

    slli t0,t0,10   # 每个hart给1024字节的栈空间，则hartid左移1024，就是

    # 将栈指针存放到栈的底部，也就是栈的最高地址，栈向低地址增长
    la	sp, stacks + STACK_SIZE
    add sp,sp,t0

    j start_kernel  # 因为不需要返回，所以直接用j


# park有停车场的意思，此处意指hart在这里停放，即不工作
park:
    wfi     # 等待中断，即低功耗状态
    j park

.balign 16
stacks:
    .skip STACK_SIZE * MAXNUM_CPU    # 为每一个hart都开辟栈空间空间，并填充为0
    .end
