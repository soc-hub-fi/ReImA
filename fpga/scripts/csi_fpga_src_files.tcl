# ------------------------------------------------------------------------------
# marian_fpga_src_files.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 23-dec-2023
#
# Description: Source file list for the FPGA prototype of the marian. Adds source
# files/packages to project and sets the project include directories
#
# Ascii art headers generated using https://textkool.com/en/ascii-art-generator
# (style: ANSI Shadow)
# ------------------------------------------------------------------------------

# Clear the console output
puts "\n---------------------------------------------------------";
puts "csi_fpga_src_files.tcl - Starting...";
puts "---------------------------------------------------------\n";

# ██╗███╗   ██╗ ██████╗██╗     ██╗   ██╗██████╗ ███████╗███████╗
# ██║████╗  ██║██╔════╝██║     ██║   ██║██╔══██╗██╔════╝██╔════╝
# ██║██╔██╗ ██║██║     ██║     ██║   ██║██║  ██║█████╗  ███████╗
# ██║██║╚██╗██║██║     ██║     ██║   ██║██║  ██║██╔══╝  ╚════██║
# ██║██║ ╚████║╚██████╗███████╗╚██████╔╝██████╔╝███████╗███████║
# ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝

set CSI_FPGA_INCLUDE_PATHS " \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/include/ \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/include/ \
  ${REPO_DIR}/src/include/ \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/include/axi/ \
";

set_property include_dirs ${CSI_FPGA_INCLUDE_PATHS} [current_fileset];
set_property include_dirs ${CSI_FPGA_INCLUDE_PATHS} [current_fileset -simset];

# ██████╗ ████████╗██╗         ██████╗ ██╗  ██╗ ██████╗ ███████╗
# ██╔══██╗╚══██╔══╝██║         ██╔══██╗██║ ██╔╝██╔════╝ ██╔════╝
# ██████╔╝   ██║   ██║         ██████╔╝█████╔╝ ██║  ███╗███████╗
# ██╔══██╗   ██║   ██║         ██╔═══╝ ██╔═██╗ ██║   ██║╚════██║
# ██║  ██║   ██║   ███████╗    ██║     ██║  ██╗╚██████╔╝███████║
# ╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝                                                                                                                           

set CSI_FPGA_RTL_PACKAGES " \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/test/tb_axi_xbar_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/test/tb_axi_dw_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common_verification/src/rand_verif_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/ecc_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cb_filter_pkg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cf_math_pkg.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_RTL_PACKAGES};

# ████████╗██████╗     ██████╗ ██╗  ██╗ ██████╗ ███████╗
# ╚══██╔══╝██╔══██╗    ██╔══██╗██║ ██╔╝██╔════╝ ██╔════╝
#    ██║   ██████╔╝    ██████╔╝█████╔╝ ██║  ███╗███████╗
#    ██║   ██╔══██╗    ██╔═══╝ ██╔═██╗ ██║   ██║╚════██║
#    ██║   ██████╔╝    ██║     ██║  ██╗╚██████╔╝███████║
#    ╚═╝   ╚═════╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝

set CSI_FPGA_TB_PACKAGES " \
  ${REPO_DIR}/src/tb/top/tb_axi_csirx_pkg.sv \
"; 

add_files -norecurse -scan_for_includes -fileset [current_fileset -simset] ${CSI_FPGA_TB_PACKAGES};

#  ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ ██████╗ ███╗   ██╗     ██████╗███████╗██╗     ██╗     ███████╗
# ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔═══██╗████╗  ██║    ██╔════╝██╔════╝██║     ██║     ██╔════╝
# ██║     ██║   ██║██╔████╔██║██╔████╔██║██║   ██║██╔██╗ ██║    ██║     █████╗  ██║     ██║     ███████╗
# ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║██║╚██╗██║    ██║     ██╔══╝  ██║     ██║     ╚════██║
# ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║    ╚██████╗███████╗███████╗███████╗███████║
#  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝╚══════╝╚══════╝╚══════╝╚══════╝

set CSI_FPGA_COMMON_CELLS_SRC " \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/binary_to_gray.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cdc_2phase.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/clk_div.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/delta_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/edge_propagator_tx.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/exp_backoff.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/fifo_v3.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/gray_to_binary.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/isochronous_spill_register.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/lfsr.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/lfsr_16bit.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/lfsr_8bit.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/mv_filter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/onehot_to_bin.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/plru_tree.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/popcount.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/rr_arb_tree.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/rstgen_bypass.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/serial_deglitch.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/shift_reg.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/spill_register_flushable.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_demux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_filter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_fork.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_intf.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_join.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_mux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/sub_per_hash.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/sync.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/sync_wedge.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/unread.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/addr_decode.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cb_filter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cdc_fifo_2phase.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/ecc_decode.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/ecc_encode.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/edge_detect.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/lzc.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/max_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/rstgen.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/spill_register.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_delay.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_fifo.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_fork_dynamic.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/cdc_fifo_gray.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/fall_through_register.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/id_queue.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_to_mem.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_arbiter_flushable.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_register.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_xbar.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_arbiter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/stream_omega_net.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/clock_divider.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/clock_divider_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/find_first_one.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/generic_LFSR_8bit.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/generic_fifo.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/generic_fifo_adv.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/pulp_sync.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/pulp_sync_wedge.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/sram.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/fifo_v2.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/prioarbiter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/rrarbiter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/deprecated/fifo_v1.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/edge_propagator.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/pulp-common-cells/src/edge_propagator_rx.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_COMMON_CELLS_SRC};                                      

