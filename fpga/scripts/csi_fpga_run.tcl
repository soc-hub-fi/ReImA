# ------------------------------------------------------------------------------
# csi_fpga_run.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 23-dec-2023
#
# Description: Main TCL script to drive the creation of the FPGA prototyping
# project for the csi. 
# ------------------------------------------------------------------------------

puts "\n---------------------------------------------------------";
puts "csi_fpga_run.tcl - Starting...";
puts "---------------------------------------------------------\n";

# ------------------------------------------------------------------------------
# Check/set basic variables
# ------------------------------------------------------------------------------

# check tcl directory has been defined
if [info exists ::env(FPGA_TCL_DIR)] {
    set FPGA_TCL_DIR $::env(FPGA_TCL_DIR);
} else {
    puts "ERROR - Variable FPGA_TCL_DIR is not globally defined in Makefile!\n";
    return 1;
}

# check tcl directory has been defined
if [info exists ::env(FPGA_BUILD_DIR)] {
    set FPGA_BUILD_DIR $::env(FPGA_BUILD_DIR);
} else {
    puts "ERROR - Variable FPGA_BUILD_DIR is not globally defined in Makefile!\n";
    return 1;
}

# check Vivado project name has been defined
if [info exists ::env(PROJECT_NAME)] {
    set PROJECT_NAME $::env(PROJECT_NAME);
} else {
    puts "ERROR - Variable PROJECT_NAME is not globally defined in Makefile!\n";
    return 1;
}

# define common.tcl script
set FPGA_COMMON_SCRIPT ${FPGA_TCL_DIR}/${PROJECT_NAME}_common.tcl;
set FPGA_BD_SCRIPT ${FPGA_TCL_DIR}/do_bd.tcl;

# read in common and board specific variables 
source ${FPGA_COMMON_SCRIPT};
source ${FPGA_BOARD_CONFIG_SCRIPT};

# define constraints file of format <project_board_constraints.xdc>
set FPGA_CONSTRAINTS ${FPGA_CONSTR_DIR}/${PROJECT_NAME}_${FPGA_BOARD}_constraints.xdc;

# ------------------------------------------------------------------------------
# Create Vivado Project
# ------------------------------------------------------------------------------

create_project ${PROJECT_NAME} . -force -part ${XLNX_PRT_ID};
set_property board_part ${XLNX_BRD_ID} [current_project];

# ------------------------------------------------------------------------------
# Add files and set includes
# ------------------------------------------------------------------------------

source ${FPGA_SOURCE_FILE_SCRIPT}
source ${FPGA_BD_SCRIPT};
set_property include_dirs ${CSI_FPGA_INCLUDE_PATHS} [current_fileset];
make_wrapper -files [get_files ${FPGA_BUILD_DIR}/csi_fpga/csi_fpga.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ${FPGA_BUILD_DIR}/csi_fpga/csi_fpga.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v
# set top design for design and testbench
set_property top ${DUT_TOP_MODULE} [current_fileset];
set_property top ${TB_TOP_MODULE}  [current_fileset -simset];

set_property verilog_define ${FPGA_SYNTH_DEFINES} [current_fileset];
set_property verilog_define ${FPGA_SIM_DEFINES}   [current_fileset -simset];

set_property generic ${FPGA_DUT_PARAMS} [current_fileset];
set_property generic ${FPGA_TB_PARAMS}  [current_fileset -simset];

add_files -fileset constrs_1 -norecurse ${FPGA_CONSTRAINTS};

# ------------------------------------------------------------------------------
# Add IPs
# ------------------------------------------------------------------------------

# separate IPs into a list
if {[llength $FPGA_IP_LIST] != 0} {
    set FPGA_IP_LIST [split $FPGA_IP_LIST " "];
}

# add each synthesised IP to the project
foreach {IP} ${FPGA_IP_LIST} {
    puts "Adding ${IP} IP to project...";
    read_ip ${FPGA_IP_BUILD_DIR}/${IP}/${IP}.srcs/sources_1/ip/${IP}/${IP}.xci;
} 

## ------------------------------------------------------------------------------
## Configure Simulation Settings
## ------------------------------------------------------------------------------
#
## below for Questa
if [info exists ::env(QUESTA_SIM_LIBS)] {
  
  set QUESTA_SIM_LIBS $::env(QUESTA_SIM_LIBS);

  set_property target_simulator Questa [current_project];
  set_property compxlib.questa_compiled_library_dir ${QUESTA_SIM_LIBS} [current_project];

  set_property -name {questa.simulate.runtime} -value {0ns} -objects [get_filesets sim_1];
  set_property -name {questa.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1];
  set_property -name {questa.elaborate.vopt.more_options} -value { -suppress vopt-7033 -suppress vsim-3009 } -objects [get_filesets sim_1];
  set_property -name {questa.simulate.vsim.more_options} -value {-suppress vsim-3009 -suppress vsim-7033 -onfinish stop} -objects [get_filesets sim_1];
  set_property -name {questa.simulate.custom_wave_do} -value "${FPGA_SIM_DIR}/sim.do" -objects [get_filesets sim_1];
}
## ------------------------------------------------------------------------------
## Block Design
## ------------------------------------------------------------------------------
##source ${FPGA_BD_SCRIPT};
##set_property include_dirs ${CSI_FPGA_INCLUDE_PATHS} [current_fileset];

# ------------------------------------------------------------------------------
# Run Synthesis
# ------------------------------------------------------------------------------

# Configure synthesis strategy to preserve hierarchy
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1];
# Use single file compilation unit mode to prevent issues with import pkg::* statements in the codebase
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value -sfcu -objects [get_runs synth_1];
# Temporarily remove DSPs from design as timing simulation will generate errors if DSPs are in design
set_property STEPS.SYNTH_DESIGN.ARGS.MAX_DSP 0 [get_runs synth_1]
# Add XPM CDC library
set_property XPM_LIBRARIES XPM_CDC [current_project]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value { -sfcu -include_dirs "opt/soc/work/moh_sol/bow/csi-rx/ips/bow-common-ips/ips/axi/include/axi/ opt/soc/work/moh_sol/bow/csi-rx/ips/bow-common-ips/ips/pulp-common-cells/include/"} -objects [get_runs synth_1]
set_property CONFIG.FREQ_HZ 50000000 [get_bd_intf_pins /top_csi_fpga_wrapper_0/s_axi]
save_bd_design
generate_target all [get_files  ${FPGA_BUILD_DIR}/csi_fpga/csi_fpga.srcs/sources_1/bd/design_1/design_1.bd]
# Launch synthesis
launch_runs synth_1;
wait_on_run synth_1;
open_run synth_1 -name netlist_1;
# prevents need to run synth again
set_property needs_refresh false [get_runs synth_1]; 

# ------------------------------------------------------------------------------
# Run Place and Route (Implementation)
# ------------------------------------------------------------------------------

# Launch implementation
launch_runs impl_1 -verbose;
wait_on_run impl_1

# ------------------------------------------------------------------------------
# Generate bitstream
# ------------------------------------------------------------------------------

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

open_run impl_1

# ------------------------------------------------------------------------------
# Generate hardware
# ------------------------------------------------------------------------------

write_hw_platform -fixed -include_bit -force -file ${FPGA_BUILD_DIR}/csi_fpga/design_1_wrapper.xsa

# ------------------------------------------------------------------------------
# Generate reports
# ------------------------------------------------------------------------------

# ToDo

puts "\n---------------------------------------------------------";
puts "csi_fpga_run.tcl - Complete!";
puts "---------------------------------------------------------\n";

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------
