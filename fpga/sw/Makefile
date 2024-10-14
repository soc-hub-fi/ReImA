# ------------------------------------------------------------------------------
# Vector-Crypto Subsystem (Marian) FPGA Prototype SW Makefile
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 27-jan-2024
#
# Description: Top Makefile for the software build flow of Marian
# ------------------------------------------------------------------------------

# test to be built
TEST          ?= hello_world
# RISCV GCC install path

# path to tools
RISCV_DIR_GCC  ?=
RISCV_DIR_LLVM ?=
GCC_CC_DIR     := $(RISCV_DIR_GCC)/bin
LLVM_CC_DIR    := $(RISCV_DIR_LLVM)/bin
GCC_CC         ?= $(GCC_CC_DIR)/riscv64-unknown-elf-gcc
CLANG_CC       ?= $(LLVM_CC_DIR)/clang
RISCV_OBJDUMP  ?= $(GCC_CC_DIR)/riscv64-unknown-elf-objdump
PYTHON         ?= python3

## directories
SW_DIR         := $(realpath $(CURDIR))
FPGA_BUILD_DIR := $(SW_DIR)/../build
SRC_DIR        := $(SW_DIR)/src
BIN_DIR        := $(SW_DIR)/bin
DMP_DIR        := $(SW_DIR)/dump
LD_DIR         := $(SW_DIR)/linker_scripts
INC_DIR        := $(SW_DIR)/inc
HEX_DIR        := $(SW_DIR)/hex
TOOLS_DIR      := $(SW_DIR)/../../sw/tools
COMMON_OBJ_DIR := $(SW_DIR)/obj/common
TEST_OBJ_DIR   := $(SW_DIR)/obj/$(TEST)

COMMON_SRC_DIR := $(SRC_DIR)/common
TEST_DIR       := $(SRC_DIR)/$(TEST)
L2_INIT_FILE   := $(FPGA_BUILD_DIR)/memory_init/test_init.mem

# get list of all sources (.c, .s, .S) under src/common
COMMON_SRC := \
  $(filter-out \
	  $(wildcard **/*.c) \$(wildcard **/*.s) $(wildcard **/*.S), \
		$(wildcard $(COMMON_SRC_DIR)/*) \
	)
# get output common object files to be created using GCC or LLVM flow
COMMON_OBJ_GCC  := $(subst $(COMMON_SRC_DIR), $(COMMON_OBJ_DIR), $(COMMON_SRC))
COMMON_OBJ_GCC  := $(COMMON_OBJ_GCC:=_gcc.o)
COMMON_OBJ_LLVM := $(subst $(COMMON_SRC_DIR), $(COMMON_OBJ_DIR), $(COMMON_SRC))
COMMON_OBJ_LLVM := $(COMMON_OBJ_LLVM:=_llvm.o)
# get list of all .c sources under src/<test_name> 
TEST_SRC := $(filter %.c, $(wildcard $(TEST_DIR)/*))
# get output test object files to be created using GCC or LLVM flow
TEST_OBJ_GCC  := $(subst $(TEST_DIR), $(TEST_OBJ_DIR), $(TEST_SRC))
TEST_OBJ_GCC  := $(TEST_OBJ_GCC:=_gcc.o)
TEST_OBJ_LLVM := $(subst $(TEST_DIR), $(TEST_OBJ_DIR), $(TEST_SRC))
TEST_OBJ_LLVM := $(TEST_OBJ_LLVM:=_llvm.o)

# build variables
NR_LANES  ?= 4
VLEN      ?= 512
L2_WIDTH  ?= 128
L2_DEPTH  ?= 131072
LD_SCRIPT ?= $(LD_DIR)/link.ld

DEFINES ?= \
  -DNR_LANES=$(NR_LANES) \
  -DVLEN=$(VLEN)

RISCV_CC_WARNS += \
  -Wunused-variable \
  -Wall \
  -Wextra

GCC_CCFLAGS ?= \
  -mcmodel=medany \
	-march=rv64gcvzvkng \
	-mabi=lp64d \
	-I$(INC_DIR) \
	-static \
	-std=gnu99 \
	-g \
	-Os \
	-ffast-math \
	-fno-common \
	-fno-builtin-printf \
	-ffreestanding \
	-nostdlib \
	$(DEFINES) \
	$(RISCV_CC_WARNS)

RISCV_LDFLAGS ?= \
	-nostartfiles \
	-lm \
	-lgcc \
	-Wl,--gc-sections \
	$(GCC_CCFLAGS) \
	-T$(LD_SCRIPT)

## recipes ##

.PHONY: copy_test
copy_test:
	@echo "Copying $(HEX_DIR)/$(TEST).hex into $(L2_INIT_FILE)"
	@cp -f $(HEX_DIR)/$(TEST).hex $(L2_INIT_FILE)

## initialise the env
## gcc
.PHONY: init_gcc
init_gcc:
ifeq ($(strip $(RISCV_DIR_GCC)),)
	echo "[ERROR] Environmental Variable RISCV_DIR_GCC is not set!"
	exit 1;
endif 
	@echo "initialising temporary directories..."
	@mkdir -p $(COMMON_OBJ_DIR)
	@mkdir -p $(TEST_OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(DMP_DIR)

## compile test defined by TEST
# gcc
.PHONY: compile_sw_gcc
compile_sw_gcc: init_gcc $(BIN_DIR)/$(TEST)_gcc.elf
	@echo "GCC Build Complete"


## compile common sources
#gcc
$(COMMON_OBJ_DIR)/%_gcc.o: $(COMMON_SRC_DIR)/%
	@echo "compiling $< to generate $@ using gcc"
	$(GCC_CC) $(GCC_CCFLAGS) -c $< -o $@


## compile test sources
# gcc
$(TEST_OBJ_DIR)/%_gcc.o: $(TEST_DIR)/%
	@echo "compiling $< to generate $@ using gcc"
	$(GCC_CC) $(GCC_CCFLAGS) -c $< -o $@
	

## generate test binary, dump + hex
# gcc
$(BIN_DIR)/$(TEST)_gcc.elf: $(COMMON_OBJ_GCC) $(TEST_OBJ_GCC)
	$(GCC_CC) $(RISCV_LDFLAGS) $(COMMON_OBJ_GCC) $(TEST_OBJ_GCC) -o $@
	$(RISCV_OBJDUMP) -fhs $@ > $(DMP_DIR)/$(TEST)_gcc.dump
	$(RISCV_OBJDUMP) --no-show-raw-insn -SCd $@ > $(DMP_DIR)/$(TEST)_gcc_full.dump
	$(PYTHON) $(TOOLS_DIR)/dump2hex.py $(DMP_DIR)/$(TEST)_gcc.dump $(L2_WIDTH) $(L2_DEPTH) $(HEX_DIR)/$(TEST).hex 0


.PHONY: clean_all
clean_all:
	@echo "cleaning temporary directories and SW build files..."
	@rm -rf $(COMMON_OBJ_DIR) $(TEST_OBJ_DIR)
	@rm -rf $(BIN_DIR)
	@rm -rf $(DMP_DIR)

