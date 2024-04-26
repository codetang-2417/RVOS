# 通用编译Makefile
# 被主Makefile包含才能正常使用
# 本项目中，将被各个子文件中的Makefile包含

# 这里使用 ..是因为本文件被子文件的makefile所包含，defines在根目录下，因此相对于子文件夹来说，defines在上层文件夹中
include ../defines.mk

# 防止该值未定义
DEFS +=

CROSS_COMPILE = riscv64-unknown-elf-
CFLAGS += -nostdlib -fno-builtin -g -Wall
CFLAGS += -march=rv32g -mabi=ilp32
LDFLAGS ?= -T os.ld

QEMU = /usr/local/bin/qemu/qemu_nopmp/qemu-system-riscv32
QFLAGS = -nographic -smp 1 -machine virt -bios none

GDB = gdb-multiarch
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump

OUTPUT_PATH = build

# SRCS_ASM & SRCS_C 定义在每个子项目中的Makefile中，因为每个子项目的文件不一定相同。

# 使用:=复制，可以立即复制，而不是相=那样，整个文件都解析后才赋最后的一个值
OBJS_ASM := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.S, %.o, ${SRCS_ASM}))
OBJS_C := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.c, %.o, ${SRCS_C}))
OBJS = ${OBJS_ASM} ${OBJS_C}

ELF = $(OUTPUT_PATH)/os.elf
BIN = $(OUTPUT_PATH)/os.bin

.DEFAULT_GOAL := all
all: ${OUTPUT_PATH} ${ELF}

# 这里使用的是变量OUTPUT_PATH的值作为目标，也就是说目标实际上是 build
# -p选项将自动创建路径中包含的所有子文件夹
${OUTPUT_PATH}:
	mkdir -p $@

${ELF}:${OBJS}
	$(CC) $(CFLAGS) $(LDFLAGS) -o ${ELF} $^
	${OBJCOPY} -O binary ${ELF} ${BIN}

${OUTPUT_PATH}/%.o:%.S
	$(CC) ${DEFS} ${CFLAGS} -c -o $@ $<

${OUTPUT_PATH}/%.o:%.c
	$(CC) ${DEFS} ${CFLAGS} -c -o $@ $<


# QEMU中支持virt才能运行，否则退出
.PHONY : run
run: all
	@${QEMU} -M \? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF}


# QEMU中支持virt才能运行，否则退出
.PHONY : debug
debug: all
	@${QEMU} -M \? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF} -S -s &
	${GDB} --tui ${ELF} -q -x ../gdbinit

.PHONY : code # 反汇编
code: all
	${OBJDUMP} -S ${ELF} | less

.PHONY : clean
clean:
	rm -rf ${OUTPUT_PATH}
