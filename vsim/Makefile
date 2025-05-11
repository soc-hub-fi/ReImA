######################################################################
# SS local vsim makefile
# Authors: 	Matti Käyrä (Matti.kayra@tuni.fi)
#			Mohamed Soliman (mohamed.w.soliman@tuni.fi)
######################################################################

BUILD_DIR ?= $(realpath $(CURDIR))/../build/
REIMA_DIR ?= $(realpath $(CURDIR))/../

START_TIME=`date +%F_%H:%M`
DATE=`date +%F`
SHELL=bash

DUT = tb_iap_core

AXI_DIR				?= $(shell bender path axi)
COMMON_CELLS_DIR 	?= $(shell bender path common_cells)

INCLUDES 	?= \
			+incdir+$(AXI_DIR)/include \
			+incdir+$(COMMON_CELLS_DIR)/include \
			+incdir+$(REIMA_DIR)/src/include

# Questa compilations, elaboration and simulation flags
VOPT_OPTS += "-check_synthesis" \
				"-pedanticerrors" \
				"-libverbose=prlib"
VSIM_OPTS = "-c"
VLOG_SUPPRESS = 
VCOM_SUPPRESS = 
VOPT_SUPPRESS = -suppress vopt-13262
VSIM_SUPPRESS = -suppress vsim-8386 -suppress vsim-3009

# Prepare libraries and files
PHONY: check_env
check_env:
	mkdir -p $(BUILD_DIR)/logs/compile
	mkdir -p $(BUILD_DIR)/logs/opt
	mkdir -p $(BUILD_DIR)/logs/sim

.PHONY: library_mapping
library_mapping: check_env
	vlib $(BUILD_DIR)/reima_lib
	vmap reima_lib $(BUILD_DIR)/reima_lib

# This target is used to map the compiled libraries correctly for vsim

.PHONY: compile
compile: library_mapping
	cd $(BUILD_DIR)
	vlog -sv -work reima_lib \
	+define+VERILATOR \
	$(INCLUDES) $(VLOG_DEFS) $(VLOG_SUPPRESS) \
	$(shell bender script flist -t simulation -t test) \
	-l $(BUILD_DIR)/logs/compile/$(START_TIME)_verilog_vlog.log

.PHONY: elaborate
elaborate: check_env
	cd $(BUILD_DIR)
	vopt \
	$(VOPT_OPTS) \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	-work reima_lib \
	$(DUT) \
	-o $(DUT)_opt \
	-l $(BUILD_DIR)/logs/opt/$(START_TIME)_$(DUT)_vopt.log

.PHONY: dut_sanity_check
dut_sanity_check:
	cd $(BUILD_DIR)
	vsim \
	$(VSIM_OPTS) \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	-work $(BUILD_DIR)/reima_lib \
	$(DUT)_opt \
	-do "run 0; exit" \
	-l $(BUILD_DIR)/logs/sim/$(START_TIME)_$(DUT)_vsim.log

.PHONY: run_test
run_test:
	cd $(BUILD_DIR)
	vsim \
	-assertdebug \
	-wlf wave.wlf \
	$(VSIM_OPTS) \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	-work $(BUILD_DIR)/reima_lib \
	$(DUT)_opt \
	-do "log -r /*; \
		run -all; \
		exit" \
	-l $(BUILD_DIR)/logs/sim/$(START_TIME)_$(DUT)_vsim.log

.PHONY: wave
wave:
	vsim wave.wlf