######################################################################
# Template-ss top-level makefile
# Author: Matti Käyrä (Matti.kayra@tuni.fi)
# Project: SoC-HUB
# Chip: Experimental
######################################################################

START_TIME=`date +%F_%H:%M`
DATE=`date +%F`

SHELL=bash
BUILD_DIR ?= $(realpath $(CURDIR))/build/

######################################################################
# Makefile common setup
######################################################################

START_TIME=`date +%F_%H:%M`
SHELL=bash
VLOG_DEFS =

######################################################################
# Repository targets
######################################################################

repository_init:
	@echo "Pulling Bender dependencies"
	@bender update
	@echo "Pulling vendor IPs"
	@bender vendor init

.PHONY: check-env
check-env:
	mkdir -p $(BUILD_DIR)/logs/compile
	mkdir -p $(BUILD_DIR)/logs/opt
	mkdir -p $(BUILD_DIR)/logs/sim

######################################################################
# hw build targets 
######################################################################

.PHONY: compile
compile:
	$(MAKE) -C vsim compile BUILD_DIR=$(BUILD_DIR) VLOG_DEFS=$(VLOG_DEFS)

.PHONY: elaborate
elaborate:
	$(MAKE) -C vsim elaborate BUILD_DIR=$(BUILD_DIR)

#################
# hw sim
#####################

.PHONY: sanity_check
sanity_check: check-env
	$(MAKE) -C vsim dut_sanity_check

.PHONY: run_test
run_test: check-env
	$(MAKE) -C vsim run_test

.PHONY: wave
wave: check-env
	$(MAKE) -C vsim wave

######################################################################
# clean target 
######################################################################

.PHONY: clean
clean:
	rm -rf build .bender