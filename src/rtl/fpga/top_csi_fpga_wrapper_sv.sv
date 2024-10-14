module top_csi_fpga_wrapper_sv #(
    localparam AXIM_ID_WIDTH     = 1,
    localparam AXIM_ADDR_WIDTH   = 32,
    localparam AXIM_DATA_WIDTH   = 32,
    localparam AXIM_USER_WIDTH   = 1,
    localparam AXIS_ID_WIDTH     = 1,
    localparam AXIS_ADDR_WIDTH   = 32,
    localparam AXIS_DATA_WIDTH   = 32,
    localparam AXIS_USER_WIDTH   = 1
)(
    // clocks and reset interface
input logic                             reset_n_i,
input logic                             pixel_clk_i,
input logic                             axi_reset_n_i,
input logic                             axi_clk_i,
// AXI Slave Register Interface
input           [AXIS_ADDR_WIDTH-1:0]   s_axi_lite_awaddr_i,
input                                   s_axi_lite_awvalid_i,
output logic                            s_axi_lite_awready_o,

input           [AXIS_DATA_WIDTH-1:0]   s_axi_lite_wdata_i,
input           [AXIS_DATA_WIDTH/8-1:0] s_axi_lite_wstrb_i,
input                                   s_axi_lite_wvalid_i,
output logic                            s_axi_lite_wready_o,

output logic    [1:0]                   s_axi_lite_bresp_o,
output logic                            s_axi_lite_bvalid_o,
input                                   s_axi_lite_bready_i,

input           [AXIS_ADDR_WIDTH-1:0]    s_axi_lite_araddr_i,
input                                   s_axi_lite_arvalid_i,
output  logic                           s_axi_lite_arready_o,

output logic    [AXIS_DATA_WIDTH-1:0]    s_axi_lite_rdata_o,
output logic    [1:0]                   s_axi_lite_rresp_o,
output logic                            s_axi_lite_rvalid_o,
input                                   s_axi_lite_rready_i,

// AXI master interface
output logic    [AXIM_ID_WIDTH-1:0]      m_axi_csi_awid_o,
output logic    [AXIM_ADDR_WIDTH-1:0]    m_axi_csi_awaddr_o,
output logic    [7:0]                   m_axi_csi_awlen_o,
output logic    [2:0]                   m_axi_csi_awsize_o,
output logic    [1:0]                   m_axi_csi_awburst_o,
output logic                            m_axi_csi_awlock_o,
output logic    [3:0]                   m_axi_csi_awcache_o,
output logic    [2:0]                   m_axi_csi_awprot_o,
output logic    [3:0]                   m_axi_csi_awqos_o,
output logic    [3:0]                   m_axi_csi_awregion_o,
output logic    [5:0]                   m_axi_csi_awatop_o,
output logic    [AXIM_USER_WIDTH-1:0]    m_axi_csi_awuser_o,
output logic                            m_axi_csi_awvalid_o,
input                                   m_axi_csi_awready_i,

output logic    [AXIM_DATA_WIDTH-1:0]    m_axi_csi_wdata_o,
output logic    [AXIM_DATA_WIDTH/8-1:0]  m_axi_csi_wstrb_o,
output logic                            m_axi_csi_wlast_o,
output logic    [AXIM_USER_WIDTH-1:0]    m_axi_csi_wuser_o,
output logic                            m_axi_csi_wvalid_o,
input                                   m_axi_csi_wready_i,

input           [AXIM_ID_WIDTH-1:0]      m_axi_csi_bid_i,
input           [1:0]                   m_axi_csi_bresp_i,
input           [AXIM_USER_WIDTH-1:0]    m_axi_csi_buser_i,
input                                   m_axi_csi_bvalid_i,
output logic                            m_axi_csi_bready_o,

output logic    [AXIM_ID_WIDTH-1:0]     m_axi_csi_arid_o,
output logic    [AXIM_ADDR_WIDTH-1:0]   m_axi_csi_araddr_o,
output logic    [7:0]                   m_axi_csi_arlen_o,
output logic    [2:0]                   m_axi_csi_arsize_o,
output logic    [1:0]                   m_axi_csi_arburst_o,
output logic                            m_axi_csi_arlock_o,
output logic    [3:0]                   m_axi_csi_arcache_o,
output logic    [2:0]                   m_axi_csi_arprot_o,
output logic    [3:0]                   m_axi_csi_arqos_o,
output logic    [3:0]                   m_axi_csi_arregion_o,
output logic    [AXIM_USER_WIDTH-1:0]   m_axi_csi_aruser_o,
output logic                            m_axi_csi_arvalid_o,
input  logic                            m_axi_csi_arready_i,

input           [AXIM_ID_WIDTH-1:0]     m_axi_csi_rid_i,
input           [AXIM_DATA_WIDTH-1:0]   m_axi_csi_rdata_i,
input           [1:0]                   m_axi_csi_rresp_i,
input                                   m_axi_csi_rlast_i,
input           [AXIM_USER_WIDTH-1:0]   m_axi_csi_ruser_i,
input                                   m_axi_csi_rvalid_i,
output logic                            m_axi_csi_rready_o,
input logic                             rx_byte_clk_hs_i,
input logic                             rx_valid_hs0_i,
input logic                             rx_valid_hs1_i,
input logic                             rx_valid_hs2_i,
input logic                             rx_valid_hs3_i,
input logic   [7:0]                     rx_data_hs0_i,
input logic   [7:0]                     rx_data_hs1_i,
input logic   [7:0]                     rx_data_hs2_i,
input logic   [7:0]                     rx_data_hs3_i,
output logic                            frame_wr_done_intr_o
);
//logic           rx_byte_clk_hs;
//logic           rx_valid_hs             [4];
//logic   [7:0]   rx_data_hs              [4];
//assign rx_byte_clk_hs = rx_byte_clk_hs_i;
//assign rx_valid_hs[0] = rx_valid_hs0_i;
//assign rx_valid_hs[1] = rx_valid_hs1_i;
//assign rx_valid_hs[2] = rx_valid_hs2_i;
//assign rx_valid_hs[3] = rx_valid_hs3_i;
//assign rx_data_hs[0] = rx_data_hs0_i;
//assign rx_data_hs[1] = rx_data_hs1_i;
//assign rx_data_hs[2] = rx_data_hs2_i;
//assign rx_data_hs[3] = rx_data_hs3_i;
mipi_camera_processor_fpga mipi_camera_processor_fpga_i(
                            .reset_n_i, 
                            .pixel_clk_i,
                            .axi_reset_n_i,
                            .axi_clk_i,
                            // AXI Slave Interface
                            .s_axi_lite_awaddr_i,
                            .s_axi_lite_awvalid_i,
                            .s_axi_lite_awready_o,

                            .s_axi_lite_wdata_i,
                            .s_axi_lite_wstrb_i,
                            .s_axi_lite_wvalid_i,
                            .s_axi_lite_wready_o,

                            .s_axi_lite_bresp_o,
                            .s_axi_lite_bvalid_o,
                            .s_axi_lite_bready_i,

                            .s_axi_lite_araddr_i,
                            .s_axi_lite_arvalid_i,
                            .s_axi_lite_arready_o,

                            .s_axi_lite_rdata_o,
                            .s_axi_lite_rresp_o,
                            .s_axi_lite_rvalid_o,
                            .s_axi_lite_rready_i,
                            // AXI master interface
                            .m_axi_csi_awid_o,    
                            .m_axi_csi_awaddr_o,  
                            .m_axi_csi_awlen_o,   
                            .m_axi_csi_awsize_o,  
                            .m_axi_csi_awburst_o, 
                            .m_axi_csi_awlock_o,  
                            .m_axi_csi_awcache_o, 
                            .m_axi_csi_awprot_o,  
                            .m_axi_csi_awqos_o,   
                            .m_axi_csi_awregion_o,
                            .m_axi_csi_awatop_o,  
                            .m_axi_csi_awuser_o,  
                            .m_axi_csi_awvalid_o, 
                            .m_axi_csi_awready_i, 

                            .m_axi_csi_wdata_o,   
                            .m_axi_csi_wstrb_o,   
                            .m_axi_csi_wlast_o,   
                            .m_axi_csi_wuser_o,   
                            .m_axi_csi_wvalid_o,  
                            .m_axi_csi_wready_i,  

                            .m_axi_csi_bid_i,     
                            .m_axi_csi_bresp_i,   
                            .m_axi_csi_buser_i,   
                            .m_axi_csi_bvalid_i,  
                            .m_axi_csi_bready_o,  

                            .m_axi_csi_arid_o,    
                            .m_axi_csi_araddr_o,  
                            .m_axi_csi_arlen_o,   
                            .m_axi_csi_arsize_o,  
                            .m_axi_csi_arburst_o, 
                            .m_axi_csi_arlock_o,  
                            .m_axi_csi_arcache_o, 
                            .m_axi_csi_arprot_o,  
                            .m_axi_csi_arqos_o,   
                            .m_axi_csi_arregion_o,
                            .m_axi_csi_aruser_o,
                            .m_axi_csi_arvalid_o,
                            .m_axi_csi_arready_i,

                            .m_axi_csi_rid_i,
                            .m_axi_csi_rdata_i,
                            .m_axi_csi_rresp_i,
                            .m_axi_csi_rlast_i,
                            .m_axi_csi_ruser_i,
                            .m_axi_csi_rvalid_i,
                            .m_axi_csi_rready_o,
                            .rx_byte_clk_hs(rx_byte_clk_hs_i),
                            .rx_valid_hs('{rx_valid_hs0_i, rx_valid_hs1_i, rx_valid_hs2_i, rx_valid_hs3_i}),
                            .rx_data_hs('{rx_data_hs0_i, rx_data_hs1_i, rx_data_hs2_i, rx_data_hs3_i}),
                            .frame_wr_done_intr_o
                    );

endmodule