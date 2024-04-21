 # Define macros for conditional compilation.
# Support customization in the Makefile files for each project separately.
# And also support customization in common.mk

# SYSCALL在后续的项目中会定义，其值定义为 y, 因此当该值为y时，表示，需要链接SYSCALL
ifeq (${SYSCALL}, y)
DEFS += -DCONFIG_SYSCALL
endif
