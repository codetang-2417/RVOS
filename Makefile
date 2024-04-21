SECTIONS = 00-bootstrap

.DEFAULT_GOAL : all

all:
	@echo "Begin to compile all directories under this project."
	for dir in $(SECTIONS); do $(MAKE) -C $$dir || exit "$$?"; done # -C选项更改make的目录
	@echo "Compile done." # 加@在echo前，不打印 “echo”

.PHONY : clean # 这是一个伪目标，不依赖于任何文件
clean:
	@echo "Begin to clean up comiled files."
	for dir in $(SECTIONS); do $(MAKE) -C $$dir clean || exit "$$?"; done
	@echo "Cleanup done."

