######################################################################
# SS local vsim makefile
# Author: Matti Käyrä (Matti.kayra@tuni.fi)
#
######################################################################
BUILD_DIR ?= $(realpath $(CURDIR))/../build/
START_TIME=`date +%F_%H:%M`
DATE=`date +%F`
SHELL=bash

# insert your ss name here
DUT = tb_camera_ss_wrapper

# library specific OPTS etc can be appended in actual library target

COMMON_CELLS_INC_DIRS = +incdir+../ips/bow-common-ips/ips/pulp-common-cells/include/
AXI_INC_DIRS = $(COMMON_CELLS_INC_DIRS) +incdir+../ips/bow-common-ips/ips/axi/include/
REPO_INC_DIRS = +incdir+../src/include/
AXITEST_INC_DIRS= +incdir+../ips/bow-common-ips/ips/axi/include/axi/

LIBS = \
	-L $(BUILD_DIR)/csi_rx_lib \
	-L $(BUILD_DIR)/common_cells_lib \
	-L $(BUILD_DIR)/axi_lib \
	-L $(BUILD_DIR)/pll_lib \
	-L $(BUILD_DIR)/common_components_lib \
	-L $(BUILD_DIR)/peripheral_ss_lib \
	-L $(BUILD_DIR)/csi_rx_tb_lib \

VLOG_DEFS += +define+VERILATOR
VOPT_OPTS = "-check_synthesis"
VOPT_OPTS += "-pedanticerrors"
VOPT_OPTS += "+acc=npr"
#Prints out information where elaboration picks up the module
VOPT_OPTS += "-libverbose=prlib"

VSIM_OPTS = "-c"

#generally no supresses allowd: need to be approved to be included
VLOG_SUPPRESS = 
VCOM_SUPPRESS = 
VOPT_SUPPRESS = -suppress vopt-13262
VSIM_SUPPRESS = -suppress vsim-8386 -suppress vsim-3009


PHONY: check_env
check_env:
	mkdir -p $(BUILD_DIR)/logs/compile
	mkdir -p $(BUILD_DIR)/logs/opt
	mkdir -p $(BUILD_DIR)/logs/sim

# This target is used to map the compiled libraries correctly for vsim
.PHONY: library_mapping
library_mapping:
	cd $(BUILD_DIR)
	vmap common_cells_lib $(BUILD_DIR)/common_cells_lib

# TEMPLATE: replace common ips path with your chip version
.PHONY: compile_common_ips_libs
compile_common_ips_libs:
	$(MAKE) -C ../ips/bow-common-ips/vsim compile BUILD_DIR=$(BUILD_DIR) VLOG_SUPPRESS=$(VLOG_DEFS)

# Compile TLP-SS
.PHONY: compile_peripherals_ss_libs
compile_peripherals_ss_libs:
	$(MAKE) -C ../ips/peripheral-ss compile BUILD_DIR=$(BUILD_DIR) VLOG_SUPPRESS=$(VLOG_DEFS)

.PHONY: $(BUILD_DIR)/csi_rx_tb_lib
$(BUILD_DIR)/csi_rx_tb_lib:
	vlib $(BUILD_DIR)/csi_rx_tb_lib
	vmap csi_rx_tb_lib $(BUILD_DIR)/csi_rx_tb_lib
	vlog $(VLOG_OPTS) -work csi_rx_tb_lib $(REPO_INC_DIRS) $(VLOG_SUPPRESS) $(AXI_INC_DIRS) $(AXITEST_INC_DIRS) $(LIBS) -sv $(VLOG_DEFS) -f ../src/v-tb-files.list -l $(BUILD_DIR)/logs/compile/$(START_TIME)_csi_rx_tb_vlog_compile.log


.PHONY: compile
compile: check_env compile_peripherals_ss_libs compile_common_ips_libs $(BUILD_DIR)/csi_rx_tb_lib
	vlib $(BUILD_DIR)/csi_rx_lib
	vmap csi_rx_lib $(BUILD_DIR)/csi_rx_lib
	vlog +acc -sv -work csi_rx_lib \
	$(REPO_INC_DIRS) $(AXI_INC_DIRS)  $(VLOG_SUPPRESS) $(LIBS)  \
	-f ../src/v-hdl-files.list \
	-l $(BUILD_DIR)/logs/compile/$(START_TIME)_verilog_vlog.log
#vcom -work csi_rx_lib \
#-f ../src/vhdl-hdl-files.list \
#-l $(BUILD_DIR)/logs/compile/$(START_TIME)_vhdl_vcom.log

.PHONY: compile_tieoff
compile_tieoff: check_env
	cd $(BUILD_DIR)
	vlog -sv ../src/wrapper/csi_rx_wrapper_0_tieoff.sv \
	-l $(BUILD_DIR)/logs/compile/vlog-tieoff.log

.PHONY: elaborate
elaborate: check_env library_mapping
	cd $(BUILD_DIR)
	vopt \
	$(VOPT_OPTS) \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	$(LIBS) \
	-work $(BUILD_DIR)/csi_rx_lib \
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
	$(LIBS) \
	-work $(BUILD_DIR)/csi_rx_lib \
	$(DUT)_opt \
	-do "run 0; exit" \
	-l $(BUILD_DIR)/logs/sim/$(START_TIME)_$(DUT)_vsim.log

.PHONY: run_test_gui
run_test_gui:
	cd $(BUILD_DIR)
	vsim \
	-assertdebug \
	-voptargs=+acc \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	$(LIBS) \
	-work $(BUILD_DIR)/csi_rx_lib \
	$(DUT)_opt \
	-do "log -r /*" \
	-l $(BUILD_DIR)/logs/sim/$(START_TIME)_$(DUT)_vsim.log

.PHONY: run_test
run_test:
	cd $(BUILD_DIR)
	vsim \
	-assertdebug \
	-voptargs=+acc \
	$(VSIM_OPTS) \
	$(VOPT_SUPPRESS) \
	$(VSIM_SUPPRESS) \
	$(LIBS) \
	-work $(BUILD_DIR)/csi_rx_lib \
	$(DUT)_opt \
	-do "run -all" \
	-l $(BUILD_DIR)/logs/sim/$(START_TIME)_$(DUT)_vsim.log