#  ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ ██████╗ ███╗   ██╗     ██████╗ ██████╗ ███╗   ███╗██████╗  ██████╗ ███╗   ██╗███████╗███╗   ██╗████████╗███████╗
# ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔═══██╗████╗  ██║    ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
# ██║     ██║   ██║██╔████╔██║██╔████╔██║██║   ██║██╔██╗ ██║    ██║     ██║   ██║██╔████╔██║██████╔╝██║   ██║██╔██╗ ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
# ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║██║╚██╗██║    ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║   ██║██║╚██╗██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
# ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║    ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ╚██████╔╝██║ ╚████║███████╗██║ ╚████║   ██║   ███████║
#  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

set CSI_FPGA_COMMON_COMPONENTS_SRC " \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/clock_selector/rtl/clock_selector.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/rst_synchronizer_wrapper/rtl/rst_synchronizer_wrapper.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/ss_clk_ctrl/rtl/blank_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/ss_clk_ctrl/rtl/pll_filter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/ss_clk_ctrl/rtl/subsystem_clock_control.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/pad_oscillator_io_generic.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_pad_oscillator_functional_wrapper.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_generic.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/pad_functional_eth.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/pad_functional_generic.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_pad_functional_wrapper.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/synchronizers/rtl/irq_synchronizer.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_pad_analog_wrapper.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/pad_analog_generic.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/margin_reg_array/rtl/margin_reg_array.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/rst_blanking_counter/rtl/rst_blanking_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/rst_delay_counter/rtl/rst_delay_counter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_ctclk_configurable_divider.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/tico/rtl/tico_ctclk_synced_configurable_divider.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/clk_dividers/rtl/generic_ff_clk_div.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/clk_dividers/rtl/conf_ff_clk_div.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/clk_dividers/rtl/synced_conf_ff_clk_div.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/axi_cdc_split/rtl/axi_cdc_split_intf_dst.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/axi_cdc_split/rtl/axi_cdc_split_intf_src.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/axi_cdc_split/rtl/axis_async_fifo_rd.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/axi_cdc_split/rtl/axis_async_fifo_wr.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/memory_models/rtl/generic_memory.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common-components/src/mem_axi_bridge/rtl/mem_axi_bridge.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_COMMON_COMPONENTS_SRC};                                                                                                                                                  

#  █████╗ ██╗  ██╗██╗
# ██╔══██╗╚██╗██╔╝██║
# ███████║ ╚███╔╝ ██║
# ██╔══██║ ██╔██╗ ██║
# ██║  ██║██╔╝ ██╗██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝

set CSI_FPGA_AXI_SRC " \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_intf.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_atop_filter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_burst_splitter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_cdc_dst.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_cdc_src.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_cut.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_delayer.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_demux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_dw_downsizer.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_dw_upsizer.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_id_remap.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_id_prepend.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_isolate.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_join.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_demux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_join.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_mailbox.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_mux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_regs.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_to_apb.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_to_axi.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_modify_address.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_mux.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_serializer.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_cdc.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_err_slv.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_dw_converter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_id_serialize.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_multicut.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_to_axi_lite.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_iw_converter.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_lite_xbar.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/axi/src/axi_xbar.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_AXI_SRC};

# ███╗   ███╗ █████╗  ██████╗██████╗  ██████╗ ███████╗
# ████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝
# ██╔████╔██║███████║██║     ██████╔╝██║   ██║███████╗
# ██║╚██╔╝██║██╔══██║██║     ██╔══██╗██║   ██║╚════██║
# ██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║╚██████╔╝███████║
# ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
                                                    
set CSI_FPGA_MACROS_SRC " \
  ${REPO_DIR}/src/rtl/fpga/xilinx_mem/xil_dual_port.v \
  ${REPO_DIR}/src/rtl/fpga/xilinx_mem/xil_single_port.v \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_MACROS_SRC};

#  ██████╗███████╗██╗
# ██╔════╝██╔════╝██║
# ██║     ███████╗██║
# ██║     ╚════██║██║
# ╚██████╗███████║██║
#  ╚═════╝╚══════╝╚═╝

