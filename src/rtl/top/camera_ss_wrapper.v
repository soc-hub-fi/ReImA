//-----------------------------------------------------------------------------
// File          : camera_ss_wrapper.v
// Creation date : 19.07.2024
// Creation time : 10:09:19
// Description   : Wrapper for camera subsystem
// Created by    : 
// Tool : Kactus2 3.10.15 64-bit
// Plugin : Verilog generator 2.4
// This file was generated based on IP-XACT component tuni.fi:subsystem.wrapper:camera-ss:1.0
// whose XML file is /opt/soc/work/moh_sol/bow/bow/ips/camera-ss/ipxact/tuni.fi/subsystem.wrapper/camera-ss/1.0/camera-ss.1.0.xml
//-----------------------------------------------------------------------------

module camera_ss_wrapper #(
    parameter                              AXI_32_DATA_WIDTH = 32,
    parameter                              AXI_ADDR_WIDTH   = 32,
    parameter                              CB_AR_DATA_SIZE  = 71,
    parameter                              CB_AW_DATA_SIZE  = 77,
    parameter                              CB_B_DATA_SIZE   = 12,
    parameter                              CB_M_LOG_DEPTH   = 2,
    parameter                              CLK_CTRL_WIDTH   = 8,
    parameter                              PLL_DIV_WIDTH    = 17,
    parameter                              AXI_ID_WIDTH     = 9,
    parameter                              AXI_USER_WIDTH   = 1,
    parameter                              CB_32_R_DATA_SIZE = 45,
    parameter                              CB_32_W_DATA_SIZE = 38,
    parameter                              APB_ADDR_WIDTH   = 12,
    parameter                              CB_S_LOG_DEPTH   = 2,
    parameter                              AXI_STRB_WIDTH   = 4,
    parameter                              PLL_CTRL_WIDTH   = 105
) (
    // Interface: DPHY
    inout  logic                        clk_lane_n,
    inout  logic                        clk_lane_p,
    inout  logic                        data_lane_0_n,
    inout  logic                        data_lane_0_p,
    inout  logic                        data_lane_1_n,
    inout  logic                        data_lane_1_p,
    inout  logic                        data_lane_2_n,
    inout  logic                        data_lane_2_p,
    inout  logic                        data_lane_3_n,
    inout  logic                        data_lane_3_p,

    // Interface: IRQ
    output logic                        frame_wr_done_intr_o,

    // Interface: axi_master
    input  logic         [1:0]          axi_master_cam_ar_rd_data_ptr_dst2src,
    input  logic         [2:0]          axi_master_cam_ar_rd_ptr_gray_dst2src,
    input  logic         [1:0]          axi_master_cam_aw_rd_data_ptr_dst2src,
    input  logic         [2:0]          axi_master_cam_aw_rd_ptr_gray_dst2src,
    input  logic         [11:0]         axi_master_cam_b_data_dst2src,
    input  logic         [2:0]          axi_master_cam_b_wr_ptr_gray_dst2src,
    input  logic         [44:0]         axi_master_cam_r_data_dst2src,
    input  logic         [2:0]          axi_master_cam_r_wr_ptr_gray_dst2src,
    input  logic         [1:0]          axi_master_cam_w_rd_data_ptr_dst2src,
    input  logic         [2:0]          axi_master_cam_w_rd_ptr_gray_dst2src,
    output logic         [70:0]         axi_master_cam_ar_data_src2dst,
    output logic         [2:0]          axi_master_cam_ar_wr_ptr_gray_src2dst,
    output logic         [76:0]         axi_master_cam_aw_data_src2dst,
    output logic         [2:0]          axi_master_cam_aw_wr_ptr_gray_src2dst,
    output logic         [1:0]          axi_master_cam_b_rd_data_ptr_src2dst,
    output logic         [2:0]          axi_master_cam_b_rd_ptr_gray_src2dst,
    output logic         [1:0]          axi_master_cam_r_rd_data_ptr_src2dst,
    output logic         [2:0]          axi_master_cam_r_rd_ptr_gray_src2dst,
    output logic         [37:0]         axi_master_cam_w_data_src2dst,
    output logic         [2:0]          axi_master_cam_w_wr_ptr_gray_src2dst,

    // Interface: axi_slave
    input  logic         [70:0]         axi_slave_cam_ar_data_src2dst,
    input  logic         [2:0]          axi_slave_cam_ar_wr_ptr_gray_src2dst,
    input  logic         [76:0]         axi_slave_cam_aw_data_src2dst,
    input  logic         [2:0]          axi_slave_cam_aw_wr_ptr_gray_src2dst,
    input  logic         [1:0]          axi_slave_cam_b_rd_data_ptr_src2dst,
    input  logic         [2:0]          axi_slave_cam_b_rd_ptr_gray_src2dst,
    input  logic         [1:0]          axi_slave_cam_r_rd_data_ptr_src2dst,
    input  logic         [2:0]          axi_slave_cam_r_rd_ptr_gray_src2dst,
    input  logic         [37:0]         axi_slave_cam_w_data_src2dst,
    input  logic         [2:0]          axi_slave_cam_w_wr_ptr_gray_src2dst,
    output logic         [1:0]          axi_slave_cam_ar_rd_data_ptr_dst2src,
    output logic         [2:0]          axi_slave_cam_ar_rd_ptr_gray_dst2src,
    output logic         [1:0]          axi_slave_cam_aw_rd_data_ptr_dst2src,
    output logic         [2:0]          axi_slave_cam_aw_rd_ptr_gray_dst2src,
    output logic         [11:0]         axi_slave_cam_b_data_dst2src,
    output logic         [2:0]          axi_slave_cam_b_wr_ptr_gray_dst2src,
    output logic         [44:0]         axi_slave_cam_r_data_dst2src,
    output logic         [2:0]          axi_slave_cam_r_wr_ptr_gray_dst2src,
    output logic         [1:0]          axi_slave_cam_w_rd_data_ptr_dst2src,
    output logic         [2:0]          axi_slave_cam_w_rd_ptr_gray_dst2src,

    // Interface: clk_ctrl
    input  logic                        force_cka,
    input  logic                        force_ckb,
    input  logic                        sel_cka,
    input  logic                        subsys_clkena,

    // Interface: i2c_master_slave
    input  logic                        scl_pad_i,
    input  logic                        sda_pad_i,
    output logic                        scl_pad_o,
    output logic                        scl_padoen_o,
    output logic                        sda_pad_o,
    output logic                        sda_padoen_o,

    // Interface: icn_rstn
    input  logic                        icn_rst_ni,

    // Interface: irq_master
    output logic                        interrupt_o,

    // Interface: pll_ctrl
    input  logic         [104:0]        pll_ctrl_in,
    input  logic                        pll_ctrl_valid,

    // Interface: pll_status
    output logic         [31:0]         STATUS1,    // ! Status 1 (TBD)
    output logic         [31:0]         STATUS2,    // ! Status 2 (TBD)

    // Interface: ref_clk
    input  logic                        refclk,

    // Interface: ref_rstn
    input  logic                        refrstn
);

    // axi2apb_0_apb_master_to_apb_i2c_0_apb_slave wires:
    wire [11:0] axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PADDR;
    wire       axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PENABLE;
    wire [31:0] axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PRDATA;
    wire       axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PREADY;
    wire       axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSEL;
    wire       axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSLVERR;
    wire [31:0] axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWDATA;
    wire       axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWRITE;
    // clkpll_0_pll_clk_to_subsystem_clock_control_0_pll_clk wires:
    wire       clkpll_0_pll_clk_to_subsystem_clock_control_0_pll_clk_clk;
    // subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched wires:
    wire [7:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DEBUG_CTRL;
    wire [16:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DIV;
    wire [7:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_ENABLE;
    wire [31:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_LOOP_CTRL;
    wire [31:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_SPARE_CTRL;
    wire [7:0] subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_TMUX_SEL;
    // subsystem_clock_control_0_clk_to_axi2apb_0_clk wires:
    wire       subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    // subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n wires:
    wire       subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    // subsystem_clock_control_0_ref_clk_to_ref_clk wires:
    wire       subsystem_clock_control_0_ref_clk_to_ref_clk_clk;
    // subsystem_clock_control_0_ref_rstn_to_ref_rstn wires:
    wire       subsystem_clock_control_0_ref_rstn_to_ref_rstn_rst_n;
    // subsystem_clock_control_0_clk_ctrl_to_clk_ctrl wires:
    wire [3:0] subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL;
    // subsystem_clock_control_0_pll_ctrl_to_pll_ctrl wires:
    wire [7:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DEBUG_CTRL;
    wire [16:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DIV;
    wire [7:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_ENABLE;
    wire [31:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_LOOP_CTRL;
    wire [31:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_SPARE_CTRL;
    wire [7:0] subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_TMUX_SEL;
    wire       subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_VALID;
    // clkpll_0_pll_status_to_pll_status wires:
    wire [31:0] clkpll_0_pll_status_to_pll_status_pll_status_1;
    wire [31:0] clkpll_0_pll_status_to_pll_status_pll_status_2;
    // apb_i2c_0_irq_master_to_irq_master wires:
    wire       apb_i2c_0_irq_master_to_irq_master_IRQ;
    // axi_cdc_intf_src_0_icn_rstn_to_icn_rstn wires:
    wire       axi_cdc_intf_src_0_icn_rstn_to_icn_rstn_rst_n;
    // axi_cdc_intf_src_0_src_to_axi_master wires:
    wire [70:0] axi_cdc_intf_src_0_src_to_axi_master_AR_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_src_0_src_to_axi_master_AR_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_AR_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_AR_WR_PTR_GRAY_SRC2DST;
    wire [76:0] axi_cdc_intf_src_0_src_to_axi_master_AW_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_src_0_src_to_axi_master_AW_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_AW_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_AW_WR_PTR_GRAY_SRC2DST;
    wire [11:0] axi_cdc_intf_src_0_src_to_axi_master_B_DATA_DST2SRC;
    wire [1:0] axi_cdc_intf_src_0_src_to_axi_master_B_RD_DATA_PTR_SRC2DST;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_B_RD_PTR_GRAY_SRC2DST;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_B_WR_PTR_GRAY_DST2SRC;
    wire [44:0] axi_cdc_intf_src_0_src_to_axi_master_R_DATA_DST2SRC;
    wire [1:0] axi_cdc_intf_src_0_src_to_axi_master_R_RD_DATA_PTR_SRC2DST;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_R_RD_PTR_GRAY_SRC2DST;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_R_WR_PTR_GRAY_DST2SRC;
    wire [37:0] axi_cdc_intf_src_0_src_to_axi_master_W_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_src_0_src_to_axi_master_W_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_W_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_src_0_src_to_axi_master_W_WR_PTR_GRAY_SRC2DST;
    // axi_cdc_intf_dst_0_dst_to_axi_slave wires:
    wire [70:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AR_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AR_WR_PTR_GRAY_SRC2DST;
    wire [76:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AW_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_AW_WR_PTR_GRAY_SRC2DST;
    wire [11:0] axi_cdc_intf_dst_0_dst_to_axi_slave_B_DATA_DST2SRC;
    wire [1:0] axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_DATA_PTR_SRC2DST;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_PTR_GRAY_SRC2DST;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_B_WR_PTR_GRAY_DST2SRC;
    wire [44:0] axi_cdc_intf_dst_0_dst_to_axi_slave_R_DATA_DST2SRC;
    wire [1:0] axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_DATA_PTR_SRC2DST;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_PTR_GRAY_SRC2DST;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_R_WR_PTR_GRAY_DST2SRC;
    wire [37:0] axi_cdc_intf_dst_0_dst_to_axi_slave_W_DATA_SRC2DST;
    wire [1:0] axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_DATA_PTR_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_PTR_GRAY_DST2SRC;
    wire [2:0] axi_cdc_intf_dst_0_dst_to_axi_slave_W_WR_PTR_GRAY_SRC2DST;
    // apb_i2c_0_i2c_master_slave_to_i2c_master_slave wires:
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_i;
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_o;
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_oen;
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_i;
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_o;
    wire       apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_oen;
    // camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst wires:
    wire [31:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ADDR;
    wire [1:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_BURST;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_CACHE;
    wire [8:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ID;
    wire [7:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LEN;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LOCK;
    wire [2:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_PROT;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_QOS;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_READY;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_REGION;
    wire [2:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_SIZE;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_USER;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_VALID;
    wire [31:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ADDR;
    wire [5:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ATOP;
    wire [1:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_BURST;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_CACHE;
    wire [8:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ID;
    wire [7:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LEN;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LOCK;
    wire [2:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_PROT;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_QOS;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_READY;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_REGION;
    wire [2:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_SIZE;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_USER;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_VALID;
    wire [8:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_ID;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_READY;
    wire [1:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_RESP;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_USER;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_VALID;
    wire [31:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_DATA;
    wire [8:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_ID;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_LAST;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_READY;
    wire [1:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_RESP;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_USER;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_VALID;
    wire [31:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_DATA;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_LAST;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_READY;
    wire [3:0] camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_STRB;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_USER;
    wire       camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_VALID;
    // d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE wires:
    wire       d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxByteClkHS;
    wire [31:0] d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS;
    wire [3:0] d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS;
    // camera_processor_0_IRQ_to_IRQ wires:
    wire       camera_processor_0_IRQ_to_IRQ_IRQ;
    // d_phy_top_0_DPHY_to_DPHY wires:
    // periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src wires:
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ADDR;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ADDR;
    wire [5:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ATOP;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_VALID;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_DATA;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_DATA;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_STRB;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_VALID;
    // periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave wires:
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ADDR;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ADDR;
    wire [5:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ATOP;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_VALID;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_DATA;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_DATA;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_STRB;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_VALID;
    // periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE wires:
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ADDR;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ADDR;
    wire [5:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ATOP;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_BURST;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_CACHE;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ID;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LEN;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LOCK;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_PROT;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_QOS;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_REGION;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_SIZE;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_VALID;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_DATA;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_ID;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_READY;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_RESP;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_VALID;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_DATA;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_LAST;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_READY;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_STRB;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_USER;
    wire       periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_VALID;

    // Ad-hoc wires:
    wire       clkpll_0_CLK_PLL_LOCK_to_subsystem_clock_control_0_pll_lock;

    // apb_i2c_0 port wires:
    wire       apb_i2c_0_HCLK;
    wire       apb_i2c_0_HRESETn;
    wire [11:0] apb_i2c_0_PADDR;
    wire       apb_i2c_0_PENABLE;
    wire [31:0] apb_i2c_0_PRDATA;
    wire       apb_i2c_0_PREADY;
    wire       apb_i2c_0_PSEL;
    wire       apb_i2c_0_PSLVERR;
    wire [31:0] apb_i2c_0_PWDATA;
    wire       apb_i2c_0_PWRITE;
    wire       apb_i2c_0_interrupt_o;
    wire       apb_i2c_0_scl_pad_i;
    wire       apb_i2c_0_scl_pad_o;
    wire       apb_i2c_0_scl_padoen_o;
    wire       apb_i2c_0_sda_pad_i;
    wire       apb_i2c_0_sda_pad_o;
    wire       apb_i2c_0_sda_padoen_o;
    // axi2apb_0 port wires:
    wire       axi2apb_0_ACLK;
    wire [31:0] axi2apb_0_ARADDR_i;
    wire [1:0] axi2apb_0_ARBURST_i;
    wire [3:0] axi2apb_0_ARCACHE_i;
    wire       axi2apb_0_ARESETn;
    wire [8:0] axi2apb_0_ARID_i;
    wire [7:0] axi2apb_0_ARLEN_i;
    wire       axi2apb_0_ARLOCK_i;
    wire [2:0] axi2apb_0_ARPROT_i;
    wire [3:0] axi2apb_0_ARQOS_i;
    wire       axi2apb_0_ARREADY_o;
    wire [3:0] axi2apb_0_ARREGION_i;
    wire [2:0] axi2apb_0_ARSIZE_i;
    wire       axi2apb_0_ARUSER_i;
    wire       axi2apb_0_ARVALID_i;
    wire [31:0] axi2apb_0_AWADDR_i;
    wire [1:0] axi2apb_0_AWBURST_i;
    wire [3:0] axi2apb_0_AWCACHE_i;
    wire [8:0] axi2apb_0_AWID_i;
    wire [7:0] axi2apb_0_AWLEN_i;
    wire       axi2apb_0_AWLOCK_i;
    wire [2:0] axi2apb_0_AWPROT_i;
    wire [3:0] axi2apb_0_AWQOS_i;
    wire       axi2apb_0_AWREADY_o;
    wire [3:0] axi2apb_0_AWREGION_i;
    wire [2:0] axi2apb_0_AWSIZE_i;
    wire       axi2apb_0_AWUSER_i;
    wire       axi2apb_0_AWVALID_i;
    wire [8:0] axi2apb_0_BID_o;
    wire       axi2apb_0_BREADY_i;
    wire [1:0] axi2apb_0_BRESP_o;
    wire       axi2apb_0_BUSER_o;
    wire       axi2apb_0_BVALID_o;
    wire [11:0] axi2apb_0_PADDR;
    wire       axi2apb_0_PENABLE;
    wire [31:0] axi2apb_0_PRDATA;
    wire       axi2apb_0_PREADY;
    wire       axi2apb_0_PSEL;
    wire       axi2apb_0_PSLVERR;
    wire [31:0] axi2apb_0_PWDATA;
    wire       axi2apb_0_PWRITE;
    wire [31:0] axi2apb_0_RDATA_o;
    wire [8:0] axi2apb_0_RID_o;
    wire       axi2apb_0_RLAST_o;
    wire       axi2apb_0_RREADY_i;
    wire [1:0] axi2apb_0_RRESP_o;
    wire       axi2apb_0_RUSER_o;
    wire       axi2apb_0_RVALID_o;
    wire [31:0] axi2apb_0_WDATA_i;
    wire       axi2apb_0_WLAST_i;
    wire       axi2apb_0_WREADY_o;
    wire [3:0] axi2apb_0_WSTRB_i;
    wire       axi2apb_0_WUSER_i;
    wire       axi2apb_0_WVALID_i;
    // axi_cdc_intf_dst_0 port wires:
    wire [31:0] axi_cdc_intf_dst_0_ar_addr;
    wire [1:0] axi_cdc_intf_dst_0_ar_burst;
    wire [3:0] axi_cdc_intf_dst_0_ar_cache;
    wire [70:0] axi_cdc_intf_dst_0_ar_data_src2dst;
    wire [8:0] axi_cdc_intf_dst_0_ar_id;
    wire [7:0] axi_cdc_intf_dst_0_ar_len;
    wire       axi_cdc_intf_dst_0_ar_lock;
    wire [2:0] axi_cdc_intf_dst_0_ar_prot;
    wire [3:0] axi_cdc_intf_dst_0_ar_qos;
    wire [1:0] axi_cdc_intf_dst_0_ar_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_dst_0_ar_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_dst_0_ar_ready;
    wire [3:0] axi_cdc_intf_dst_0_ar_region;
    wire [2:0] axi_cdc_intf_dst_0_ar_size;
    wire       axi_cdc_intf_dst_0_ar_user;
    wire       axi_cdc_intf_dst_0_ar_valid;
    wire [2:0] axi_cdc_intf_dst_0_ar_wr_ptr_gray_src2dst;
    wire [31:0] axi_cdc_intf_dst_0_aw_addr;
    wire [5:0] axi_cdc_intf_dst_0_aw_atop;
    wire [1:0] axi_cdc_intf_dst_0_aw_burst;
    wire [3:0] axi_cdc_intf_dst_0_aw_cache;
    wire [76:0] axi_cdc_intf_dst_0_aw_data_src2dst;
    wire [8:0] axi_cdc_intf_dst_0_aw_id;
    wire [7:0] axi_cdc_intf_dst_0_aw_len;
    wire       axi_cdc_intf_dst_0_aw_lock;
    wire [2:0] axi_cdc_intf_dst_0_aw_prot;
    wire [3:0] axi_cdc_intf_dst_0_aw_qos;
    wire [1:0] axi_cdc_intf_dst_0_aw_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_dst_0_aw_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_dst_0_aw_ready;
    wire [3:0] axi_cdc_intf_dst_0_aw_region;
    wire [2:0] axi_cdc_intf_dst_0_aw_size;
    wire       axi_cdc_intf_dst_0_aw_user;
    wire       axi_cdc_intf_dst_0_aw_valid;
    wire [2:0] axi_cdc_intf_dst_0_aw_wr_ptr_gray_src2dst;
    wire [11:0] axi_cdc_intf_dst_0_b_data_dst2src;
    wire [8:0] axi_cdc_intf_dst_0_b_id;
    wire [1:0] axi_cdc_intf_dst_0_b_rd_data_ptr_src2dst;
    wire [2:0] axi_cdc_intf_dst_0_b_rd_ptr_gray_src2dst;
    wire       axi_cdc_intf_dst_0_b_ready;
    wire [1:0] axi_cdc_intf_dst_0_b_resp;
    wire       axi_cdc_intf_dst_0_b_user;
    wire       axi_cdc_intf_dst_0_b_valid;
    wire [2:0] axi_cdc_intf_dst_0_b_wr_ptr_gray_dst2src;
    wire       axi_cdc_intf_dst_0_dst_clk_i;
    wire       axi_cdc_intf_dst_0_dst_rst_ni;
    wire       axi_cdc_intf_dst_0_icn_rst_ni;
    wire [31:0] axi_cdc_intf_dst_0_r_data;
    wire [44:0] axi_cdc_intf_dst_0_r_data_dst2src;
    wire [8:0] axi_cdc_intf_dst_0_r_id;
    wire       axi_cdc_intf_dst_0_r_last;
    wire [1:0] axi_cdc_intf_dst_0_r_rd_data_ptr_src2dst;
    wire [2:0] axi_cdc_intf_dst_0_r_rd_ptr_gray_src2dst;
    wire       axi_cdc_intf_dst_0_r_ready;
    wire [1:0] axi_cdc_intf_dst_0_r_resp;
    wire       axi_cdc_intf_dst_0_r_user;
    wire       axi_cdc_intf_dst_0_r_valid;
    wire [2:0] axi_cdc_intf_dst_0_r_wr_ptr_gray_dst2src;
    wire [31:0] axi_cdc_intf_dst_0_w_data;
    wire [37:0] axi_cdc_intf_dst_0_w_data_src2dst;
    wire       axi_cdc_intf_dst_0_w_last;
    wire [1:0] axi_cdc_intf_dst_0_w_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_dst_0_w_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_dst_0_w_ready;
    wire [3:0] axi_cdc_intf_dst_0_w_strb;
    wire       axi_cdc_intf_dst_0_w_user;
    wire       axi_cdc_intf_dst_0_w_valid;
    wire [2:0] axi_cdc_intf_dst_0_w_wr_ptr_gray_src2dst;
    // axi_cdc_intf_src_0 port wires:
    wire [31:0] axi_cdc_intf_src_0_ar_addr;
    wire [1:0] axi_cdc_intf_src_0_ar_burst;
    wire [3:0] axi_cdc_intf_src_0_ar_cache;
    wire [70:0] axi_cdc_intf_src_0_ar_data_src2dst;
    wire [8:0] axi_cdc_intf_src_0_ar_id;
    wire [7:0] axi_cdc_intf_src_0_ar_len;
    wire       axi_cdc_intf_src_0_ar_lock;
    wire [2:0] axi_cdc_intf_src_0_ar_prot;
    wire [3:0] axi_cdc_intf_src_0_ar_qos;
    wire [1:0] axi_cdc_intf_src_0_ar_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_src_0_ar_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_src_0_ar_ready;
    wire [3:0] axi_cdc_intf_src_0_ar_region;
    wire [2:0] axi_cdc_intf_src_0_ar_size;
    wire       axi_cdc_intf_src_0_ar_user;
    wire       axi_cdc_intf_src_0_ar_valid;
    wire [2:0] axi_cdc_intf_src_0_ar_wr_ptr_gray_src2dst;
    wire [31:0] axi_cdc_intf_src_0_aw_addr;
    wire [5:0] axi_cdc_intf_src_0_aw_atop;
    wire [1:0] axi_cdc_intf_src_0_aw_burst;
    wire [3:0] axi_cdc_intf_src_0_aw_cache;
    wire [76:0] axi_cdc_intf_src_0_aw_data_src2dst;
    wire [8:0] axi_cdc_intf_src_0_aw_id;
    wire [7:0] axi_cdc_intf_src_0_aw_len;
    wire       axi_cdc_intf_src_0_aw_lock;
    wire [2:0] axi_cdc_intf_src_0_aw_prot;
    wire [3:0] axi_cdc_intf_src_0_aw_qos;
    wire [1:0] axi_cdc_intf_src_0_aw_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_src_0_aw_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_src_0_aw_ready;
    wire [3:0] axi_cdc_intf_src_0_aw_region;
    wire [2:0] axi_cdc_intf_src_0_aw_size;
    wire       axi_cdc_intf_src_0_aw_user;
    wire       axi_cdc_intf_src_0_aw_valid;
    wire [2:0] axi_cdc_intf_src_0_aw_wr_ptr_gray_src2dst;
    wire [11:0] axi_cdc_intf_src_0_b_data_dst2src;
    wire [8:0] axi_cdc_intf_src_0_b_id;
    wire [1:0] axi_cdc_intf_src_0_b_rd_data_ptr_src2dst;
    wire [2:0] axi_cdc_intf_src_0_b_rd_ptr_gray_src2dst;
    wire       axi_cdc_intf_src_0_b_ready;
    wire [1:0] axi_cdc_intf_src_0_b_resp;
    wire       axi_cdc_intf_src_0_b_user;
    wire       axi_cdc_intf_src_0_b_valid;
    wire [2:0] axi_cdc_intf_src_0_b_wr_ptr_gray_dst2src;
    wire       axi_cdc_intf_src_0_icn_rst_ni;
    wire [31:0] axi_cdc_intf_src_0_r_data;
    wire [44:0] axi_cdc_intf_src_0_r_data_dst2src;
    wire [8:0] axi_cdc_intf_src_0_r_id;
    wire       axi_cdc_intf_src_0_r_last;
    wire [1:0] axi_cdc_intf_src_0_r_rd_data_ptr_src2dst;
    wire [2:0] axi_cdc_intf_src_0_r_rd_ptr_gray_src2dst;
    wire       axi_cdc_intf_src_0_r_ready;
    wire [1:0] axi_cdc_intf_src_0_r_resp;
    wire       axi_cdc_intf_src_0_r_user;
    wire       axi_cdc_intf_src_0_r_valid;
    wire [2:0] axi_cdc_intf_src_0_r_wr_ptr_gray_dst2src;
    wire       axi_cdc_intf_src_0_src_clk_i;
    wire       axi_cdc_intf_src_0_src_rst_ni;
    wire [31:0] axi_cdc_intf_src_0_w_data;
    wire [37:0] axi_cdc_intf_src_0_w_data_src2dst;
    wire       axi_cdc_intf_src_0_w_last;
    wire [1:0] axi_cdc_intf_src_0_w_rd_data_ptr_dst2src;
    wire [2:0] axi_cdc_intf_src_0_w_rd_ptr_gray_dst2src;
    wire       axi_cdc_intf_src_0_w_ready;
    wire [3:0] axi_cdc_intf_src_0_w_strb;
    wire       axi_cdc_intf_src_0_w_user;
    wire       axi_cdc_intf_src_0_w_valid;
    wire [2:0] axi_cdc_intf_src_0_w_wr_ptr_gray_src2dst;
    // camera_processor_0 port wires:
    wire       camera_processor_0_axi_clk_i;
    wire       camera_processor_0_axi_reset_n_i;
    wire       camera_processor_0_frame_wr_done_intr_o;
    wire [31:0] camera_processor_0_m_axi_csi_araddr_o;
    wire [1:0] camera_processor_0_m_axi_csi_arburst_o;
    wire [3:0] camera_processor_0_m_axi_csi_arcache_o;
    wire [8:0] camera_processor_0_m_axi_csi_arid_o;
    wire [7:0] camera_processor_0_m_axi_csi_arlen_o;
    wire       camera_processor_0_m_axi_csi_arlock_o;
    wire [2:0] camera_processor_0_m_axi_csi_arprot_o;
    wire [3:0] camera_processor_0_m_axi_csi_arqos_o;
    wire       camera_processor_0_m_axi_csi_arready_i;
    wire [3:0] camera_processor_0_m_axi_csi_arregion_o;
    wire [2:0] camera_processor_0_m_axi_csi_arsize_o;
    wire       camera_processor_0_m_axi_csi_aruser_o;
    wire       camera_processor_0_m_axi_csi_arvalid_o;
    wire [31:0] camera_processor_0_m_axi_csi_awaddr_o;
    wire [5:0] camera_processor_0_m_axi_csi_awatop_o;
    wire [1:0] camera_processor_0_m_axi_csi_awburst_o;
    wire [3:0] camera_processor_0_m_axi_csi_awcache_o;
    wire [8:0] camera_processor_0_m_axi_csi_awid_o;
    wire [7:0] camera_processor_0_m_axi_csi_awlen_o;
    wire       camera_processor_0_m_axi_csi_awlock_o;
    wire [2:0] camera_processor_0_m_axi_csi_awprot_o;
    wire [3:0] camera_processor_0_m_axi_csi_awqos_o;
    wire       camera_processor_0_m_axi_csi_awready_i;
    wire [3:0] camera_processor_0_m_axi_csi_awregion_o;
    wire [2:0] camera_processor_0_m_axi_csi_awsize_o;
    wire       camera_processor_0_m_axi_csi_awuser_o;
    wire       camera_processor_0_m_axi_csi_awvalid_o;
    wire [8:0] camera_processor_0_m_axi_csi_bid_i;
    wire       camera_processor_0_m_axi_csi_bready_o;
    wire [1:0] camera_processor_0_m_axi_csi_bresp_i;
    wire       camera_processor_0_m_axi_csi_buser_i;
    wire       camera_processor_0_m_axi_csi_bvalid_i;
    wire [31:0] camera_processor_0_m_axi_csi_rdata_i;
    wire [8:0] camera_processor_0_m_axi_csi_rid_i;
    wire       camera_processor_0_m_axi_csi_rlast_i;
    wire       camera_processor_0_m_axi_csi_rready_o;
    wire [1:0] camera_processor_0_m_axi_csi_rresp_i;
    wire       camera_processor_0_m_axi_csi_ruser_i;
    wire       camera_processor_0_m_axi_csi_rvalid_i;
    wire [31:0] camera_processor_0_m_axi_csi_wdata_o;
    wire       camera_processor_0_m_axi_csi_wlast_o;
    wire       camera_processor_0_m_axi_csi_wready_i;
    wire [3:0] camera_processor_0_m_axi_csi_wstrb_o;
    wire       camera_processor_0_m_axi_csi_wuser_o;
    wire       camera_processor_0_m_axi_csi_wvalid_o;
    wire       camera_processor_0_pixel_clk_i;
    wire       camera_processor_0_reset_n_i;
    wire       camera_processor_0_rx_byte_clk_hs;
    wire [7:0] camera_processor_0_rx_data_hs_0;
    wire [7:0] camera_processor_0_rx_data_hs_1;
    wire [7:0] camera_processor_0_rx_data_hs_2;
    wire [7:0] camera_processor_0_rx_data_hs_3;
    wire       camera_processor_0_rx_valid_hs_0;
    wire       camera_processor_0_rx_valid_hs_1;
    wire       camera_processor_0_rx_valid_hs_2;
    wire       camera_processor_0_rx_valid_hs_3;
    wire [31:0] camera_processor_0_s_axi_csi_araddr_i;
    wire [1:0] camera_processor_0_s_axi_csi_arburst_i;
    wire [3:0] camera_processor_0_s_axi_csi_arcache_i;
    wire [8:0] camera_processor_0_s_axi_csi_arid_i;
    wire [7:0] camera_processor_0_s_axi_csi_arlen_i;
    wire       camera_processor_0_s_axi_csi_arlock_i;
    wire [2:0] camera_processor_0_s_axi_csi_arprot_i;
    wire [3:0] camera_processor_0_s_axi_csi_arqos_i;
    wire       camera_processor_0_s_axi_csi_arready_o;
    wire [3:0] camera_processor_0_s_axi_csi_arregion_i;
    wire [2:0] camera_processor_0_s_axi_csi_arsize_i;
    wire       camera_processor_0_s_axi_csi_aruser_i;
    wire       camera_processor_0_s_axi_csi_arvalid_i;
    wire [31:0] camera_processor_0_s_axi_csi_awaddr_i;
    wire [5:0] camera_processor_0_s_axi_csi_awatop_i;
    wire [1:0] camera_processor_0_s_axi_csi_awburst_i;
    wire [3:0] camera_processor_0_s_axi_csi_awcache_i;
    wire [8:0] camera_processor_0_s_axi_csi_awid_i;
    wire [7:0] camera_processor_0_s_axi_csi_awlen_i;
    wire       camera_processor_0_s_axi_csi_awlock_i;
    wire [2:0] camera_processor_0_s_axi_csi_awprot_i;
    wire [3:0] camera_processor_0_s_axi_csi_awqos_i;
    wire       camera_processor_0_s_axi_csi_awready_o;
    wire [3:0] camera_processor_0_s_axi_csi_awregion_i;
    wire [2:0] camera_processor_0_s_axi_csi_awsize_i;
    wire       camera_processor_0_s_axi_csi_awuser_i;
    wire       camera_processor_0_s_axi_csi_awvalid_i;
    wire [8:0] camera_processor_0_s_axi_csi_bid_o;
    wire       camera_processor_0_s_axi_csi_bready_i;
    wire [1:0] camera_processor_0_s_axi_csi_bresp_o;
    wire       camera_processor_0_s_axi_csi_buser_o;
    wire       camera_processor_0_s_axi_csi_bvalid_o;
    wire [31:0] camera_processor_0_s_axi_csi_rdata_o;
    wire [8:0] camera_processor_0_s_axi_csi_rid_o;
    wire       camera_processor_0_s_axi_csi_rlast_o;
    wire       camera_processor_0_s_axi_csi_rready_i;
    wire [1:0] camera_processor_0_s_axi_csi_rresp_o;
    wire       camera_processor_0_s_axi_csi_ruser_o;
    wire       camera_processor_0_s_axi_csi_rvalid_o;
    wire [31:0] camera_processor_0_s_axi_csi_wdata_i;
    wire       camera_processor_0_s_axi_csi_wlast_i;
    wire       camera_processor_0_s_axi_csi_wready_o;
    wire [3:0] camera_processor_0_s_axi_csi_wstrb_i;
    wire       camera_processor_0_s_axi_csi_wuser_i;
    wire       camera_processor_0_s_axi_csi_wvalid_i;
    // clkpll_0 port wires:
    wire       clkpll_0_CLK_PLL_LOCK;
    wire       clkpll_0_CLK_PLL_OUT;
    wire       clkpll_0_CLK_REF;
    wire [7:0] clkpll_0_DEBUG_CTRL;
    wire [7:0] clkpll_0_ENABLE;
    wire [31:0] clkpll_0_LOOP_CTRL;
    wire [2:0] clkpll_0_M_DIV;
    wire [9:0] clkpll_0_N_DIV;
    wire [3:0] clkpll_0_R_DIV;
    wire [31:0] clkpll_0_SPARE_CTRL;
    wire [31:0] clkpll_0_STATUS1;
    wire [31:0] clkpll_0_STATUS2;
    wire [3:0] clkpll_0_TMUX_1_SEL;
    wire [3:0] clkpll_0_TMUX_2_SEL;
    // d_phy_top_0 port wires:
    wire       d_phy_top_0_clk_i;
    wire       d_phy_top_0_reset_n_i;
    wire       d_phy_top_0_rx_byte_clk_hs;
    wire [7:0] d_phy_top_0_rx_data_hs_0;
    wire [7:0] d_phy_top_0_rx_data_hs_1;
    wire [7:0] d_phy_top_0_rx_data_hs_2;
    wire [7:0] d_phy_top_0_rx_data_hs_3;
    wire       d_phy_top_0_rx_valid_hs_0;
    wire       d_phy_top_0_rx_valid_hs_1;
    wire       d_phy_top_0_rx_valid_hs_2;
    wire       d_phy_top_0_rx_valid_hs_3;
    // periph_axi_demux_1_to_2_wrapper_0 port wires:
    wire       periph_axi_demux_1_to_2_wrapper_0_clk;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_addr;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_ar_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_ar_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_0_ar_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_ar_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_ar_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_addr;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_aw_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_aw_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_0_aw_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_aw_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_aw_valid;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_0_b_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_b_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_0_b_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_b_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_b_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_0_r_data;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_0_r_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_r_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_r_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_0_r_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_r_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_r_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_0_w_data;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_w_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_w_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_0_w_strb;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_w_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_0_w_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_addr;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_ar_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_ar_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_1_ar_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_ar_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_ar_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_addr;
    wire [5:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_atop;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_aw_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_aw_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_master_1_aw_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_aw_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_aw_valid;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_1_b_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_b_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_1_b_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_b_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_b_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_1_r_data;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_master_1_r_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_r_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_r_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_master_1_r_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_r_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_r_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_master_1_w_data;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_w_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_w_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_master_1_w_strb;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_w_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_master_1_w_valid;
    wire       periph_axi_demux_1_to_2_wrapper_0_rst_n;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_addr;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_ar_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_ar_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_ar_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_ar_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_ar_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_addr;
    wire [5:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_atop;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_burst;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_cache;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_id;
    wire [7:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_len;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_aw_lock;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_prot;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_qos;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_aw_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_region;
    wire [2:0] periph_axi_demux_1_to_2_wrapper_0_slave_aw_size;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_aw_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_aw_valid;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_b_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_b_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_b_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_b_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_b_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_r_data;
    wire [8:0] periph_axi_demux_1_to_2_wrapper_0_slave_r_id;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_r_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_r_ready;
    wire [1:0] periph_axi_demux_1_to_2_wrapper_0_slave_r_resp;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_r_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_r_valid;
    wire [31:0] periph_axi_demux_1_to_2_wrapper_0_slave_w_data;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_w_last;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_w_ready;
    wire [3:0] periph_axi_demux_1_to_2_wrapper_0_slave_w_strb;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_w_user;
    wire       periph_axi_demux_1_to_2_wrapper_0_slave_w_valid;
    // subsystem_clock_control_0 port wires:
    wire       subsystem_clock_control_0_clk_out;
    wire       subsystem_clock_control_0_force_cka;
    wire       subsystem_clock_control_0_force_ckb;
    wire [104:0] subsystem_clock_control_0_pll_ctrl_in;
    wire [104:0] subsystem_clock_control_0_pll_ctrl_out;
    wire       subsystem_clock_control_0_pll_ctrl_valid;
    wire       subsystem_clock_control_0_pll_lock;
    wire       subsystem_clock_control_0_pllclk;
    wire       subsystem_clock_control_0_refclk;
    wire       subsystem_clock_control_0_refrstn;
    wire       subsystem_clock_control_0_rstn_out;
    wire       subsystem_clock_control_0_sel_cka;
    wire       subsystem_clock_control_0_subsys_clkena;

    // Assignments for the ports of the encompassing component:
    assign STATUS1 = clkpll_0_pll_status_to_pll_status_pll_status_1;
    assign STATUS2 = clkpll_0_pll_status_to_pll_status_pll_status_2;
    assign axi_master_cam_ar_data_src2dst = axi_cdc_intf_src_0_src_to_axi_master_AR_DATA_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_AR_RD_DATA_PTR_DST2SRC = axi_master_cam_ar_rd_data_ptr_dst2src;
    assign axi_cdc_intf_src_0_src_to_axi_master_AR_RD_PTR_GRAY_DST2SRC = axi_master_cam_ar_rd_ptr_gray_dst2src;
    assign axi_master_cam_ar_wr_ptr_gray_src2dst = axi_cdc_intf_src_0_src_to_axi_master_AR_WR_PTR_GRAY_SRC2DST;
    assign axi_master_cam_aw_data_src2dst = axi_cdc_intf_src_0_src_to_axi_master_AW_DATA_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_AW_RD_DATA_PTR_DST2SRC = axi_master_cam_aw_rd_data_ptr_dst2src;
    assign axi_cdc_intf_src_0_src_to_axi_master_AW_RD_PTR_GRAY_DST2SRC = axi_master_cam_aw_rd_ptr_gray_dst2src;
    assign axi_master_cam_aw_wr_ptr_gray_src2dst = axi_cdc_intf_src_0_src_to_axi_master_AW_WR_PTR_GRAY_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_B_DATA_DST2SRC = axi_master_cam_b_data_dst2src;
    assign axi_master_cam_b_rd_data_ptr_src2dst = axi_cdc_intf_src_0_src_to_axi_master_B_RD_DATA_PTR_SRC2DST;
    assign axi_master_cam_b_rd_ptr_gray_src2dst = axi_cdc_intf_src_0_src_to_axi_master_B_RD_PTR_GRAY_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_B_WR_PTR_GRAY_DST2SRC = axi_master_cam_b_wr_ptr_gray_dst2src;
    assign axi_cdc_intf_src_0_src_to_axi_master_R_DATA_DST2SRC = axi_master_cam_r_data_dst2src;
    assign axi_master_cam_r_rd_data_ptr_src2dst = axi_cdc_intf_src_0_src_to_axi_master_R_RD_DATA_PTR_SRC2DST;
    assign axi_master_cam_r_rd_ptr_gray_src2dst = axi_cdc_intf_src_0_src_to_axi_master_R_RD_PTR_GRAY_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_R_WR_PTR_GRAY_DST2SRC = axi_master_cam_r_wr_ptr_gray_dst2src;
    assign axi_master_cam_w_data_src2dst = axi_cdc_intf_src_0_src_to_axi_master_W_DATA_SRC2DST;
    assign axi_cdc_intf_src_0_src_to_axi_master_W_RD_DATA_PTR_DST2SRC = axi_master_cam_w_rd_data_ptr_dst2src;
    assign axi_cdc_intf_src_0_src_to_axi_master_W_RD_PTR_GRAY_DST2SRC = axi_master_cam_w_rd_ptr_gray_dst2src;
    assign axi_master_cam_w_wr_ptr_gray_src2dst = axi_cdc_intf_src_0_src_to_axi_master_W_WR_PTR_GRAY_SRC2DST;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AR_DATA_SRC2DST = axi_slave_cam_ar_data_src2dst;
    assign axi_slave_cam_ar_rd_data_ptr_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_DATA_PTR_DST2SRC;
    assign axi_slave_cam_ar_rd_ptr_gray_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AR_WR_PTR_GRAY_SRC2DST = axi_slave_cam_ar_wr_ptr_gray_src2dst;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AW_DATA_SRC2DST = axi_slave_cam_aw_data_src2dst;
    assign axi_slave_cam_aw_rd_data_ptr_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_DATA_PTR_DST2SRC;
    assign axi_slave_cam_aw_rd_ptr_gray_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AW_WR_PTR_GRAY_SRC2DST = axi_slave_cam_aw_wr_ptr_gray_src2dst;
    assign axi_slave_cam_b_data_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_B_DATA_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_DATA_PTR_SRC2DST = axi_slave_cam_b_rd_data_ptr_src2dst;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_PTR_GRAY_SRC2DST = axi_slave_cam_b_rd_ptr_gray_src2dst;
    assign axi_slave_cam_b_wr_ptr_gray_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_B_WR_PTR_GRAY_DST2SRC;
    assign axi_slave_cam_r_data_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_R_DATA_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_DATA_PTR_SRC2DST = axi_slave_cam_r_rd_data_ptr_src2dst;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_PTR_GRAY_SRC2DST = axi_slave_cam_r_rd_ptr_gray_src2dst;
    assign axi_slave_cam_r_wr_ptr_gray_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_R_WR_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_W_DATA_SRC2DST = axi_slave_cam_w_data_src2dst;
    assign axi_slave_cam_w_rd_data_ptr_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_DATA_PTR_DST2SRC;
    assign axi_slave_cam_w_rd_ptr_gray_dst2src = axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_W_WR_PTR_GRAY_SRC2DST = axi_slave_cam_w_wr_ptr_gray_src2dst;
    assign subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[1] = force_cka;
    assign subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[2] = force_ckb;
    assign frame_wr_done_intr_o = camera_processor_0_IRQ_to_IRQ_IRQ;
    assign axi_cdc_intf_src_0_icn_rstn_to_icn_rstn_rst_n = icn_rst_ni;
    assign interrupt_o = apb_i2c_0_irq_master_to_irq_master_IRQ;
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DEBUG_CTRL = pll_ctrl_in[55:48];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DIV = pll_ctrl_in[104:88];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_ENABLE = pll_ctrl_in[47:40];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_LOOP_CTRL = pll_ctrl_in[87:56];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_SPARE_CTRL = pll_ctrl_in[39:8];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_TMUX_SEL = pll_ctrl_in[7:0];
    assign subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_VALID = pll_ctrl_valid;
    assign subsystem_clock_control_0_ref_clk_to_ref_clk_clk = refclk;
    assign subsystem_clock_control_0_ref_rstn_to_ref_rstn_rst_n = refrstn;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_i = scl_pad_i;
    assign scl_pad_o = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_o;
    assign scl_padoen_o = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_oen;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_i = sda_pad_i;
    assign sda_pad_o = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_o;
    assign sda_padoen_o = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_oen;
    assign subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[0] = sel_cka;
    assign subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[3] = subsys_clkena;

    // apb_i2c_0 assignments:
    assign apb_i2c_0_HCLK = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign apb_i2c_0_HRESETn = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign apb_i2c_0_PADDR = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PADDR;
    assign apb_i2c_0_PENABLE = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PENABLE;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PRDATA = apb_i2c_0_PRDATA;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PREADY = apb_i2c_0_PREADY;
    assign apb_i2c_0_PSEL = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSEL;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSLVERR = apb_i2c_0_PSLVERR;
    assign apb_i2c_0_PWDATA = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWDATA;
    assign apb_i2c_0_PWRITE = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWRITE;
    assign apb_i2c_0_irq_master_to_irq_master_IRQ = apb_i2c_0_interrupt_o;
    assign apb_i2c_0_scl_pad_i = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_i;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_o = apb_i2c_0_scl_pad_o;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_scl_oen = apb_i2c_0_scl_padoen_o;
    assign apb_i2c_0_sda_pad_i = apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_i;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_o = apb_i2c_0_sda_pad_o;
    assign apb_i2c_0_i2c_master_slave_to_i2c_master_slave_sda_oen = apb_i2c_0_sda_padoen_o;
    // axi2apb_0 assignments:
    assign axi2apb_0_ACLK = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign axi2apb_0_ARADDR_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ADDR;
    assign axi2apb_0_ARBURST_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_BURST;
    assign axi2apb_0_ARCACHE_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_CACHE;
    assign axi2apb_0_ARESETn = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign axi2apb_0_ARID_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ID;
    assign axi2apb_0_ARLEN_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LEN;
    assign axi2apb_0_ARLOCK_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LOCK;
    assign axi2apb_0_ARPROT_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_PROT;
    assign axi2apb_0_ARQOS_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_READY = axi2apb_0_ARREADY_o;
    assign axi2apb_0_ARREGION_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_REGION;
    assign axi2apb_0_ARSIZE_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_SIZE;
    assign axi2apb_0_ARUSER_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_USER;
    assign axi2apb_0_ARVALID_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_VALID;
    assign axi2apb_0_AWADDR_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ADDR;
    assign axi2apb_0_AWBURST_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_BURST;
    assign axi2apb_0_AWCACHE_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_CACHE;
    assign axi2apb_0_AWID_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ID;
    assign axi2apb_0_AWLEN_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LEN;
    assign axi2apb_0_AWLOCK_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LOCK;
    assign axi2apb_0_AWPROT_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_PROT;
    assign axi2apb_0_AWQOS_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_READY = axi2apb_0_AWREADY_o;
    assign axi2apb_0_AWREGION_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_REGION;
    assign axi2apb_0_AWSIZE_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_SIZE;
    assign axi2apb_0_AWUSER_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_USER;
    assign axi2apb_0_AWVALID_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_ID = axi2apb_0_BID_o;
    assign axi2apb_0_BREADY_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_RESP = axi2apb_0_BRESP_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_USER = axi2apb_0_BUSER_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_VALID = axi2apb_0_BVALID_o;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PADDR = axi2apb_0_PADDR;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PENABLE = axi2apb_0_PENABLE;
    assign axi2apb_0_PRDATA = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PRDATA;
    assign axi2apb_0_PREADY = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PREADY;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSEL = axi2apb_0_PSEL;
    assign axi2apb_0_PSLVERR = axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PSLVERR;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWDATA = axi2apb_0_PWDATA;
    assign axi2apb_0_apb_master_to_apb_i2c_0_apb_slave_PWRITE = axi2apb_0_PWRITE;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_DATA = axi2apb_0_RDATA_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_ID = axi2apb_0_RID_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_LAST = axi2apb_0_RLAST_o;
    assign axi2apb_0_RREADY_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_RESP = axi2apb_0_RRESP_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_USER = axi2apb_0_RUSER_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_VALID = axi2apb_0_RVALID_o;
    assign axi2apb_0_WDATA_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_DATA;
    assign axi2apb_0_WLAST_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_LAST;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_READY = axi2apb_0_WREADY_o;
    assign axi2apb_0_WSTRB_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_STRB;
    assign axi2apb_0_WUSER_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_USER;
    assign axi2apb_0_WVALID_i = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_VALID;
    // axi_cdc_intf_dst_0 assignments:
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ADDR = axi_cdc_intf_dst_0_ar_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_BURST = axi_cdc_intf_dst_0_ar_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_CACHE = axi_cdc_intf_dst_0_ar_cache;
    assign axi_cdc_intf_dst_0_ar_data_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_AR_DATA_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ID = axi_cdc_intf_dst_0_ar_id;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LEN = axi_cdc_intf_dst_0_ar_len;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LOCK = axi_cdc_intf_dst_0_ar_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_PROT = axi_cdc_intf_dst_0_ar_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_QOS = axi_cdc_intf_dst_0_ar_qos;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_DATA_PTR_DST2SRC = axi_cdc_intf_dst_0_ar_rd_data_ptr_dst2src;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AR_RD_PTR_GRAY_DST2SRC = axi_cdc_intf_dst_0_ar_rd_ptr_gray_dst2src;
    assign axi_cdc_intf_dst_0_ar_ready = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_REGION = axi_cdc_intf_dst_0_ar_region;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_SIZE = axi_cdc_intf_dst_0_ar_size;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_USER = axi_cdc_intf_dst_0_ar_user;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_VALID = axi_cdc_intf_dst_0_ar_valid;
    assign axi_cdc_intf_dst_0_ar_wr_ptr_gray_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_AR_WR_PTR_GRAY_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ADDR = axi_cdc_intf_dst_0_aw_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ATOP = axi_cdc_intf_dst_0_aw_atop;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_BURST = axi_cdc_intf_dst_0_aw_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_CACHE = axi_cdc_intf_dst_0_aw_cache;
    assign axi_cdc_intf_dst_0_aw_data_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_AW_DATA_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ID = axi_cdc_intf_dst_0_aw_id;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LEN = axi_cdc_intf_dst_0_aw_len;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LOCK = axi_cdc_intf_dst_0_aw_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_PROT = axi_cdc_intf_dst_0_aw_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_QOS = axi_cdc_intf_dst_0_aw_qos;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_DATA_PTR_DST2SRC = axi_cdc_intf_dst_0_aw_rd_data_ptr_dst2src;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_AW_RD_PTR_GRAY_DST2SRC = axi_cdc_intf_dst_0_aw_rd_ptr_gray_dst2src;
    assign axi_cdc_intf_dst_0_aw_ready = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_REGION = axi_cdc_intf_dst_0_aw_region;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_SIZE = axi_cdc_intf_dst_0_aw_size;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_USER = axi_cdc_intf_dst_0_aw_user;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_VALID = axi_cdc_intf_dst_0_aw_valid;
    assign axi_cdc_intf_dst_0_aw_wr_ptr_gray_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_AW_WR_PTR_GRAY_SRC2DST;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_B_DATA_DST2SRC = axi_cdc_intf_dst_0_b_data_dst2src;
    assign axi_cdc_intf_dst_0_b_id = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_ID;
    assign axi_cdc_intf_dst_0_b_rd_data_ptr_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_DATA_PTR_SRC2DST;
    assign axi_cdc_intf_dst_0_b_rd_ptr_gray_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_B_RD_PTR_GRAY_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_READY = axi_cdc_intf_dst_0_b_ready;
    assign axi_cdc_intf_dst_0_b_resp = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_RESP;
    assign axi_cdc_intf_dst_0_b_user = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_USER;
    assign axi_cdc_intf_dst_0_b_valid = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_VALID;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_B_WR_PTR_GRAY_DST2SRC = axi_cdc_intf_dst_0_b_wr_ptr_gray_dst2src;
    assign axi_cdc_intf_dst_0_dst_clk_i = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign axi_cdc_intf_dst_0_dst_rst_ni = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign axi_cdc_intf_dst_0_icn_rst_ni = axi_cdc_intf_src_0_icn_rstn_to_icn_rstn_rst_n;
    assign axi_cdc_intf_dst_0_r_data = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_DATA;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_R_DATA_DST2SRC = axi_cdc_intf_dst_0_r_data_dst2src;
    assign axi_cdc_intf_dst_0_r_id = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_ID;
    assign axi_cdc_intf_dst_0_r_last = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_LAST;
    assign axi_cdc_intf_dst_0_r_rd_data_ptr_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_DATA_PTR_SRC2DST;
    assign axi_cdc_intf_dst_0_r_rd_ptr_gray_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_R_RD_PTR_GRAY_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_READY = axi_cdc_intf_dst_0_r_ready;
    assign axi_cdc_intf_dst_0_r_resp = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_RESP;
    assign axi_cdc_intf_dst_0_r_user = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_USER;
    assign axi_cdc_intf_dst_0_r_valid = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_VALID;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_R_WR_PTR_GRAY_DST2SRC = axi_cdc_intf_dst_0_r_wr_ptr_gray_dst2src;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_DATA = axi_cdc_intf_dst_0_w_data;
    assign axi_cdc_intf_dst_0_w_data_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_W_DATA_SRC2DST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_LAST = axi_cdc_intf_dst_0_w_last;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_DATA_PTR_DST2SRC = axi_cdc_intf_dst_0_w_rd_data_ptr_dst2src;
    assign axi_cdc_intf_dst_0_dst_to_axi_slave_W_RD_PTR_GRAY_DST2SRC = axi_cdc_intf_dst_0_w_rd_ptr_gray_dst2src;
    assign axi_cdc_intf_dst_0_w_ready = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_STRB = axi_cdc_intf_dst_0_w_strb;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_USER = axi_cdc_intf_dst_0_w_user;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_VALID = axi_cdc_intf_dst_0_w_valid;
    assign axi_cdc_intf_dst_0_w_wr_ptr_gray_src2dst = axi_cdc_intf_dst_0_dst_to_axi_slave_W_WR_PTR_GRAY_SRC2DST;
    // axi_cdc_intf_src_0 assignments:
    assign axi_cdc_intf_src_0_ar_addr = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ADDR;
    assign axi_cdc_intf_src_0_ar_burst = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_BURST;
    assign axi_cdc_intf_src_0_ar_cache = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_CACHE;
    assign axi_cdc_intf_src_0_src_to_axi_master_AR_DATA_SRC2DST = axi_cdc_intf_src_0_ar_data_src2dst;
    assign axi_cdc_intf_src_0_ar_id = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ID;
    assign axi_cdc_intf_src_0_ar_len = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LEN;
    assign axi_cdc_intf_src_0_ar_lock = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LOCK;
    assign axi_cdc_intf_src_0_ar_prot = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_PROT;
    assign axi_cdc_intf_src_0_ar_qos = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_QOS;
    assign axi_cdc_intf_src_0_ar_rd_data_ptr_dst2src = axi_cdc_intf_src_0_src_to_axi_master_AR_RD_DATA_PTR_DST2SRC;
    assign axi_cdc_intf_src_0_ar_rd_ptr_gray_dst2src = axi_cdc_intf_src_0_src_to_axi_master_AR_RD_PTR_GRAY_DST2SRC;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_READY = axi_cdc_intf_src_0_ar_ready;
    assign axi_cdc_intf_src_0_ar_region = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_REGION;
    assign axi_cdc_intf_src_0_ar_size = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_SIZE;
    assign axi_cdc_intf_src_0_ar_user = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_USER;
    assign axi_cdc_intf_src_0_ar_valid = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_VALID;
    assign axi_cdc_intf_src_0_src_to_axi_master_AR_WR_PTR_GRAY_SRC2DST = axi_cdc_intf_src_0_ar_wr_ptr_gray_src2dst;
    assign axi_cdc_intf_src_0_aw_addr = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ADDR;
    assign axi_cdc_intf_src_0_aw_atop = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ATOP;
    assign axi_cdc_intf_src_0_aw_burst = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_BURST;
    assign axi_cdc_intf_src_0_aw_cache = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_CACHE;
    assign axi_cdc_intf_src_0_src_to_axi_master_AW_DATA_SRC2DST = axi_cdc_intf_src_0_aw_data_src2dst;
    assign axi_cdc_intf_src_0_aw_id = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ID;
    assign axi_cdc_intf_src_0_aw_len = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LEN;
    assign axi_cdc_intf_src_0_aw_lock = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LOCK;
    assign axi_cdc_intf_src_0_aw_prot = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_PROT;
    assign axi_cdc_intf_src_0_aw_qos = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_QOS;
    assign axi_cdc_intf_src_0_aw_rd_data_ptr_dst2src = axi_cdc_intf_src_0_src_to_axi_master_AW_RD_DATA_PTR_DST2SRC;
    assign axi_cdc_intf_src_0_aw_rd_ptr_gray_dst2src = axi_cdc_intf_src_0_src_to_axi_master_AW_RD_PTR_GRAY_DST2SRC;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_READY = axi_cdc_intf_src_0_aw_ready;
    assign axi_cdc_intf_src_0_aw_region = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_REGION;
    assign axi_cdc_intf_src_0_aw_size = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_SIZE;
    assign axi_cdc_intf_src_0_aw_user = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_USER;
    assign axi_cdc_intf_src_0_aw_valid = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_VALID;
    assign axi_cdc_intf_src_0_src_to_axi_master_AW_WR_PTR_GRAY_SRC2DST = axi_cdc_intf_src_0_aw_wr_ptr_gray_src2dst;
    assign axi_cdc_intf_src_0_b_data_dst2src = axi_cdc_intf_src_0_src_to_axi_master_B_DATA_DST2SRC;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_ID = axi_cdc_intf_src_0_b_id;
    assign axi_cdc_intf_src_0_src_to_axi_master_B_RD_DATA_PTR_SRC2DST = axi_cdc_intf_src_0_b_rd_data_ptr_src2dst;
    assign axi_cdc_intf_src_0_src_to_axi_master_B_RD_PTR_GRAY_SRC2DST = axi_cdc_intf_src_0_b_rd_ptr_gray_src2dst;
    assign axi_cdc_intf_src_0_b_ready = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_READY;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_RESP = axi_cdc_intf_src_0_b_resp;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_USER = axi_cdc_intf_src_0_b_user;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_VALID = axi_cdc_intf_src_0_b_valid;
    assign axi_cdc_intf_src_0_b_wr_ptr_gray_dst2src = axi_cdc_intf_src_0_src_to_axi_master_B_WR_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_src_0_icn_rst_ni = axi_cdc_intf_src_0_icn_rstn_to_icn_rstn_rst_n;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_DATA = axi_cdc_intf_src_0_r_data;
    assign axi_cdc_intf_src_0_r_data_dst2src = axi_cdc_intf_src_0_src_to_axi_master_R_DATA_DST2SRC;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_ID = axi_cdc_intf_src_0_r_id;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_LAST = axi_cdc_intf_src_0_r_last;
    assign axi_cdc_intf_src_0_src_to_axi_master_R_RD_DATA_PTR_SRC2DST = axi_cdc_intf_src_0_r_rd_data_ptr_src2dst;
    assign axi_cdc_intf_src_0_src_to_axi_master_R_RD_PTR_GRAY_SRC2DST = axi_cdc_intf_src_0_r_rd_ptr_gray_src2dst;
    assign axi_cdc_intf_src_0_r_ready = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_READY;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_RESP = axi_cdc_intf_src_0_r_resp;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_USER = axi_cdc_intf_src_0_r_user;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_VALID = axi_cdc_intf_src_0_r_valid;
    assign axi_cdc_intf_src_0_r_wr_ptr_gray_dst2src = axi_cdc_intf_src_0_src_to_axi_master_R_WR_PTR_GRAY_DST2SRC;
    assign axi_cdc_intf_src_0_src_clk_i = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign axi_cdc_intf_src_0_src_rst_ni = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign axi_cdc_intf_src_0_w_data = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_DATA;
    assign axi_cdc_intf_src_0_src_to_axi_master_W_DATA_SRC2DST = axi_cdc_intf_src_0_w_data_src2dst;
    assign axi_cdc_intf_src_0_w_last = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_LAST;
    assign axi_cdc_intf_src_0_w_rd_data_ptr_dst2src = axi_cdc_intf_src_0_src_to_axi_master_W_RD_DATA_PTR_DST2SRC;
    assign axi_cdc_intf_src_0_w_rd_ptr_gray_dst2src = axi_cdc_intf_src_0_src_to_axi_master_W_RD_PTR_GRAY_DST2SRC;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_READY = axi_cdc_intf_src_0_w_ready;
    assign axi_cdc_intf_src_0_w_strb = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_STRB;
    assign axi_cdc_intf_src_0_w_user = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_USER;
    assign axi_cdc_intf_src_0_w_valid = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_VALID;
    assign axi_cdc_intf_src_0_src_to_axi_master_W_WR_PTR_GRAY_SRC2DST = axi_cdc_intf_src_0_w_wr_ptr_gray_src2dst;
    // camera_processor_0 assignments:
    assign camera_processor_0_axi_clk_i = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign camera_processor_0_axi_reset_n_i = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign camera_processor_0_IRQ_to_IRQ_IRQ = camera_processor_0_frame_wr_done_intr_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ADDR = camera_processor_0_m_axi_csi_araddr_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_BURST = camera_processor_0_m_axi_csi_arburst_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_CACHE = camera_processor_0_m_axi_csi_arcache_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_ID = camera_processor_0_m_axi_csi_arid_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LEN = camera_processor_0_m_axi_csi_arlen_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_LOCK = camera_processor_0_m_axi_csi_arlock_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_PROT = camera_processor_0_m_axi_csi_arprot_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_QOS = camera_processor_0_m_axi_csi_arqos_o;
    assign camera_processor_0_m_axi_csi_arready_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_READY;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_REGION = camera_processor_0_m_axi_csi_arregion_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_SIZE = camera_processor_0_m_axi_csi_arsize_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_USER = camera_processor_0_m_axi_csi_aruser_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AR_VALID = camera_processor_0_m_axi_csi_arvalid_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ADDR = camera_processor_0_m_axi_csi_awaddr_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ATOP = camera_processor_0_m_axi_csi_awatop_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_BURST = camera_processor_0_m_axi_csi_awburst_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_CACHE = camera_processor_0_m_axi_csi_awcache_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_ID = camera_processor_0_m_axi_csi_awid_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LEN = camera_processor_0_m_axi_csi_awlen_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_LOCK = camera_processor_0_m_axi_csi_awlock_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_PROT = camera_processor_0_m_axi_csi_awprot_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_QOS = camera_processor_0_m_axi_csi_awqos_o;
    assign camera_processor_0_m_axi_csi_awready_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_READY;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_REGION = camera_processor_0_m_axi_csi_awregion_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_SIZE = camera_processor_0_m_axi_csi_awsize_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_USER = camera_processor_0_m_axi_csi_awuser_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_AW_VALID = camera_processor_0_m_axi_csi_awvalid_o;
    assign camera_processor_0_m_axi_csi_bid_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_ID;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_READY = camera_processor_0_m_axi_csi_bready_o;
    assign camera_processor_0_m_axi_csi_bresp_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_RESP;
    assign camera_processor_0_m_axi_csi_buser_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_USER;
    assign camera_processor_0_m_axi_csi_bvalid_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_B_VALID;
    assign camera_processor_0_m_axi_csi_rdata_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_DATA;
    assign camera_processor_0_m_axi_csi_rid_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_ID;
    assign camera_processor_0_m_axi_csi_rlast_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_LAST;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_READY = camera_processor_0_m_axi_csi_rready_o;
    assign camera_processor_0_m_axi_csi_rresp_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_RESP;
    assign camera_processor_0_m_axi_csi_ruser_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_USER;
    assign camera_processor_0_m_axi_csi_rvalid_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_R_VALID;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_DATA = camera_processor_0_m_axi_csi_wdata_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_LAST = camera_processor_0_m_axi_csi_wlast_o;
    assign camera_processor_0_m_axi_csi_wready_i = camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_READY;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_STRB = camera_processor_0_m_axi_csi_wstrb_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_USER = camera_processor_0_m_axi_csi_wuser_o;
    assign camera_processor_0_AXI_MASTER_to_axi_cdc_intf_src_0_dst_W_VALID = camera_processor_0_m_axi_csi_wvalid_o;
    assign camera_processor_0_pixel_clk_i = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign camera_processor_0_reset_n_i = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign camera_processor_0_rx_byte_clk_hs = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxByteClkHS;
    assign camera_processor_0_rx_data_hs_0 = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[7:0];
    assign camera_processor_0_rx_data_hs_1[7:0] = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[15:8];
    assign camera_processor_0_rx_data_hs_2[7:0] = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[23:16];
    assign camera_processor_0_rx_data_hs_3[7:0] = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[31:24];
    assign camera_processor_0_rx_valid_hs_0 = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[0];
    assign camera_processor_0_rx_valid_hs_1 = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[1];
    assign camera_processor_0_rx_valid_hs_2 = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[2];
    assign camera_processor_0_rx_valid_hs_3 = d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[3];
    assign camera_processor_0_s_axi_csi_araddr_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ADDR;
    assign camera_processor_0_s_axi_csi_arburst_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_BURST;
    assign camera_processor_0_s_axi_csi_arcache_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_CACHE;
    assign camera_processor_0_s_axi_csi_arid_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ID;
    assign camera_processor_0_s_axi_csi_arlen_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LEN;
    assign camera_processor_0_s_axi_csi_arlock_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LOCK;
    assign camera_processor_0_s_axi_csi_arprot_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_PROT;
    assign camera_processor_0_s_axi_csi_arqos_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_READY = camera_processor_0_s_axi_csi_arready_o;
    assign camera_processor_0_s_axi_csi_arregion_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_REGION;
    assign camera_processor_0_s_axi_csi_arsize_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_SIZE;
    assign camera_processor_0_s_axi_csi_aruser_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_USER;
    assign camera_processor_0_s_axi_csi_arvalid_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_VALID;
    assign camera_processor_0_s_axi_csi_awaddr_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ADDR;
    assign camera_processor_0_s_axi_csi_awatop_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ATOP;
    assign camera_processor_0_s_axi_csi_awburst_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_BURST;
    assign camera_processor_0_s_axi_csi_awcache_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_CACHE;
    assign camera_processor_0_s_axi_csi_awid_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ID;
    assign camera_processor_0_s_axi_csi_awlen_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LEN;
    assign camera_processor_0_s_axi_csi_awlock_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LOCK;
    assign camera_processor_0_s_axi_csi_awprot_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_PROT;
    assign camera_processor_0_s_axi_csi_awqos_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_READY = camera_processor_0_s_axi_csi_awready_o;
    assign camera_processor_0_s_axi_csi_awregion_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_REGION;
    assign camera_processor_0_s_axi_csi_awsize_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_SIZE;
    assign camera_processor_0_s_axi_csi_awuser_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_USER;
    assign camera_processor_0_s_axi_csi_awvalid_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_ID = camera_processor_0_s_axi_csi_bid_o;
    assign camera_processor_0_s_axi_csi_bready_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_RESP = camera_processor_0_s_axi_csi_bresp_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_USER = camera_processor_0_s_axi_csi_buser_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_VALID = camera_processor_0_s_axi_csi_bvalid_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_DATA = camera_processor_0_s_axi_csi_rdata_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_ID = camera_processor_0_s_axi_csi_rid_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_LAST = camera_processor_0_s_axi_csi_rlast_o;
    assign camera_processor_0_s_axi_csi_rready_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_RESP = camera_processor_0_s_axi_csi_rresp_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_USER = camera_processor_0_s_axi_csi_ruser_o;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_VALID = camera_processor_0_s_axi_csi_rvalid_o;
    assign camera_processor_0_s_axi_csi_wdata_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_DATA;
    assign camera_processor_0_s_axi_csi_wlast_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_LAST;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_READY = camera_processor_0_s_axi_csi_wready_o;
    assign camera_processor_0_s_axi_csi_wstrb_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_STRB;
    assign camera_processor_0_s_axi_csi_wuser_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_USER;
    assign camera_processor_0_s_axi_csi_wvalid_i = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_VALID;
    // clkpll_0 assignments:
    assign clkpll_0_CLK_PLL_LOCK_to_subsystem_clock_control_0_pll_lock = clkpll_0_CLK_PLL_LOCK;
    assign clkpll_0_pll_clk_to_subsystem_clock_control_0_pll_clk_clk = clkpll_0_CLK_PLL_OUT;
    assign clkpll_0_CLK_REF = subsystem_clock_control_0_ref_clk_to_ref_clk_clk;
    assign clkpll_0_DEBUG_CTRL = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DEBUG_CTRL;
    assign clkpll_0_ENABLE = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_ENABLE;
    assign clkpll_0_LOOP_CTRL = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_LOOP_CTRL;
    assign clkpll_0_M_DIV[2:0] = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DIV[16:14];
    assign clkpll_0_N_DIV[9:0] = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DIV[13:4];
    assign clkpll_0_R_DIV = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DIV[3:0];
    assign clkpll_0_SPARE_CTRL = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_SPARE_CTRL;
    assign clkpll_0_pll_status_to_pll_status_pll_status_1 = clkpll_0_STATUS1;
    assign clkpll_0_pll_status_to_pll_status_pll_status_2 = clkpll_0_STATUS2;
    assign clkpll_0_TMUX_1_SEL = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_TMUX_SEL[3:0];
    assign clkpll_0_TMUX_2_SEL[3:0] = subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_TMUX_SEL[7:4];
    // d_phy_top_0 assignments:
    assign d_phy_top_0_clk_i = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign d_phy_top_0_reset_n_i = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxByteClkHS = d_phy_top_0_rx_byte_clk_hs;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[7:0] = d_phy_top_0_rx_data_hs_0;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[15:8] = d_phy_top_0_rx_data_hs_1[7:0];
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[23:16] = d_phy_top_0_rx_data_hs_2[7:0];
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxDataHS[31:24] = d_phy_top_0_rx_data_hs_3[7:0];
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[0] = d_phy_top_0_rx_valid_hs_0;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[1] = d_phy_top_0_rx_valid_hs_1;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[2] = d_phy_top_0_rx_valid_hs_2;
    assign d_phy_top_0_PPI_MASTER_to_camera_processor_0_PPI_SLAVE_RxValidHS[3] = d_phy_top_0_rx_valid_hs_3;
    // periph_axi_demux_1_to_2_wrapper_0 assignments:
    assign periph_axi_demux_1_to_2_wrapper_0_clk = subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ADDR = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_BURST = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_CACHE = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_cache;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_ID = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_id;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LEN = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_len;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_LOCK = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_PROT = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_QOS = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_qos;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_ar_ready = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_REGION = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_region;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_SIZE = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_size;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_USER = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AR_VALID = periph_axi_demux_1_to_2_wrapper_0_master_0_ar_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ADDR = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_BURST = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_CACHE = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_cache;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_ID = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_id;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LEN = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_len;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_LOCK = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_PROT = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_QOS = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_qos;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_aw_ready = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_REGION = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_region;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_SIZE = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_size;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_USER = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_AW_VALID = periph_axi_demux_1_to_2_wrapper_0_master_0_aw_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_b_id = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_READY = periph_axi_demux_1_to_2_wrapper_0_master_0_b_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_b_resp = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_RESP;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_b_user = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_b_valid = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_B_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_data = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_DATA;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_id = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_last = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_LAST;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_READY = periph_axi_demux_1_to_2_wrapper_0_master_0_r_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_resp = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_RESP;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_user = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_r_valid = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_R_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_DATA = periph_axi_demux_1_to_2_wrapper_0_master_0_w_data;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_LAST = periph_axi_demux_1_to_2_wrapper_0_master_0_w_last;
    assign periph_axi_demux_1_to_2_wrapper_0_master_0_w_ready = periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_STRB = periph_axi_demux_1_to_2_wrapper_0_master_0_w_strb;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_USER = periph_axi_demux_1_to_2_wrapper_0_master_0_w_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master0_to_axi2apb_0_axi_slave_W_VALID = periph_axi_demux_1_to_2_wrapper_0_master_0_w_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ADDR = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_BURST = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_CACHE = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_cache;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_ID = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_id;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LEN = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_len;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_LOCK = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_PROT = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_QOS = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_qos;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_ar_ready = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_REGION = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_region;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_SIZE = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_size;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_USER = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AR_VALID = periph_axi_demux_1_to_2_wrapper_0_master_1_ar_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ADDR = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_addr;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ATOP = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_atop;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_BURST = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_burst;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_CACHE = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_cache;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_ID = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_id;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LEN = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_len;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_LOCK = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_lock;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_PROT = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_prot;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_QOS = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_qos;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_aw_ready = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_REGION = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_region;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_SIZE = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_size;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_USER = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_AW_VALID = periph_axi_demux_1_to_2_wrapper_0_master_1_aw_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_b_id = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_READY = periph_axi_demux_1_to_2_wrapper_0_master_1_b_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_b_resp = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_RESP;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_b_user = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_b_valid = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_B_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_data = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_DATA;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_id = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_last = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_LAST;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_READY = periph_axi_demux_1_to_2_wrapper_0_master_1_r_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_resp = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_RESP;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_user = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_r_valid = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_R_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_DATA = periph_axi_demux_1_to_2_wrapper_0_master_1_w_data;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_LAST = periph_axi_demux_1_to_2_wrapper_0_master_1_w_last;
    assign periph_axi_demux_1_to_2_wrapper_0_master_1_w_ready = periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_STRB = periph_axi_demux_1_to_2_wrapper_0_master_1_w_strb;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_USER = periph_axi_demux_1_to_2_wrapper_0_master_1_w_user;
    assign periph_axi_demux_1_to_2_wrapper_0_master1_to_camera_processor_0_AXI_SLAVE_W_VALID = periph_axi_demux_1_to_2_wrapper_0_master_1_w_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_rst_n = subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_addr = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ADDR;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_burst = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_BURST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_cache = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_CACHE;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_id = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_len = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LEN;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_lock = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_LOCK;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_prot = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_PROT;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_qos = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_READY = periph_axi_demux_1_to_2_wrapper_0_slave_ar_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_region = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_REGION;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_size = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_SIZE;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_user = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_ar_valid = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AR_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_addr = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ADDR;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_atop = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ATOP;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_burst = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_BURST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_cache = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_CACHE;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_id = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_ID;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_len = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LEN;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_lock = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_LOCK;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_prot = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_PROT;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_qos = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_QOS;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_READY = periph_axi_demux_1_to_2_wrapper_0_slave_aw_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_region = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_REGION;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_size = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_SIZE;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_user = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_aw_valid = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_AW_VALID;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_ID = periph_axi_demux_1_to_2_wrapper_0_slave_b_id;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_b_ready = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_RESP = periph_axi_demux_1_to_2_wrapper_0_slave_b_resp;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_USER = periph_axi_demux_1_to_2_wrapper_0_slave_b_user;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_B_VALID = periph_axi_demux_1_to_2_wrapper_0_slave_b_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_DATA = periph_axi_demux_1_to_2_wrapper_0_slave_r_data;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_ID = periph_axi_demux_1_to_2_wrapper_0_slave_r_id;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_LAST = periph_axi_demux_1_to_2_wrapper_0_slave_r_last;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_r_ready = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_READY;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_RESP = periph_axi_demux_1_to_2_wrapper_0_slave_r_resp;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_USER = periph_axi_demux_1_to_2_wrapper_0_slave_r_user;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_R_VALID = periph_axi_demux_1_to_2_wrapper_0_slave_r_valid;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_w_data = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_DATA;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_w_last = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_LAST;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_READY = periph_axi_demux_1_to_2_wrapper_0_slave_w_ready;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_w_strb = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_STRB;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_w_user = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_USER;
    assign periph_axi_demux_1_to_2_wrapper_0_slave_w_valid = periph_axi_demux_1_to_2_wrapper_0_slave_to_axi_cdc_intf_dst_0_src_W_VALID;
    // subsystem_clock_control_0 assignments:
    assign subsystem_clock_control_0_clk_to_axi2apb_0_clk_clk = subsystem_clock_control_0_clk_out;
    assign subsystem_clock_control_0_force_cka = subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[1];
    assign subsystem_clock_control_0_force_ckb = subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[2];
    assign subsystem_clock_control_0_pll_ctrl_in[55:48] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DEBUG_CTRL;
    assign subsystem_clock_control_0_pll_ctrl_in[104:88] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_DIV;
    assign subsystem_clock_control_0_pll_ctrl_in[47:40] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_ENABLE;
    assign subsystem_clock_control_0_pll_ctrl_in[87:56] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_LOOP_CTRL;
    assign subsystem_clock_control_0_pll_ctrl_in[39:8] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_SPARE_CTRL;
    assign subsystem_clock_control_0_pll_ctrl_in[7:0] = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_TMUX_SEL;
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DEBUG_CTRL = subsystem_clock_control_0_pll_ctrl_out[55:48];
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_DIV = subsystem_clock_control_0_pll_ctrl_out[104:88];
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_ENABLE = subsystem_clock_control_0_pll_ctrl_out[47:40];
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_LOOP_CTRL = subsystem_clock_control_0_pll_ctrl_out[87:56];
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_SPARE_CTRL = subsystem_clock_control_0_pll_ctrl_out[39:8];
    assign subsystem_clock_control_0_pll_ctrl_latched_to_clkpll_0_pll_ctrl_latched_TMUX_SEL = subsystem_clock_control_0_pll_ctrl_out[7:0];
    assign subsystem_clock_control_0_pll_ctrl_valid = subsystem_clock_control_0_pll_ctrl_to_pll_ctrl_VALID;
    assign subsystem_clock_control_0_pll_lock = clkpll_0_CLK_PLL_LOCK_to_subsystem_clock_control_0_pll_lock;
    assign subsystem_clock_control_0_pllclk = clkpll_0_pll_clk_to_subsystem_clock_control_0_pll_clk_clk;
    assign subsystem_clock_control_0_refclk = subsystem_clock_control_0_ref_clk_to_ref_clk_clk;
    assign subsystem_clock_control_0_refrstn = subsystem_clock_control_0_ref_rstn_to_ref_rstn_rst_n;
    assign subsystem_clock_control_0_rst_n_to_axi2apb_0_reset_n_rst_n = subsystem_clock_control_0_rstn_out;
    assign subsystem_clock_control_0_sel_cka = subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[0];
    assign subsystem_clock_control_0_subsys_clkena = subsystem_clock_control_0_clk_ctrl_to_clk_ctrl_CLK_CTRL[3];

    // IP-XACT VLNV: pulp-platform.org:peripheral.ip:apb_i2c:1.0
    apb_i2c #(
        .APB_ADDR_WIDTH      (12))
    apb_i2c_0(
        // Interface: apb_slave
        .PADDR               (apb_i2c_0_PADDR),
        .PENABLE             (apb_i2c_0_PENABLE),
        .PSEL                (apb_i2c_0_PSEL),
        .PWDATA              (apb_i2c_0_PWDATA),
        .PWRITE              (apb_i2c_0_PWRITE),
        .PRDATA              (apb_i2c_0_PRDATA),
        .PREADY              (apb_i2c_0_PREADY),
        .PSLVERR             (apb_i2c_0_PSLVERR),
        // Interface: clk
        .HCLK                (apb_i2c_0_HCLK),
        // Interface: i2c_master_slave
        .scl_pad_i           (apb_i2c_0_scl_pad_i),
        .sda_pad_i           (apb_i2c_0_sda_pad_i),
        .scl_pad_o           (apb_i2c_0_scl_pad_o),
        .scl_padoen_o        (apb_i2c_0_scl_padoen_o),
        .sda_pad_o           (apb_i2c_0_sda_pad_o),
        .sda_padoen_o        (apb_i2c_0_sda_padoen_o),
        // Interface: irq_master
        .interrupt_o         (apb_i2c_0_interrupt_o),
        // Interface: reset_n
        .HRESETn             (apb_i2c_0_HRESETn));

    // IP-XACT VLNV: pulp-platform.org:communication.converter:axi2apb:1.0
    axi2apb #(
        .AXI4_ADDRESS_WIDTH  (32),
        .AXI4_ID_WIDTH       (9),
        .AXI4_USER_WIDTH     (1),
        .APB_ADDR_WIDTH      (12))
    axi2apb_0(
        // Interface: apb_master
        .PRDATA              (axi2apb_0_PRDATA),
        .PREADY              (axi2apb_0_PREADY),
        .PSLVERR             (axi2apb_0_PSLVERR),
        .PADDR               (axi2apb_0_PADDR),
        .PENABLE             (axi2apb_0_PENABLE),
        .PSEL                (axi2apb_0_PSEL),
        .PWDATA              (axi2apb_0_PWDATA),
        .PWRITE              (axi2apb_0_PWRITE),
        // Interface: axi_slave
        .ARADDR_i            (axi2apb_0_ARADDR_i),
        .ARBURST_i           (axi2apb_0_ARBURST_i),
        .ARCACHE_i           (axi2apb_0_ARCACHE_i),
        .ARID_i              (axi2apb_0_ARID_i),
        .ARLEN_i             (axi2apb_0_ARLEN_i),
        .ARLOCK_i            (axi2apb_0_ARLOCK_i),
        .ARPROT_i            (axi2apb_0_ARPROT_i),
        .ARQOS_i             (axi2apb_0_ARQOS_i),
        .ARREGION_i          (axi2apb_0_ARREGION_i),
        .ARSIZE_i            (axi2apb_0_ARSIZE_i),
        .ARUSER_i            (axi2apb_0_ARUSER_i),
        .ARVALID_i           (axi2apb_0_ARVALID_i),
        .AWADDR_i            (axi2apb_0_AWADDR_i),
        .AWBURST_i           (axi2apb_0_AWBURST_i),
        .AWCACHE_i           (axi2apb_0_AWCACHE_i),
        .AWID_i              (axi2apb_0_AWID_i),
        .AWLEN_i             (axi2apb_0_AWLEN_i),
        .AWLOCK_i            (axi2apb_0_AWLOCK_i),
        .AWPROT_i            (axi2apb_0_AWPROT_i),
        .AWQOS_i             (axi2apb_0_AWQOS_i),
        .AWREGION_i          (axi2apb_0_AWREGION_i),
        .AWSIZE_i            (axi2apb_0_AWSIZE_i),
        .AWUSER_i            (axi2apb_0_AWUSER_i),
        .AWVALID_i           (axi2apb_0_AWVALID_i),
        .BREADY_i            (axi2apb_0_BREADY_i),
        .RREADY_i            (axi2apb_0_RREADY_i),
        .WDATA_i             (axi2apb_0_WDATA_i),
        .WLAST_i             (axi2apb_0_WLAST_i),
        .WSTRB_i             (axi2apb_0_WSTRB_i),
        .WUSER_i             (axi2apb_0_WUSER_i),
        .WVALID_i            (axi2apb_0_WVALID_i),
        .ARREADY_o           (axi2apb_0_ARREADY_o),
        .AWREADY_o           (axi2apb_0_AWREADY_o),
        .BID_o               (axi2apb_0_BID_o),
        .BRESP_o             (axi2apb_0_BRESP_o),
        .BUSER_o             (axi2apb_0_BUSER_o),
        .BVALID_o            (axi2apb_0_BVALID_o),
        .RDATA_o             (axi2apb_0_RDATA_o),
        .RID_o               (axi2apb_0_RID_o),
        .RLAST_o             (axi2apb_0_RLAST_o),
        .RRESP_o             (axi2apb_0_RRESP_o),
        .RUSER_o             (axi2apb_0_RUSER_o),
        .RVALID_o            (axi2apb_0_RVALID_o),
        .WREADY_o            (axi2apb_0_WREADY_o),
        // Interface: clk
        .ACLK                (axi2apb_0_ACLK),
        // Interface: reset_n
        .ARESETn             (axi2apb_0_ARESETn),
        // These ports are not in any interface
        .test_en_i           (1'b0));

    // IP-XACT VLNV: tuni.fi:subsystem.axi_cdc_split:axi_cdc_intf_dst:1.0
    axi_cdc_split_intf_dst #(
        .AXI_ID_WIDTH        (9),
        .AXI_ADDR_WIDTH      (32),
        .AXI_DATA_WIDTH      (32),
        .AXI_USER_WIDTH      (1),
        .LOG_DEPTH           (2))
    axi_cdc_intf_dst_0(
        // Interface: dst
        .ar_data_src2dst     (axi_cdc_intf_dst_0_ar_data_src2dst),
        .ar_wr_ptr_gray_src2dst(axi_cdc_intf_dst_0_ar_wr_ptr_gray_src2dst),
        .aw_data_src2dst     (axi_cdc_intf_dst_0_aw_data_src2dst),
        .aw_wr_ptr_gray_src2dst(axi_cdc_intf_dst_0_aw_wr_ptr_gray_src2dst),
        .b_rd_data_ptr_src2dst(axi_cdc_intf_dst_0_b_rd_data_ptr_src2dst),
        .b_rd_ptr_gray_src2dst(axi_cdc_intf_dst_0_b_rd_ptr_gray_src2dst),
        .r_rd_data_ptr_src2dst(axi_cdc_intf_dst_0_r_rd_data_ptr_src2dst),
        .r_rd_ptr_gray_src2dst(axi_cdc_intf_dst_0_r_rd_ptr_gray_src2dst),
        .w_data_src2dst      (axi_cdc_intf_dst_0_w_data_src2dst),
        .w_wr_ptr_gray_src2dst(axi_cdc_intf_dst_0_w_wr_ptr_gray_src2dst),
        .ar_rd_data_ptr_dst2src(axi_cdc_intf_dst_0_ar_rd_data_ptr_dst2src),
        .ar_rd_ptr_gray_dst2src(axi_cdc_intf_dst_0_ar_rd_ptr_gray_dst2src),
        .aw_rd_data_ptr_dst2src(axi_cdc_intf_dst_0_aw_rd_data_ptr_dst2src),
        .aw_rd_ptr_gray_dst2src(axi_cdc_intf_dst_0_aw_rd_ptr_gray_dst2src),
        .b_data_dst2src      (axi_cdc_intf_dst_0_b_data_dst2src),
        .b_wr_ptr_gray_dst2src(axi_cdc_intf_dst_0_b_wr_ptr_gray_dst2src),
        .r_data_dst2src      (axi_cdc_intf_dst_0_r_data_dst2src),
        .r_wr_ptr_gray_dst2src(axi_cdc_intf_dst_0_r_wr_ptr_gray_dst2src),
        .w_rd_data_ptr_dst2src(axi_cdc_intf_dst_0_w_rd_data_ptr_dst2src),
        .w_rd_ptr_gray_dst2src(axi_cdc_intf_dst_0_w_rd_ptr_gray_dst2src),
        // Interface: dst_clk
        .dst_clk_i           (axi_cdc_intf_dst_0_dst_clk_i),
        // Interface: dst_rstn
        .dst_rst_ni          (axi_cdc_intf_dst_0_dst_rst_ni),
        // Interface: icn_rstn
        .icn_rst_ni          (axi_cdc_intf_dst_0_icn_rst_ni),
        // Interface: src
        .ar_ready            (axi_cdc_intf_dst_0_ar_ready),
        .aw_ready            (axi_cdc_intf_dst_0_aw_ready),
        .b_id                (axi_cdc_intf_dst_0_b_id),
        .b_resp              (axi_cdc_intf_dst_0_b_resp),
        .b_user              (axi_cdc_intf_dst_0_b_user),
        .b_valid             (axi_cdc_intf_dst_0_b_valid),
        .r_data              (axi_cdc_intf_dst_0_r_data),
        .r_id                (axi_cdc_intf_dst_0_r_id),
        .r_last              (axi_cdc_intf_dst_0_r_last),
        .r_resp              (axi_cdc_intf_dst_0_r_resp),
        .r_user              (axi_cdc_intf_dst_0_r_user),
        .r_valid             (axi_cdc_intf_dst_0_r_valid),
        .w_ready             (axi_cdc_intf_dst_0_w_ready),
        .ar_addr             (axi_cdc_intf_dst_0_ar_addr),
        .ar_burst            (axi_cdc_intf_dst_0_ar_burst),
        .ar_cache            (axi_cdc_intf_dst_0_ar_cache),
        .ar_id               (axi_cdc_intf_dst_0_ar_id),
        .ar_len              (axi_cdc_intf_dst_0_ar_len),
        .ar_lock             (axi_cdc_intf_dst_0_ar_lock),
        .ar_prot             (axi_cdc_intf_dst_0_ar_prot),
        .ar_qos              (axi_cdc_intf_dst_0_ar_qos),
        .ar_region           (axi_cdc_intf_dst_0_ar_region),
        .ar_size             (axi_cdc_intf_dst_0_ar_size),
        .ar_user             (axi_cdc_intf_dst_0_ar_user),
        .ar_valid            (axi_cdc_intf_dst_0_ar_valid),
        .aw_addr             (axi_cdc_intf_dst_0_aw_addr),
        .aw_atop             (axi_cdc_intf_dst_0_aw_atop),
        .aw_burst            (axi_cdc_intf_dst_0_aw_burst),
        .aw_cache            (axi_cdc_intf_dst_0_aw_cache),
        .aw_id               (axi_cdc_intf_dst_0_aw_id),
        .aw_len              (axi_cdc_intf_dst_0_aw_len),
        .aw_lock             (axi_cdc_intf_dst_0_aw_lock),
        .aw_prot             (axi_cdc_intf_dst_0_aw_prot),
        .aw_qos              (axi_cdc_intf_dst_0_aw_qos),
        .aw_region           (axi_cdc_intf_dst_0_aw_region),
        .aw_size             (axi_cdc_intf_dst_0_aw_size),
        .aw_user             (axi_cdc_intf_dst_0_aw_user),
        .aw_valid            (axi_cdc_intf_dst_0_aw_valid),
        .b_ready             (axi_cdc_intf_dst_0_b_ready),
        .r_ready             (axi_cdc_intf_dst_0_r_ready),
        .w_data              (axi_cdc_intf_dst_0_w_data),
        .w_last              (axi_cdc_intf_dst_0_w_last),
        .w_strb              (axi_cdc_intf_dst_0_w_strb),
        .w_user              (axi_cdc_intf_dst_0_w_user),
        .w_valid             (axi_cdc_intf_dst_0_w_valid));

    // IP-XACT VLNV: tuni.fi:subsystem.axi_cdc_split:axi_cdc_intf_src:1.0
    axi_cdc_split_intf_src #(
        .AXI_ID_WIDTH        (9),
        .AXI_ADDR_WIDTH      (32),
        .AXI_DATA_WIDTH      (32),
        .AXI_USER_WIDTH      (1),
        .LOG_DEPTH           (2))
    axi_cdc_intf_src_0(
        // Interface: dst
        .ar_addr             (axi_cdc_intf_src_0_ar_addr),
        .ar_burst            (axi_cdc_intf_src_0_ar_burst),
        .ar_cache            (axi_cdc_intf_src_0_ar_cache),
        .ar_id               (axi_cdc_intf_src_0_ar_id),
        .ar_len              (axi_cdc_intf_src_0_ar_len),
        .ar_lock             (axi_cdc_intf_src_0_ar_lock),
        .ar_prot             (axi_cdc_intf_src_0_ar_prot),
        .ar_qos              (axi_cdc_intf_src_0_ar_qos),
        .ar_region           (axi_cdc_intf_src_0_ar_region),
        .ar_size             (axi_cdc_intf_src_0_ar_size),
        .ar_user             (axi_cdc_intf_src_0_ar_user),
        .ar_valid            (axi_cdc_intf_src_0_ar_valid),
        .aw_addr             (axi_cdc_intf_src_0_aw_addr),
        .aw_atop             (axi_cdc_intf_src_0_aw_atop),
        .aw_burst            (axi_cdc_intf_src_0_aw_burst),
        .aw_cache            (axi_cdc_intf_src_0_aw_cache),
        .aw_id               (axi_cdc_intf_src_0_aw_id),
        .aw_len              (axi_cdc_intf_src_0_aw_len),
        .aw_lock             (axi_cdc_intf_src_0_aw_lock),
        .aw_prot             (axi_cdc_intf_src_0_aw_prot),
        .aw_qos              (axi_cdc_intf_src_0_aw_qos),
        .aw_region           (axi_cdc_intf_src_0_aw_region),
        .aw_size             (axi_cdc_intf_src_0_aw_size),
        .aw_user             (axi_cdc_intf_src_0_aw_user),
        .aw_valid            (axi_cdc_intf_src_0_aw_valid),
        .b_ready             (axi_cdc_intf_src_0_b_ready),
        .r_ready             (axi_cdc_intf_src_0_r_ready),
        .w_data              (axi_cdc_intf_src_0_w_data),
        .w_last              (axi_cdc_intf_src_0_w_last),
        .w_strb              (axi_cdc_intf_src_0_w_strb),
        .w_user              (axi_cdc_intf_src_0_w_user),
        .w_valid             (axi_cdc_intf_src_0_w_valid),
        .ar_ready            (axi_cdc_intf_src_0_ar_ready),
        .aw_ready            (axi_cdc_intf_src_0_aw_ready),
        .b_id                (axi_cdc_intf_src_0_b_id),
        .b_resp              (axi_cdc_intf_src_0_b_resp),
        .b_user              (axi_cdc_intf_src_0_b_user),
        .b_valid             (axi_cdc_intf_src_0_b_valid),
        .r_data              (axi_cdc_intf_src_0_r_data),
        .r_id                (axi_cdc_intf_src_0_r_id),
        .r_last              (axi_cdc_intf_src_0_r_last),
        .r_resp              (axi_cdc_intf_src_0_r_resp),
        .r_user              (axi_cdc_intf_src_0_r_user),
        .r_valid             (axi_cdc_intf_src_0_r_valid),
        .w_ready             (axi_cdc_intf_src_0_w_ready),
        // Interface: icn_rstn
        .icn_rst_ni          (axi_cdc_intf_src_0_icn_rst_ni),
        // Interface: src
        .ar_rd_data_ptr_dst2src(axi_cdc_intf_src_0_ar_rd_data_ptr_dst2src),
        .ar_rd_ptr_gray_dst2src(axi_cdc_intf_src_0_ar_rd_ptr_gray_dst2src),
        .aw_rd_data_ptr_dst2src(axi_cdc_intf_src_0_aw_rd_data_ptr_dst2src),
        .aw_rd_ptr_gray_dst2src(axi_cdc_intf_src_0_aw_rd_ptr_gray_dst2src),
        .b_data_dst2src      (axi_cdc_intf_src_0_b_data_dst2src),
        .b_wr_ptr_gray_dst2src(axi_cdc_intf_src_0_b_wr_ptr_gray_dst2src),
        .r_data_dst2src      (axi_cdc_intf_src_0_r_data_dst2src),
        .r_wr_ptr_gray_dst2src(axi_cdc_intf_src_0_r_wr_ptr_gray_dst2src),
        .w_rd_data_ptr_dst2src(axi_cdc_intf_src_0_w_rd_data_ptr_dst2src),
        .w_rd_ptr_gray_dst2src(axi_cdc_intf_src_0_w_rd_ptr_gray_dst2src),
        .ar_data_src2dst     (axi_cdc_intf_src_0_ar_data_src2dst),
        .ar_wr_ptr_gray_src2dst(axi_cdc_intf_src_0_ar_wr_ptr_gray_src2dst),
        .aw_data_src2dst     (axi_cdc_intf_src_0_aw_data_src2dst),
        .aw_wr_ptr_gray_src2dst(axi_cdc_intf_src_0_aw_wr_ptr_gray_src2dst),
        .b_rd_data_ptr_src2dst(axi_cdc_intf_src_0_b_rd_data_ptr_src2dst),
        .b_rd_ptr_gray_src2dst(axi_cdc_intf_src_0_b_rd_ptr_gray_src2dst),
        .r_rd_data_ptr_src2dst(axi_cdc_intf_src_0_r_rd_data_ptr_src2dst),
        .r_rd_ptr_gray_src2dst(axi_cdc_intf_src_0_r_rd_ptr_gray_src2dst),
        .w_data_src2dst      (axi_cdc_intf_src_0_w_data_src2dst),
        .w_wr_ptr_gray_src2dst(axi_cdc_intf_src_0_w_wr_ptr_gray_src2dst),
        // Interface: src_clk
        .src_clk_i           (axi_cdc_intf_src_0_src_clk_i),
        // Interface: src_rstn
        .src_rst_ni          (axi_cdc_intf_src_0_src_rst_ni));

    // IP-XACT VLNV: tuni.fi:flat:camera_processor:1.0
    camera_processor_wrapper #(
        .AXIM_ID_WIDTH       (9),
        .AXIM_ADDR_WIDTH     (32),
        .AXIM_DATA_WIDTH     (32),
        .AXIM_USER_WIDTH     (1),
        .AXIS_ID_WIDTH       (9),
        .AXIS_ADDR_WIDTH     (32),
        .AXIS_DATA_WIDTH     (32),
        .AXIS_USER_WIDTH     (1))
    camera_processor_0(
        // Interface: AXI_CLK
        .axi_clk_i           (camera_processor_0_axi_clk_i),
        // Interface: AXI_MASTER
        .m_axi_csi_arready_i (camera_processor_0_m_axi_csi_arready_i),
        .m_axi_csi_awready_i (camera_processor_0_m_axi_csi_awready_i),
        .m_axi_csi_bid_i     (camera_processor_0_m_axi_csi_bid_i),
        .m_axi_csi_bresp_i   (camera_processor_0_m_axi_csi_bresp_i),
        .m_axi_csi_buser_i   (camera_processor_0_m_axi_csi_buser_i),
        .m_axi_csi_bvalid_i  (camera_processor_0_m_axi_csi_bvalid_i),
        .m_axi_csi_rdata_i   (camera_processor_0_m_axi_csi_rdata_i),
        .m_axi_csi_rid_i     (camera_processor_0_m_axi_csi_rid_i),
        .m_axi_csi_rlast_i   (camera_processor_0_m_axi_csi_rlast_i),
        .m_axi_csi_rresp_i   (camera_processor_0_m_axi_csi_rresp_i),
        .m_axi_csi_ruser_i   (camera_processor_0_m_axi_csi_ruser_i),
        .m_axi_csi_rvalid_i  (camera_processor_0_m_axi_csi_rvalid_i),
        .m_axi_csi_wready_i  (camera_processor_0_m_axi_csi_wready_i),
        .m_axi_csi_araddr_o  (camera_processor_0_m_axi_csi_araddr_o),
        .m_axi_csi_arburst_o (camera_processor_0_m_axi_csi_arburst_o),
        .m_axi_csi_arcache_o (camera_processor_0_m_axi_csi_arcache_o),
        .m_axi_csi_arid_o    (camera_processor_0_m_axi_csi_arid_o),
        .m_axi_csi_arlen_o   (camera_processor_0_m_axi_csi_arlen_o),
        .m_axi_csi_arlock_o  (camera_processor_0_m_axi_csi_arlock_o),
        .m_axi_csi_arprot_o  (camera_processor_0_m_axi_csi_arprot_o),
        .m_axi_csi_arqos_o   (camera_processor_0_m_axi_csi_arqos_o),
        .m_axi_csi_arregion_o(camera_processor_0_m_axi_csi_arregion_o),
        .m_axi_csi_arsize_o  (camera_processor_0_m_axi_csi_arsize_o),
        .m_axi_csi_aruser_o  (camera_processor_0_m_axi_csi_aruser_o),
        .m_axi_csi_arvalid_o (camera_processor_0_m_axi_csi_arvalid_o),
        .m_axi_csi_awaddr_o  (camera_processor_0_m_axi_csi_awaddr_o),
        .m_axi_csi_awatop_o  (camera_processor_0_m_axi_csi_awatop_o),
        .m_axi_csi_awburst_o (camera_processor_0_m_axi_csi_awburst_o),
        .m_axi_csi_awcache_o (camera_processor_0_m_axi_csi_awcache_o),
        .m_axi_csi_awid_o    (camera_processor_0_m_axi_csi_awid_o),
        .m_axi_csi_awlen_o   (camera_processor_0_m_axi_csi_awlen_o),
        .m_axi_csi_awlock_o  (camera_processor_0_m_axi_csi_awlock_o),
        .m_axi_csi_awprot_o  (camera_processor_0_m_axi_csi_awprot_o),
        .m_axi_csi_awqos_o   (camera_processor_0_m_axi_csi_awqos_o),
        .m_axi_csi_awregion_o(camera_processor_0_m_axi_csi_awregion_o),
        .m_axi_csi_awsize_o  (camera_processor_0_m_axi_csi_awsize_o),
        .m_axi_csi_awuser_o  (camera_processor_0_m_axi_csi_awuser_o),
        .m_axi_csi_awvalid_o (camera_processor_0_m_axi_csi_awvalid_o),
        .m_axi_csi_bready_o  (camera_processor_0_m_axi_csi_bready_o),
        .m_axi_csi_rready_o  (camera_processor_0_m_axi_csi_rready_o),
        .m_axi_csi_wdata_o   (camera_processor_0_m_axi_csi_wdata_o),
        .m_axi_csi_wlast_o   (camera_processor_0_m_axi_csi_wlast_o),
        .m_axi_csi_wstrb_o   (camera_processor_0_m_axi_csi_wstrb_o),
        .m_axi_csi_wuser_o   (camera_processor_0_m_axi_csi_wuser_o),
        .m_axi_csi_wvalid_o  (camera_processor_0_m_axi_csi_wvalid_o),
        // Interface: AXI_RESET_N
        .axi_reset_n_i       (camera_processor_0_axi_reset_n_i),
        // Interface: AXI_SLAVE
        .s_axi_csi_araddr_i  (camera_processor_0_s_axi_csi_araddr_i),
        .s_axi_csi_arburst_i (camera_processor_0_s_axi_csi_arburst_i),
        .s_axi_csi_arcache_i (camera_processor_0_s_axi_csi_arcache_i),
        .s_axi_csi_arid_i    (camera_processor_0_s_axi_csi_arid_i),
        .s_axi_csi_arlen_i   (camera_processor_0_s_axi_csi_arlen_i),
        .s_axi_csi_arlock_i  (camera_processor_0_s_axi_csi_arlock_i),
        .s_axi_csi_arprot_i  (camera_processor_0_s_axi_csi_arprot_i),
        .s_axi_csi_arqos_i   (camera_processor_0_s_axi_csi_arqos_i),
        .s_axi_csi_arregion_i(camera_processor_0_s_axi_csi_arregion_i),
        .s_axi_csi_arsize_i  (camera_processor_0_s_axi_csi_arsize_i),
        .s_axi_csi_aruser_i  (camera_processor_0_s_axi_csi_aruser_i),
        .s_axi_csi_arvalid_i (camera_processor_0_s_axi_csi_arvalid_i),
        .s_axi_csi_awaddr_i  (camera_processor_0_s_axi_csi_awaddr_i),
        .s_axi_csi_awatop_i  (camera_processor_0_s_axi_csi_awatop_i),
        .s_axi_csi_awburst_i (camera_processor_0_s_axi_csi_awburst_i),
        .s_axi_csi_awcache_i (camera_processor_0_s_axi_csi_awcache_i),
        .s_axi_csi_awid_i    (camera_processor_0_s_axi_csi_awid_i),
        .s_axi_csi_awlen_i   (camera_processor_0_s_axi_csi_awlen_i),
        .s_axi_csi_awlock_i  (camera_processor_0_s_axi_csi_awlock_i),
        .s_axi_csi_awprot_i  (camera_processor_0_s_axi_csi_awprot_i),
        .s_axi_csi_awqos_i   (camera_processor_0_s_axi_csi_awqos_i),
        .s_axi_csi_awregion_i(camera_processor_0_s_axi_csi_awregion_i),
        .s_axi_csi_awsize_i  (camera_processor_0_s_axi_csi_awsize_i),
        .s_axi_csi_awuser_i  (camera_processor_0_s_axi_csi_awuser_i),
        .s_axi_csi_awvalid_i (camera_processor_0_s_axi_csi_awvalid_i),
        .s_axi_csi_bready_i  (camera_processor_0_s_axi_csi_bready_i),
        .s_axi_csi_rready_i  (camera_processor_0_s_axi_csi_rready_i),
        .s_axi_csi_wdata_i   (camera_processor_0_s_axi_csi_wdata_i),
        .s_axi_csi_wlast_i   (camera_processor_0_s_axi_csi_wlast_i),
        .s_axi_csi_wstrb_i   (camera_processor_0_s_axi_csi_wstrb_i),
        .s_axi_csi_wuser_i   (camera_processor_0_s_axi_csi_wuser_i),
        .s_axi_csi_wvalid_i  (camera_processor_0_s_axi_csi_wvalid_i),
        .s_axi_csi_arready_o (camera_processor_0_s_axi_csi_arready_o),
        .s_axi_csi_awready_o (camera_processor_0_s_axi_csi_awready_o),
        .s_axi_csi_bid_o     (camera_processor_0_s_axi_csi_bid_o),
        .s_axi_csi_bresp_o   (camera_processor_0_s_axi_csi_bresp_o),
        .s_axi_csi_buser_o   (camera_processor_0_s_axi_csi_buser_o),
        .s_axi_csi_bvalid_o  (camera_processor_0_s_axi_csi_bvalid_o),
        .s_axi_csi_rdata_o   (camera_processor_0_s_axi_csi_rdata_o),
        .s_axi_csi_rid_o     (camera_processor_0_s_axi_csi_rid_o),
        .s_axi_csi_rlast_o   (camera_processor_0_s_axi_csi_rlast_o),
        .s_axi_csi_rresp_o   (camera_processor_0_s_axi_csi_rresp_o),
        .s_axi_csi_ruser_o   (camera_processor_0_s_axi_csi_ruser_o),
        .s_axi_csi_rvalid_o  (camera_processor_0_s_axi_csi_rvalid_o),
        .s_axi_csi_wready_o  (camera_processor_0_s_axi_csi_wready_o),
        // Interface: CLK
        .pixel_clk_i         (camera_processor_0_pixel_clk_i),
        // Interface: IRQ
        .frame_wr_done_intr_o(camera_processor_0_frame_wr_done_intr_o),
        // Interface: PPI_SLAVE
        .rx_byte_clk_hs      (camera_processor_0_rx_byte_clk_hs),
        .rx_data_hs_0        (camera_processor_0_rx_data_hs_0),
        .rx_data_hs_1        (camera_processor_0_rx_data_hs_1),
        .rx_data_hs_2        (camera_processor_0_rx_data_hs_2),
        .rx_data_hs_3        (camera_processor_0_rx_data_hs_3),
        .rx_valid_hs_0       (camera_processor_0_rx_valid_hs_0),
        .rx_valid_hs_1       (camera_processor_0_rx_valid_hs_1),
        .rx_valid_hs_2       (camera_processor_0_rx_valid_hs_2),
        .rx_valid_hs_3       (camera_processor_0_rx_valid_hs_3),
        // Interface: RESET_N
        .reset_n_i           (camera_processor_0_reset_n_i));

    // IP-XACT VLNV: corehw.com:subsystem.clock:clkpll:1.0
    CLKPLL clkpll_0(
        // Interface: pll_clk
        .CLK_PLL_OUT         (clkpll_0_CLK_PLL_OUT),
        // Interface: pll_ctrl_latched
        .DEBUG_CTRL          (clkpll_0_DEBUG_CTRL),
        .ENABLE              (clkpll_0_ENABLE),
        .LOOP_CTRL           (clkpll_0_LOOP_CTRL),
        .M_DIV               (clkpll_0_M_DIV),
        .N_DIV               (clkpll_0_N_DIV),
        .R_DIV               (clkpll_0_R_DIV),
        .SPARE_CTRL          (clkpll_0_SPARE_CTRL),
        .TMUX_1_SEL          (clkpll_0_TMUX_1_SEL),
        .TMUX_2_SEL          (clkpll_0_TMUX_2_SEL),
        // Interface: pll_status
        .STATUS1             (clkpll_0_STATUS1),
        .STATUS2             (clkpll_0_STATUS2),
        // Interface: ref_clk
        .CLK_REF             (clkpll_0_CLK_REF),
        // These ports are not in any interface
        .SCAN_EN             (1'b0),
        .SCAN_IN             (1'b0),
        .SCAN_MODE           (2'h0),
        .CLK_PLL_LOCK        (clkpll_0_CLK_PLL_LOCK),
        .CLK_REF_BUF_OUT     (),
        .SCAN_OUT            (),
        .TOUT1               (),
        .TOUT2               ());

    // IP-XACT VLNV: tuni.fi:flat:d_phy_top:1.0
    d_phy_top d_phy_top_0(
        // Interface: DPHY
        .clk_lane_n          (clk_lane_n),
        .clk_lane_p          (clk_lane_p),
        .data_lane_0_n       (data_lane_0_n),
        .data_lane_0_p       (data_lane_0_p),
        .data_lane_1_n       (data_lane_1_n),
        .data_lane_1_p       (data_lane_1_p),
        .data_lane_2_n       (data_lane_2_n),
        .data_lane_2_p       (data_lane_2_p),
        .data_lane_3_n       (data_lane_3_n),
        .data_lane_3_p       (data_lane_3_p),
        // Interface: PPI_MASTER
        .rx_byte_clk_hs      (d_phy_top_0_rx_byte_clk_hs),
        .rx_data_hs_0        (d_phy_top_0_rx_data_hs_0),
        .rx_data_hs_1        (d_phy_top_0_rx_data_hs_1),
        .rx_data_hs_2        (d_phy_top_0_rx_data_hs_2),
        .rx_data_hs_3        (d_phy_top_0_rx_data_hs_3),
        .rx_valid_hs_0       (d_phy_top_0_rx_valid_hs_0),
        .rx_valid_hs_1       (d_phy_top_0_rx_valid_hs_1),
        .rx_valid_hs_2       (d_phy_top_0_rx_valid_hs_2),
        .rx_valid_hs_3       (d_phy_top_0_rx_valid_hs_3),
        // Interface: clk
        .clk_i               (d_phy_top_0_clk_i),
        // Interface: reset_n
        .reset_n_i           (d_phy_top_0_reset_n_i));

    // IP-XACT VLNV: tuni.fi:flat:periph_axi_demux_1_to_2_wrapper:1.0
    periph_axi_demux_1_to_2_wrapper #(
        .AXI_ID_WIDTH        (9),
        .AXI_ADDR_WIDTH      (32),
        .AXI_DATA_WIDTH      (32),
        .AXI_USER_WIDTH      (1))
    periph_axi_demux_1_to_2_wrapper_0(
        // Interface: clk
        .clk                 (periph_axi_demux_1_to_2_wrapper_0_clk),
        // Interface: master0
        .master_0_ar_ready   (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_ready),
        .master_0_aw_ready   (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_ready),
        .master_0_b_id       (periph_axi_demux_1_to_2_wrapper_0_master_0_b_id),
        .master_0_b_resp     (periph_axi_demux_1_to_2_wrapper_0_master_0_b_resp),
        .master_0_b_user     (periph_axi_demux_1_to_2_wrapper_0_master_0_b_user),
        .master_0_b_valid    (periph_axi_demux_1_to_2_wrapper_0_master_0_b_valid),
        .master_0_r_data     (periph_axi_demux_1_to_2_wrapper_0_master_0_r_data),
        .master_0_r_id       (periph_axi_demux_1_to_2_wrapper_0_master_0_r_id),
        .master_0_r_last     (periph_axi_demux_1_to_2_wrapper_0_master_0_r_last),
        .master_0_r_resp     (periph_axi_demux_1_to_2_wrapper_0_master_0_r_resp),
        .master_0_r_user     (periph_axi_demux_1_to_2_wrapper_0_master_0_r_user),
        .master_0_r_valid    (periph_axi_demux_1_to_2_wrapper_0_master_0_r_valid),
        .master_0_w_ready    (periph_axi_demux_1_to_2_wrapper_0_master_0_w_ready),
        .master_0_ar_addr    (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_addr),
        .master_0_ar_burst   (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_burst),
        .master_0_ar_cache   (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_cache),
        .master_0_ar_id      (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_id),
        .master_0_ar_len     (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_len),
        .master_0_ar_lock    (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_lock),
        .master_0_ar_prot    (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_prot),
        .master_0_ar_qos     (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_qos),
        .master_0_ar_region  (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_region),
        .master_0_ar_size    (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_size),
        .master_0_ar_user    (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_user),
        .master_0_ar_valid   (periph_axi_demux_1_to_2_wrapper_0_master_0_ar_valid),
        .master_0_aw_addr    (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_addr),
        .master_0_aw_atop    (),
        .master_0_aw_burst   (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_burst),
        .master_0_aw_cache   (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_cache),
        .master_0_aw_id      (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_id),
        .master_0_aw_len     (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_len),
        .master_0_aw_lock    (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_lock),
        .master_0_aw_prot    (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_prot),
        .master_0_aw_qos     (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_qos),
        .master_0_aw_region  (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_region),
        .master_0_aw_size    (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_size),
        .master_0_aw_user    (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_user),
        .master_0_aw_valid   (periph_axi_demux_1_to_2_wrapper_0_master_0_aw_valid),
        .master_0_b_ready    (periph_axi_demux_1_to_2_wrapper_0_master_0_b_ready),
        .master_0_r_ready    (periph_axi_demux_1_to_2_wrapper_0_master_0_r_ready),
        .master_0_w_data     (periph_axi_demux_1_to_2_wrapper_0_master_0_w_data),
        .master_0_w_last     (periph_axi_demux_1_to_2_wrapper_0_master_0_w_last),
        .master_0_w_strb     (periph_axi_demux_1_to_2_wrapper_0_master_0_w_strb),
        .master_0_w_user     (periph_axi_demux_1_to_2_wrapper_0_master_0_w_user),
        .master_0_w_valid    (periph_axi_demux_1_to_2_wrapper_0_master_0_w_valid),
        // Interface: master1
        .master_1_ar_ready   (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_ready),
        .master_1_aw_ready   (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_ready),
        .master_1_b_id       (periph_axi_demux_1_to_2_wrapper_0_master_1_b_id),
        .master_1_b_resp     (periph_axi_demux_1_to_2_wrapper_0_master_1_b_resp),
        .master_1_b_user     (periph_axi_demux_1_to_2_wrapper_0_master_1_b_user),
        .master_1_b_valid    (periph_axi_demux_1_to_2_wrapper_0_master_1_b_valid),
        .master_1_r_data     (periph_axi_demux_1_to_2_wrapper_0_master_1_r_data),
        .master_1_r_id       (periph_axi_demux_1_to_2_wrapper_0_master_1_r_id),
        .master_1_r_last     (periph_axi_demux_1_to_2_wrapper_0_master_1_r_last),
        .master_1_r_resp     (periph_axi_demux_1_to_2_wrapper_0_master_1_r_resp),
        .master_1_r_user     (periph_axi_demux_1_to_2_wrapper_0_master_1_r_user),
        .master_1_r_valid    (periph_axi_demux_1_to_2_wrapper_0_master_1_r_valid),
        .master_1_w_ready    (periph_axi_demux_1_to_2_wrapper_0_master_1_w_ready),
        .master_1_ar_addr    (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_addr),
        .master_1_ar_burst   (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_burst),
        .master_1_ar_cache   (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_cache),
        .master_1_ar_id      (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_id),
        .master_1_ar_len     (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_len),
        .master_1_ar_lock    (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_lock),
        .master_1_ar_prot    (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_prot),
        .master_1_ar_qos     (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_qos),
        .master_1_ar_region  (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_region),
        .master_1_ar_size    (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_size),
        .master_1_ar_user    (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_user),
        .master_1_ar_valid   (periph_axi_demux_1_to_2_wrapper_0_master_1_ar_valid),
        .master_1_aw_addr    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_addr),
        .master_1_aw_atop    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_atop),
        .master_1_aw_burst   (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_burst),
        .master_1_aw_cache   (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_cache),
        .master_1_aw_id      (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_id),
        .master_1_aw_len     (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_len),
        .master_1_aw_lock    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_lock),
        .master_1_aw_prot    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_prot),
        .master_1_aw_qos     (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_qos),
        .master_1_aw_region  (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_region),
        .master_1_aw_size    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_size),
        .master_1_aw_user    (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_user),
        .master_1_aw_valid   (periph_axi_demux_1_to_2_wrapper_0_master_1_aw_valid),
        .master_1_b_ready    (periph_axi_demux_1_to_2_wrapper_0_master_1_b_ready),
        .master_1_r_ready    (periph_axi_demux_1_to_2_wrapper_0_master_1_r_ready),
        .master_1_w_data     (periph_axi_demux_1_to_2_wrapper_0_master_1_w_data),
        .master_1_w_last     (periph_axi_demux_1_to_2_wrapper_0_master_1_w_last),
        .master_1_w_strb     (periph_axi_demux_1_to_2_wrapper_0_master_1_w_strb),
        .master_1_w_user     (periph_axi_demux_1_to_2_wrapper_0_master_1_w_user),
        .master_1_w_valid    (periph_axi_demux_1_to_2_wrapper_0_master_1_w_valid),
        // Interface: reset
        .rst_n               (periph_axi_demux_1_to_2_wrapper_0_rst_n),
        // Interface: slave
        .slave_ar_addr       (periph_axi_demux_1_to_2_wrapper_0_slave_ar_addr),
        .slave_ar_burst      (periph_axi_demux_1_to_2_wrapper_0_slave_ar_burst),
        .slave_ar_cache      (periph_axi_demux_1_to_2_wrapper_0_slave_ar_cache),
        .slave_ar_id         (periph_axi_demux_1_to_2_wrapper_0_slave_ar_id),
        .slave_ar_len        (periph_axi_demux_1_to_2_wrapper_0_slave_ar_len),
        .slave_ar_lock       (periph_axi_demux_1_to_2_wrapper_0_slave_ar_lock),
        .slave_ar_prot       (periph_axi_demux_1_to_2_wrapper_0_slave_ar_prot),
        .slave_ar_qos        (periph_axi_demux_1_to_2_wrapper_0_slave_ar_qos),
        .slave_ar_region     (periph_axi_demux_1_to_2_wrapper_0_slave_ar_region),
        .slave_ar_size       (periph_axi_demux_1_to_2_wrapper_0_slave_ar_size),
        .slave_ar_user       (periph_axi_demux_1_to_2_wrapper_0_slave_ar_user),
        .slave_ar_valid      (periph_axi_demux_1_to_2_wrapper_0_slave_ar_valid),
        .slave_aw_addr       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_addr),
        .slave_aw_atop       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_atop),
        .slave_aw_burst      (periph_axi_demux_1_to_2_wrapper_0_slave_aw_burst),
        .slave_aw_cache      (periph_axi_demux_1_to_2_wrapper_0_slave_aw_cache),
        .slave_aw_id         (periph_axi_demux_1_to_2_wrapper_0_slave_aw_id),
        .slave_aw_len        (periph_axi_demux_1_to_2_wrapper_0_slave_aw_len),
        .slave_aw_lock       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_lock),
        .slave_aw_prot       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_prot),
        .slave_aw_qos        (periph_axi_demux_1_to_2_wrapper_0_slave_aw_qos),
        .slave_aw_region     (periph_axi_demux_1_to_2_wrapper_0_slave_aw_region),
        .slave_aw_size       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_size),
        .slave_aw_user       (periph_axi_demux_1_to_2_wrapper_0_slave_aw_user),
        .slave_aw_valid      (periph_axi_demux_1_to_2_wrapper_0_slave_aw_valid),
        .slave_b_ready       (periph_axi_demux_1_to_2_wrapper_0_slave_b_ready),
        .slave_r_ready       (periph_axi_demux_1_to_2_wrapper_0_slave_r_ready),
        .slave_w_data        (periph_axi_demux_1_to_2_wrapper_0_slave_w_data),
        .slave_w_last        (periph_axi_demux_1_to_2_wrapper_0_slave_w_last),
        .slave_w_strb        (periph_axi_demux_1_to_2_wrapper_0_slave_w_strb),
        .slave_w_user        (periph_axi_demux_1_to_2_wrapper_0_slave_w_user),
        .slave_w_valid       (periph_axi_demux_1_to_2_wrapper_0_slave_w_valid),
        .slave_ar_ready      (periph_axi_demux_1_to_2_wrapper_0_slave_ar_ready),
        .slave_aw_ready      (periph_axi_demux_1_to_2_wrapper_0_slave_aw_ready),
        .slave_b_id          (periph_axi_demux_1_to_2_wrapper_0_slave_b_id),
        .slave_b_resp        (periph_axi_demux_1_to_2_wrapper_0_slave_b_resp),
        .slave_b_user        (periph_axi_demux_1_to_2_wrapper_0_slave_b_user),
        .slave_b_valid       (periph_axi_demux_1_to_2_wrapper_0_slave_b_valid),
        .slave_r_data        (periph_axi_demux_1_to_2_wrapper_0_slave_r_data),
        .slave_r_id          (periph_axi_demux_1_to_2_wrapper_0_slave_r_id),
        .slave_r_last        (periph_axi_demux_1_to_2_wrapper_0_slave_r_last),
        .slave_r_resp        (periph_axi_demux_1_to_2_wrapper_0_slave_r_resp),
        .slave_r_user        (periph_axi_demux_1_to_2_wrapper_0_slave_r_user),
        .slave_r_valid       (periph_axi_demux_1_to_2_wrapper_0_slave_r_valid),
        .slave_w_ready       (periph_axi_demux_1_to_2_wrapper_0_slave_w_ready));

    // IP-XACT VLNV: tuni.fi:subsystem.clock:subsystem_clock_control:1.0
    subsystem_clock_control #(
        .PLL_CTRL_WIDTH      (105),
        .CLK_CTRL_WIDTH      (8))
    subsystem_clock_control_0(
        // Interface: clk
        .clk_out             (subsystem_clock_control_0_clk_out),
        // Interface: clk_ctrl
        .force_cka           (subsystem_clock_control_0_force_cka),
        .force_ckb           (subsystem_clock_control_0_force_ckb),
        .sel_cka             (subsystem_clock_control_0_sel_cka),
        .subsys_clkena       (subsystem_clock_control_0_subsys_clkena),
        // Interface: pll_clk
        .pllclk              (subsystem_clock_control_0_pllclk),
        // Interface: pll_ctrl
        .pll_ctrl_in         (subsystem_clock_control_0_pll_ctrl_in),
        .pll_ctrl_valid      (subsystem_clock_control_0_pll_ctrl_valid),
        // Interface: pll_ctrl_latched
        .pll_ctrl_out        (subsystem_clock_control_0_pll_ctrl_out),
        // Interface: ref_clk
        .refclk              (subsystem_clock_control_0_refclk),
        // Interface: ref_rstn
        .refrstn             (subsystem_clock_control_0_refrstn),
        // Interface: rst_n
        .rstn_out            (subsystem_clock_control_0_rstn_out),
        // These ports are not in any interface
        .pll_lock            (subsystem_clock_control_0_pll_lock));


endmodule
