# ------------------------------------------------------------------------------
# Vector-Crypto Subsystem (Marian) FPGA Makefile
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 22-dec-2023
#
# Description: Top Makefile for the (Marian) FPGA flow
# ------------------------------------------------------------------------------

## global variables

export FPGA_DIR          ?= $(PWD)
export REPO_DIR          ?= $(realpath $(FPGA_DIR)/..)
export FPGA_BUILD_DIR    ?= $(FPGA_DIR)/build
export FPGA_LOG_DIR      ?= $(FPGA_BUILD_DIR)/logs
export FPGA_PROJECT_DIR  ?= $(FPGA_BUILD_DIR)/$(PROJECT_NAME)
export FPGA_TCL_DIR      ?= $(FPGA_DIR)/scripts
export FPGA_IP_DIR       ?= $(FPGA_DIR)/ips
export FPGA_SIM_DIR      ?= $(FPGA_DIR)/sim
export FPGA_IP_BUILD_DIR ?= $(FPGA_BUILD_DIR)/ips
export FPGA_CONSTR_DIR   ?= $(FPGA_DIR)/constraints
export BOARD_FILES_DIR   ?= $(FPGA_DIR)/board_files

export SUBSYTEM         ?= csi
export PROJECT_NAME     ?= $(SUBSYTEM)_fpga
export FPGA_BOARD       ?= ZCU104
export DUT_TOP_MODULE   ?= design_1_wrapper
export TB_TOP_MODULE    ?= tb_top_fpga

# L2 initialisation method, valid options are:
# - FILE : Directly initialises L2 memory directly from hex file
# - JTAG : Performs JTAG TAP tests and loads L2 memory with hex using JTAG 
L2_INIT_METHOD ?= JTAG

# memory initialisation file used for L2
export TEST              ?= test
export INIT_FILE         := $(FPGA_DIR)/sw/hex/loop.hex
export TEST_FILE         := $(FPGA_DIR)/sw/hex/$(TEST).hex

# path to Questa Compiled Simulation Libraries
# if Questa simulation is not required, remove this variable
export QUESTA_SIM_LIBS   := /opt/soc/work/tom_szymkowiak/xilinx_libs_2021_2

## IP configuration parameters
# top clock frequency in MHz
export TOP_CLK_FREQ_MHZ := 50

# Project synthesis defines
export FPGA_SYNTH_DEFINES ?= \
	FPGA=1

# Project simulation defines
export FPGA_SIM_DEFINES ?= \
	XSIM=1 \
	FPGA=1 \
	PIC_TEST=1

# Parameters for DUT
export FPGA_DUT_PARAMS ?= 

# Parameters for TB
export FPGA_TB_PARAMS ?=

# List of FPGA IPs used in design
export FPGA_IP_LIST ?=

## local variables

START_TIME =`date +%F_%H:%M`

TOP_LOG_DIR := $(FPGA_LOG_DIR)/$(PROJECT_NAME)

BITSTREAM   ?= $(FPGA_BUILD_DIR)/$(PROJECT_NAME).bit
# ILA probe file (if exists)
PROBE_FILE  ?= $(FPGA_BUILD_DIR)/$(PROJECT_NAME).ltx
FPGA_IP_XCI := $(foreach ip, $(FPGA_IP_LIST), $(FPGA_IP_BUILD_DIR)/$(ip)/$(ip).srcs)

.PHONY: all
all: clean_all top


.PHONY: init
init:
	@mkdir -p $(FPGA_BUILD_DIR)	


# launch a Vivado project
.PHONY: top
top: init clean_top all_ips
	@rm -f $(BITSTREAM) $(PROBE_FILE)
	@echo "INFO: Building FPGA design for $(PROJECT_NAME)"
	@mkdir -p $(FPGA_PROJECT_DIR)
	@mkdir -p $(TOP_LOG_DIR)
	cd $(FPGA_PROJECT_DIR) && \
	vivado -mode batch -source $(FPGA_TCL_DIR)/$(PROJECT_NAME)_run.tcl -notrace \
	-log $(TOP_LOG_DIR)/$(START_TIME)_vivado_$(PROJECT_NAME).log \
	-journal $(TOP_LOG_DIR)/$(START_TIME)_vivado_$(PROJECT_NAME).jou


.PHONY: all_ips
all_ips: init $(FPGA_IP_LIST)
	@echo "running all_ips recipe"


$(FPGA_IP_LIST):
	$(MAKE) -C $(FPGA_IP_DIR)/$@ build_ip IP_PROJECT=$@


.PHONY: clean_top
clean_top:
	@echo "INFO: Deleting $(PROJECT_NAME) top build directory and artefacts..."
	@rm -f $(BITSTREAM)
	@rm -f $(PROBE_FILE) 
	@rm -rf $(FPGA_PROJECT_DIR)


.PHONY: clean_ips
clean_ips:
	@echo "INFO: Deleting IP build directory and artefacts..."
	@rm -rf $(FPGA_IP_BUILD_DIR)


.PHONY: clean_all
clean_all:
	@echo "INFO: Deleting build directory..."
	@rm -rf $(FPGA_BUILD_DIR)