set CSI_FPGA_SRC " \
  ${REPO_DIR}/ips/axi/src/axi_atop_filter.sv \
  ${REPO_DIR}/ips/axi/src/axi_burst_splitter.sv \
  ${REPO_DIR}/ips/axi/src/axi_to_axi_lite.sv \
  ${REPO_DIR}/ips/common_cells/src/cdc_4phase.sv \
  ${REPO_DIR}/ips/common_cells/src/cdc_reset_ctrlr_pkg.sv \
  ${REPO_DIR}/ips/common_cells/src/cdc_reset_ctrlr.sv \
  ${REPO_DIR}/ips/common_cells/src/cdc_fifo_gray_clearable.sv \
  ${REPO_DIR}/src/rtl/isp/mem/dual_port_ram_model.sv \
  ${REPO_DIR}/src/rtl/isp/mem/dual_port_ram_wrapper.sv \
  ${REPO_DIR}/src/rtl/isp/mem/pixel_mem_array_wrapper.sv \
  ${REPO_DIR}/src/rtl/isp/mem/yuv_mem_array_wrapper.sv \
  ${REPO_DIR}/src/rtl/csi/crc/crc16_parallel.sv \
  ${REPO_DIR}/src/rtl/csi/crc/crc16_top.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_byte_aligner_m.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_depacker.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_header_ecc.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_lane_aligner_m.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_packet_decoder.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_packet_stream_controller.sv \
  ${REPO_DIR}/src/rtl/csi/mipi_csi_rx_protocol_layer.sv \
  ${REPO_DIR}/src/rtl/isp/flow_control.sv \
  ${REPO_DIR}/src/rtl/isp/debayer_filter.sv \
  ${REPO_DIR}/src/rtl/isp/rgb_to_yuv.sv \
  ${REPO_DIR}/src/rtl/isp/csi_axi_master.sv \
  ${REPO_DIR}/src/rtl/top/isp_pipeline.sv \
  ${REPO_DIR}/src/rtl/top/csi_integration.sv \
  ${REPO_DIR}/src/rtl/top/mipi_camera_processor.sv \
  ${REPO_DIR}/src/rtl/top/mipi_camera_processor_fpga.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_SRC};

# ███████╗██████╗  ██████╗  █████╗     ██████╗ ████████╗██╗     
# ██╔════╝██╔══██╗██╔════╝ ██╔══██╗    ██╔══██╗╚══██╔══╝██║     
# █████╗  ██████╔╝██║  ███╗███████║    ██████╔╝   ██║   ██║     
# ██╔══╝  ██╔═══╝ ██║   ██║██╔══██║    ██╔══██╗   ██║   ██║     
# ██║     ██║     ╚██████╔╝██║  ██║    ██║  ██║   ██║   ███████╗
# ╚═╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝   ╚═╝   ╚══════╝

set CSI_FPGA_FPGA_SRC " \  
  ${REPO_DIR}/src/rtl/fpga/top_csi_fpga_wrapper_v.v \
  ${REPO_DIR}/src/rtl/fpga/top_csi_fpga_wrapper_sv.sv \
";

add_files -norecurse -scan_for_includes ${CSI_FPGA_FPGA_SRC};

# ████████╗██████╗ 
# ╚══██╔══╝██╔══██╗
#    ██║   ██████╔╝
#    ██║   ██╔══██╗
#    ██║   ██████╔╝
#    ╚═╝   ╚═════╝ 

set CSI_FPGA_TB_SRC " \
  ${REPO_DIR}/ips/bow-common-ips/ips/common_verification/src/rand_id_queue.sv \
  ${REPO_DIR}/ips/bow-common-ips/ips/common_verification/src/clk_rst_gen.sv \
  ${REPO_DIR}/ips/axi/src/axi_test.sv \
  ${REPO_DIR}/src/tb/csi/tb_crc16.sv \
  ${REPO_DIR}/src/tb/csi/tb_mipi_csi_rx_packet_stream_controller.sv \
  ${REPO_DIR}/src/tb/csi/tb_mipi_csi_rx_depacker.sv \
  ${REPO_DIR}/src/tb/csi/if_csi_dphy_rx_model.sv \
  ${REPO_DIR}/src/tb/csi/pattern_generator.v \
  ${REPO_DIR}/src/tb/isp/tb_isp_pipeline.sv \
  ${REPO_DIR}/src/tb/isp/tb_flow_control.sv \
  ${REPO_DIR}/src/tb/top/tb_top.sv \
  ${REPO_DIR}/src/tb/top/tb_top_camera.sv \
  ${REPO_DIR}/src/tb/top/tb_top_camera_axi.sv \
  ${REPO_DIR}/src/tb/top/tb_top_fpga.sv \
";

add_files -norecurse -scan_for_includes -fileset [current_fileset -simset] ${CSI_FPGA_TB_SRC};

puts "\n---------------------------------------------------------";
puts "csi_fpga_src_files.tcl - Complete!";
puts "---------------------------------------------------------\n";

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------