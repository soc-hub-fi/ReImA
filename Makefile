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
	git fetch 
	git submodule foreach 'git stash' #stash is to avoid override by accident
	git submodule update --init --recursive

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

.PHONY: elab_syn
elab_syn: check-env
	$(MAKE) -C syn elab_syn

.PHONY: elab_lec
elab_lec: check-env
	$(MAKE) -C syn elab_lec

######################################################################
# formal targets 
######################################################################

.PHONY: autocheck
autocheck: check-env
	$(MAKE) -C formal qverify_autocheck

.PHONY: xcheck
xcheck: check-env
	$(MAKE) -C formal qverify_xcheck

.PHONY: formal
formal: check-env
	$(MAKE) -C formal qverify_formal

.PHONY: check_formal_result
check_formal_result: check-env
	$(MAKE) -C formal check_formal_result

#################
# hw sim
#####################

.PHONY: sanity_check
sanity_check: check-env
	$(MAKE) -C vsim dut_sanity_check

.PHONY: run_test
run_test: check-env
	$(MAKE) -C vsim run_test

.PHONY: run_test_gui
run_test_gui: check-env
	$(MAKE) -C vsim run_test_gui

######################################################################
# CI pipeline variables  targets 
######################################################################

.PHONY: echo_success
echo_success:
	echo -e "\n\n##################################################\n\n OK! \n\n##################################################\n"


######################################################################
# clean target 
######################################################################

.PHONY: clean
clean:
	rm -rf build