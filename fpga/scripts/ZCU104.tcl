# ------------------------------------------------------------------------------
# ZCU104.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 03-dec-2023
#
# Description: TCL script containing FPGA board configuration values
# ------------------------------------------------------------------------------

puts "\n---------------------------------------------------------"
puts "ZCU104.tcl - Starting..."
puts "---------------------------------------------------------\n"

set XLNX_PRT_ID xczu7ev-ffvc1156-2-e
set XLNX_BRD_ID xilinx.com:zcu104:part0:1.1
set INPUT_OSC_FREQ_MHZ 250.000

puts "Board Configuration Parameters are:"
puts "Board Part: ${XLNX_PRT_ID}"
puts "Board ID  : ${XLNX_BRD_ID}"
puts "Clock Freq: ${INPUT_OSC_FREQ_MHZ}Mhz\n"

puts "\n---------------------------------------------------------"
puts "ZCU104.tcl - Complete!"
puts "---------------------------------------------------------\n"

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------