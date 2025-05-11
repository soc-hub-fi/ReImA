`include "csi_regs.svh"
`include "axi_assign.svh"
`include "axi/typedef.svh"

module iap_core #(
  parameter AXIM_ID_WIDTH     = 3,
  parameter AXIM_ADDR_WIDTH   = 32,
  parameter AXIM_DATA_WIDTH   = 32,
  parameter AXIM_USER_WIDTH   = 1,
  parameter AXIS_ID_WIDTH     = 3,
  parameter AXIS_ADDR_WIDTH   = 32,
  parameter AXIS_DATA_WIDTH   = 32,
  parameter AXIS_USER_WIDTH   = 1
) (
  // Clocks and reset interface
  input logic                             reset_n_i,
  input logic                             pixel_clk_i,
  input logic                             axi_reset_n_i,
  input logic                             axi_clk_i,

  // AXI Slave Register Interface
  input logic     [AXIS_ID_WIDTH-1:0]     s_axi_csi_awid_i,
  input logic     [AXIS_ADDR_WIDTH-1:0]   s_axi_csi_awaddr_i,
  input logic     [7:0]                   s_axi_csi_awlen_i,
  input logic     [2:0]                   s_axi_csi_awsize_i,
  input logic     [1:0]                   s_axi_csi_awburst_i,
  input logic                             s_axi_csi_awlock_i,
  input logic     [3:0]                   s_axi_csi_awcache_i,
  input logic     [2:0]                   s_axi_csi_awprot_i,
  input logic     [3:0]                   s_axi_csi_awqos_i,
  input logic     [3:0]                   s_axi_csi_awregion_i,
  input logic     [5:0]                   s_axi_csi_awatop_i,
  input logic     [AXIS_USER_WIDTH-1:0]   s_axi_csi_awuser_i,
  input logic                             s_axi_csi_awvalid_i,
  output logic                            s_axi_csi_awready_o,

  input logic     [AXIS_DATA_WIDTH-1:0]   s_axi_csi_wdata_i,
  input logic     [AXIS_DATA_WIDTH/8-1:0] s_axi_csi_wstrb_i,
  input logic                             s_axi_csi_wlast_i,
  input logic     [AXIS_USER_WIDTH-1:0]   s_axi_csi_wuser_i,
  input logic                             s_axi_csi_wvalid_i,
  output logic                            s_axi_csi_wready_o,

  output logic    [AXIS_ID_WIDTH-1:0]     s_axi_csi_bid_o,
  output logic    [1:0]                   s_axi_csi_bresp_o,
  output logic    [AXIS_USER_WIDTH-1:0]   s_axi_csi_buser_o,
  output logic                            s_axi_csi_bvalid_o,
  input logic                             s_axi_csi_bready_i,

  input logic     [AXIS_ID_WIDTH-1:0]     s_axi_csi_arid_i,
  input logic     [AXIS_ADDR_WIDTH-1:0]   s_axi_csi_araddr_i,
  input logic     [7:0]                   s_axi_csi_arlen_i,
  input logic     [2:0]                   s_axi_csi_arsize_i,
  input logic     [1:0]                   s_axi_csi_arburst_i,
  input logic                             s_axi_csi_arlock_i,
  input logic     [3:0]                   s_axi_csi_arcache_i,
  input logic     [2:0]                   s_axi_csi_arprot_i,
  input logic     [3:0]                   s_axi_csi_arqos_i,
  input logic     [3:0]                   s_axi_csi_arregion_i,
  input logic     [AXIS_USER_WIDTH-1:0]   s_axi_csi_aruser_i,
  input logic                             s_axi_csi_arvalid_i,
  output logic                            s_axi_csi_arready_o,

  output logic    [AXIS_ID_WIDTH-1:0]     s_axi_csi_rid_o,
  output logic    [AXIS_DATA_WIDTH-1:0]   s_axi_csi_rdata_o,
  output logic    [1:0]                   s_axi_csi_rresp_o,
  output logic                            s_axi_csi_rlast_o,
  output logic    [AXIS_USER_WIDTH-1:0]   s_axi_csi_ruser_o,
  output logic                            s_axi_csi_rvalid_o,
  input logic                             s_axi_csi_rready_i,

  // AXI Master Interface
  output logic    [AXIM_ID_WIDTH-1:0]     m_axi_csi_awid_o,
  output logic    [AXIM_ADDR_WIDTH-1:0]   m_axi_csi_awaddr_o,
  output logic    [7:0]                   m_axi_csi_awlen_o,
  output logic    [2:0]                   m_axi_csi_awsize_o,
  output logic    [1:0]                   m_axi_csi_awburst_o,
  output logic                            m_axi_csi_awlock_o,
  output logic    [3:0]                   m_axi_csi_awcache_o,
  output logic    [2:0]                   m_axi_csi_awprot_o,
  output logic    [3:0]                   m_axi_csi_awqos_o,
  output logic    [3:0]                   m_axi_csi_awregion_o,
  output logic    [5:0]                   m_axi_csi_awatop_o,
  output logic    [AXIM_USER_WIDTH-1:0]   m_axi_csi_awuser_o,
  output logic                            m_axi_csi_awvalid_o,
  input logic                             m_axi_csi_awready_i,

  output logic    [AXIM_DATA_WIDTH-1:0]   m_axi_csi_wdata_o,
  output logic    [AXIM_DATA_WIDTH/8-1:0] m_axi_csi_wstrb_o,
  output logic                            m_axi_csi_wlast_o,
  output logic    [AXIM_USER_WIDTH-1:0]   m_axi_csi_wuser_o,
  output logic                            m_axi_csi_wvalid_o,
  input logic                             m_axi_csi_wready_i,

  input logic     [AXIM_ID_WIDTH-1:0]     m_axi_csi_bid_i,
  input logic     [1:0]                   m_axi_csi_bresp_i,
  input logic     [AXIM_USER_WIDTH-1:0]   m_axi_csi_buser_i,
  input logic                             m_axi_csi_bvalid_i,
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
  input logic                             m_axi_csi_arready_i,

  input logic     [AXIM_ID_WIDTH-1:0]     m_axi_csi_rid_i,
  input logic     [AXIM_DATA_WIDTH-1:0]   m_axi_csi_rdata_i,
  input logic     [1:0]                   m_axi_csi_rresp_i,
  input logic                             m_axi_csi_rlast_i,
  input logic     [AXIM_USER_WIDTH-1:0]   m_axi_csi_ruser_i,
  input logic                             m_axi_csi_rvalid_i,
  output logic                            m_axi_csi_rready_o,

  // Additional signals
  input logic                             rx_byte_clk_hs,
  input logic                             rx_valid_hs [4],
  input logic     [7:0]                   rx_data_hs [4],
  output logic                            frame_wr_done_intr_o
);

  parameter                     REG_NUM_BYTES = `REG_NUM_BYTES;
  parameter [REG_NUM_BYTES-1:0] REG_RO_EN     = `ASSIGN_RO_REGS;
  parameter                     REG_RST_VAL   = 0;

  logic   [1:0]   vc_id_reg[4];
  logic   [5:0]   data_type_reg[4];
  logic   [5:0]   byte_data_type_reg[4];
  logic   [2:0]   active_lanes_reg;
  logic           clear_frame_data[4];
  logic           clear_frame_sync[4];
  logic           err_sot_hs;
  logic           err_sot_sync_hs;

  logic           err_crc;
  logic           err_frame_sync[4];
  logic           err_frame_data[4];

  logic   [3:0]   activate_stream;
  logic           header_no_error;
  logic           header_corrected_error;
  logic           header_error;
  logic           line_valid[4];
  logic   [15:0]  line_num[4];
  logic           frame_valid[4];
  logic   [15:0]  frame_num[4];
  logic           line_valid_sync_fake;

  logic   [3:0]   byte_data_valid;
  logic   [47:0]  byte_data;

  logic           stream_stall;
  logic   [2:0]   pixel_per_clk_reg[4];
  logic   [1:0]   bayer_filter_type_reg[4];
  logic           line_valid_pixel_sync[4];
  logic           line_valid_yuv_sync[4];
  logic   [63:0]  yuv422_data[4];
  logic   [7:0]   yuv422_byte_valid[4];
  logic   [95:0]  pixel_data[4];          // Preprocessed data coming from flow control with a specified pixel per clock
  logic   [11:0]  pixel_byte_valid[4];    // Each bit in the valid corresponds to a byte in the pixel_data_o interface
  
  // csi_axi_master signals
  logic                           double_buff_enable_reg;
  logic                           frame_done_pulse[4];
  logic   [AXIS_ADDR_WIDTH-1:0]   frame_ptr0;           // Points to either the preprocessed pixel frame or Y channel location for YUV420 (Y)
  logic   [AXIS_ADDR_WIDTH-1:0]   frame_ptr1;           // Points to either the preprocessed pixel frame or Y channel location for YUV420 (Y)
  logic   [11:0]                  frame_width;
  logic   [11:0]                  frame_height;
  logic                           csi_enable;
  logic                           output_select;        // select the output 1 for yuv420, 0 for pixel data
  
  // Register Inteface Signals
  typedef logic [AXIS_ADDR_WIDTH-1:0]   axi_addr_t;
  typedef logic [AXIS_DATA_WIDTH-1:0]   axi_data_t;
  typedef logic [AXIS_DATA_WIDTH/8-1:0] axi_strb_t;
  typedef logic [AXIS_ID_WIDTH-1:0]     axi_id_t;
  typedef logic [AXIS_USER_WIDTH-1:0]   axi_user_t;
  
  logic [REG_NUM_BYTES-1:0]   wr_active;
  logic [REG_NUM_BYTES-1:0]   rd_active;
  logic [REG_NUM_BYTES*8-1:0] reg_d;
  logic                       byte_reset_n_sync;
  logic [REG_NUM_BYTES-1:0]   reg_load;
  logic [REG_NUM_BYTES*8-1:0] reg_q;
  logic [REG_NUM_BYTES*8-1:0] reg_q_pixel_sync;
  logic [REG_NUM_BYTES*8-1:0] reg_q_byte_sync;
  logic                       src_rcv_pixel;
  logic                       src_send_pixel;
  logic                       src_rcv_byte;
  logic                       src_send_byte;

  `AXI_TYPEDEF_ALL(axi, axi_addr_t, axi_id_t, axi_data_t, axi_strb_t, axi_user_t)      
  
  axi_req_t axi_req_s;
  axi_resp_t axi_resp_s;
  axi_req_t axi_req_m;
  axi_resp_t axi_resp_m;
  
  // AXI lite signals
  `AXI_LITE_TYPEDEF_ALL(axi_lite, axi_addr_t, axi_data_t, axi_strb_t)    
  
  axi_lite_req_t  axi_lite_req;
  axi_lite_resp_t axi_lite_resp;

  ////////////////////////////
  // AXI Register Interface //
  ////////////////////////////
  `AXI_IOASSIGN_SLAVE_TO_FLAT(csi, axi_req_s, axi_resp_s)
  axi_to_axi_lite #(
    .AxiAddrWidth               (AXIS_ADDR_WIDTH),      // 32-bit address width
    .AxiDataWidth               (AXIS_DATA_WIDTH),      // 32-bit data width
    .AxiIdWidth                 (AXIS_ID_WIDTH),        // 32-bit ID width
    .AxiUserWidth               (AXIS_USER_WIDTH),      // 32-bit user width
    .AxiMaxWriteTxns            (32'd1),                // 256 write transactions
    .AxiMaxReadTxns             (32'd1),                // 256 read transactions    
    .FallThrough                (1'b0),                 // FIFOs in Fall through mode in ID reflect
    .full_req_t                 (axi_req_t),            // AXI4+ATOP request   
    .full_resp_t                (axi_resp_t),           // AXI4+ATOP response
    .lite_req_t                 (axi_lite_req_t),       // AXI4-Lite request
    .lite_resp_t                (axi_lite_resp_t)       // AXI4-Lite response
  ) u_axi_to_axi_lite (
    .clk_i                      (axi_clk_i),            // Clock
    .rst_ni                     (axi_reset_n_i),        // Asynchronous reset active low
    .test_i                     (1'b0),                 // Test mode enable
    // Slave port full AXI4+ATOP
    .slv_req_i                  (axi_req_s),            // AXI4+ATOP request
    .slv_resp_o                 (axi_resp_s),           // AXI4+ATOP response
    // Master port AXI4-Lite
    .mst_req_o                  (axi_lite_req),         // AXI4-Lite request
    .mst_resp_i                 (axi_lite_resp)         // AXI4-Lite response
  );

  axi_lite_regs #(
    .RegNumBytes                (REG_NUM_BYTES),        // 10 registers of 8 bytes
    .AxiAddrWidth               (AXIS_ADDR_WIDTH),      // 32-bit address width
    .AxiDataWidth               (AXIS_DATA_WIDTH),      // 32-bit data width
    .PrivProtOnly               (1'b0),                 // Allow only privileged accesses
    .SecuProtOnly               (1'b0),                 // Allow only secure access
    .AxiReadOnly                (REG_RO_EN),            // If that bit is `1`, the byte can only be read on the AXI4-Lite port
    .RegRstVal                  ('0),                   // Reset value of the registers
    .req_lite_t                 (axi_lite_req_t),       // AXI4-Lite request datatype
    .resp_lite_t                (axi_lite_resp_t)       // AXI4-Lite response datatype
  ) u_axi_lite_regs (
    .clk_i                      (axi_clk_i),            // Clock
    .rst_ni                     (axi_reset_n_i),        // Asynchronous reset active low
    .axi_req_i                  (axi_lite_req),         // AXI4-Lite request
    .axi_resp_o                 (axi_lite_resp),        // AXI4-Lite response
    .wr_active_o                (wr_active),            // Write transaction is in progress
    .rd_active_o                (rd_active),            // Read transaction is in progress
    .reg_d_i                    (768'd0),               // Data to be written to the register
    .reg_load_i                 (96'd0),                // Load the register with the data 
    .reg_q_o                    (reg_q)                 // Data read from the register
  );

`ifdef FPGA
  // xpm_cdc_handshake: Bus Synchronizer with Full Handshake
  // Xilinx Parameterized Macro, version 2021.2
  xpm_cdc_handshake #(
    .DEST_EXT_HSK   (0),  // DECIMAL; 0=internal handshake, 1=external handshake
    .DEST_SYNC_FF   (4),  // DECIMAL; range: 2-10
    .INIT_SYNC_FF   (1),  // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK (1),  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_SYNC_FF    (4),  // DECIMAL; range: 2-10
    .WIDTH          (768) // DECIMAL; range: 1-1024
  ) xpm_cdc_handshake_byte_i (
    .dest_out    (reg_q_byte_sync), // WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain.
                                    // This output is registered.

    .dest_req    (),                // 1-bit output: Assertion of this signal indicates that new dest_out data has been
                                    // received and is ready to be used or captured by the destination logic. When
                                    // DEST_EXT_HSK = 1, this signal will deassert once the source handshake
                                    // acknowledges that the destination clock domain has received the transferred data.
                                    // When DEST_EXT_HSK = 0, this signal asserts for one clock period when dest_out bus
                                    // is valid. This output is registered.

    .src_rcv     (src_rcv_byte),    // 1-bit output: Acknowledgement from destination logic that src_in has been
                                    // received. This signal will be deasserted once destination handshake has fully
                                    // completed, thus completing a full data transfer. This output is registered.

    .dest_ack    (1'b0),            // 1-bit input: optional; required when DEST_EXT_HSK = 1
    .dest_clk    (rx_byte_clk_hs),  // 1-bit input: Destination clock.
    .src_clk     (axi_clk_i),       // 1-bit input: Source clock.
    .src_in      (reg_q),           // WIDTH-bit input: Input bus that will be synchronized to the destination clock
                                    // domain.

    .src_send    (src_send_byte)    // 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to
                                    // the destination clock domain. This signal should only be asserted when src_rcv is
                                    // deasserted, indicating that the previous data transfer is complete. This signal
                                    // should only be deasserted once src_rcv is asserted, acknowledging that the src_in
                                    // has been received by the destination logic.
  );
  // End of xpm_cdc_handshake_inst instantiation
  
  assign src_send_byte = !src_rcv_byte;

  // xpm_cdc_handshake: Bus Synchronizer with Full Handshake
  // Xilinx Parameterized Macro, version 2021.2
  xpm_cdc_handshake #(
    .DEST_EXT_HSK   (0),  // DECIMAL; 0=internal handshake, 1=external handshake
    .DEST_SYNC_FF   (4),  // DECIMAL; range: 2-10
    .INIT_SYNC_FF   (1),  // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK (1),  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_SYNC_FF    (4),  // DECIMAL; range: 2-10
    .WIDTH          (768) // DECIMAL; range: 1-1024
  ) xpm_cdc_handshake_pixel_i (
    .dest_out (reg_q_pixel_sync),   // WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain.
                                    // This output is registered.

    .dest_req (),                   // 1-bit output: Assertion of this signal indicates that new dest_out data has been
                                    // received and is ready to be used or captured by the destination logic. When
                                    // DEST_EXT_HSK = 1, this signal will deassert once the source handshake
                                    // acknowledges that the destination clock domain has received the transferred data.
                                    // When DEST_EXT_HSK = 0, this signal asserts for one clock period when dest_out bus
                                    // is valid. This output is registered.

    .src_rcv  (src_rcv_pixel),      // 1-bit output: Acknowledgement from destination logic that src_in has been
                                    // received. This signal will be deasserted once destination handshake has fully
                                    // completed, thus completing a full data transfer. This output is registered.

    .dest_ack (1'b0),               // 1-bit input: optional; required when DEST_EXT_HSK = 1
    .dest_clk (pixel_clk_i),        // 1-bit input: Destination clock.
    .src_clk  (axi_clk_i),          // 1-bit input: Source clock.
    .src_in   (reg_q),              // WIDTH-bit input: Input bus that will be synchronized to the destination clock
                                    // domain.

    .src_send (src_send_pixel)      // 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to
                                    // the destination clock domain. This signal should only be asserted when src_rcv is
                                    // deasserted, indicating that the previous data transfer is complete. This signal
                                    // should only be deasserted once src_rcv is asserted, acknowledging that the src_in
                                    // has been received by the destination logic.
  );
  // End of xpm_cdc_handshake_inst instantiation
  
  assign src_send_pixel = !src_rcv_pixel;

`else //no cdc in simulation

  assign reg_q_byte_sync = reg_q;
  assign reg_q_pixel_sync = reg_q;

`endif

  //////////////////
  // Control Unit //
  //////////////////
  
  assign active_lanes_reg       = `FETCH_PCR_FIELD(reg_q_byte_sync, "ACTIVE_LANES");
  assign vc_id_reg[0]           = `FETCH_ICR_FIELD(reg_q_byte_sync, "VCID_SEL0");
  assign vc_id_reg[1]           = `FETCH_ICR_FIELD(reg_q_byte_sync, "VCID_SEL1");
  assign vc_id_reg[2]           = `FETCH_ICR_FIELD(reg_q_byte_sync, "VCID_SEL2");
  assign vc_id_reg[3]           = `FETCH_ICR_FIELD(reg_q_byte_sync, "VCID_SEL3");
  assign byte_data_type_reg[0]  = `FETCH_ICR_FIELD(reg_q_byte_sync, "DATA_TYPE_SEL0");
  assign byte_data_type_reg[1]  = `FETCH_ICR_FIELD(reg_q_byte_sync, "DATA_TYPE_SEL1");
  assign byte_data_type_reg[2]  = `FETCH_ICR_FIELD(reg_q_byte_sync, "DATA_TYPE_SEL2");
  assign byte_data_type_reg[3]  = `FETCH_ICR_FIELD(reg_q_byte_sync, "DATA_TYPE_SEL3");
  
  control_unit control_unit_i (
    // Clock and reset interface
    .reset_n_i                  (reset_n_i),            // Active low reset
    .rx_byte_clk_hs_i           (rx_byte_clk_hs),       // Byte clock from D-PHY

    // Configuration registers interface
    .vc_id_reg_i                (vc_id_reg),            // Picks a virtual channel to be processed for each ISP pipeline
    .data_type_reg_i            (byte_data_type_reg),   // Picks a datatype to be processed for each ISP pipeline
    .active_lanes_reg_i         (active_lanes_reg),     // Active lanes from config register (1, 2, or 4 lanes active)
    .clear_frame_data_i         (4'd0),                 // Active high pulse to clear err_frame_data register
    .clear_frame_sync_i         (4'd0),                 // Active high pulse to clear err_frame_sync register

    // Error signals interface
    .err_sot_sync_hs_i          (1'd0),                 // SOT sequence corrupted, synchronization not possible
    .err_crc_o                  (err_crc),              // Active high pulse indicating error in received packet data
    .err_frame_sync_o           (err_frame_sync),       // FS not paired with FE
    .err_frame_data_o           (err_frame_data),       // Frame has corrupted data

    // Stream information interface
    .activate_stream_o          (activate_stream),      // Activate stream to receive short packet info or payload data
    .header_no_error_o          (header_no_error),      // No 1 or 2-bit errors detected
    .header_corrected_error_o   (header_corrected_error), // Corrected 1-bit error
    .header_error_o             (header_error),         // 2-bit error detected
    .line_valid_o               (line_valid),           // Line reception active signal
    .line_num_o                 (line_num),             // Line number increments (non-interlaced or interlaced)
    .frame_valid_o              (frame_valid),          // Frame reception active signal
    .frame_num_o                (frame_num),            // Frame number increments for every FS packet with same VCID

    // Data interface
    .rx_valid_hs_i              (rx_valid_hs),          // Valid signal for high-speed data transmission from D-PHY
    .rx_data_hs_i               (rx_data_hs),           // High-speed data transmission from D-PHY
    .line_valid_sync_fake_o     (line_valid_sync_fake),  // Fake synchronized line valid signal
    .byte_data_valid_o          (byte_data_valid),      // Pixel data valid signal for each byte in the pixel data
    .byte_data_o                (byte_data)             // Pixel data composed of up to 5 bytes (e.g., RAW10)
  );

  ///////////////////////////
  // Image Processing Unit //
  ///////////////////////////
  
  assign data_type_reg[0]           = `FETCH_ICR_FIELD(reg_q_pixel_sync, "DATA_TYPE_SEL0");
  assign data_type_reg[1]           = `FETCH_ICR_FIELD(reg_q_pixel_sync, "DATA_TYPE_SEL1");
  assign data_type_reg[2]           = `FETCH_ICR_FIELD(reg_q_pixel_sync, "DATA_TYPE_SEL2");
  assign data_type_reg[3]           = `FETCH_ICR_FIELD(reg_q_pixel_sync, "DATA_TYPE_SEL3");
  assign pixel_per_clk_reg[0]       = `FETCH_PCR_FIELD(reg_q_pixel_sync, "PIXEL_PER_CLK0");
  assign pixel_per_clk_reg[1]       = `FETCH_PCR_FIELD(reg_q_pixel_sync, "PIXEL_PER_CLK1");
  assign pixel_per_clk_reg[2]       = `FETCH_PCR_FIELD(reg_q_pixel_sync, "PIXEL_PER_CLK2");
  assign pixel_per_clk_reg[3]       = `FETCH_PCR_FIELD(reg_q_pixel_sync, "PIXEL_PER_CLK3");
  assign bayer_filter_type_reg[0]   = `FETCH_PCR_FIELD(reg_q_pixel_sync, "BAYER_TYPE0");
  assign bayer_filter_type_reg[1]   = `FETCH_PCR_FIELD(reg_q_pixel_sync, "BAYER_TYPE1");
  assign bayer_filter_type_reg[2]   = `FETCH_PCR_FIELD(reg_q_pixel_sync, "BAYER_TYPE2");
  assign bayer_filter_type_reg[3]   = `FETCH_PCR_FIELD(reg_q_pixel_sync, "BAYER_TYPE3");

  image_processing_unit #(
    .PIPELINE_WIDTH(1)
  ) image_processing_unit_i (
    // Clocks and reset interface
    .byte_reset_n_i             (reset_n_i),                  // Active low reset
    .byte_clk_i                 (rx_byte_clk_hs),             // Byte clock usually 1/8 of the line rate coming from the DPHY
    .pixel_reset_n_i            (reset_n_i),                  // Active low reset
    .pixel_clk_i                (pixel_clk_i),                // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
    
    // Configuration register interface
    .pixel_per_clk_reg_i        (pixel_per_clk_reg[0:0]),     // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
    .data_type_reg_i            (data_type_reg[0:0]),         // Programmable datatype that each pipeline should process
    .bayer_filter_type_reg_i    (bayer_filter_type_reg[0:0]), // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
    
    // Stream information interface
    .activate_stream_i          (activate_stream),            // Picks which ISP pipeline does the data go to
    .frame_valid_i              (frame_valid[0:0]),           // Frame reception is in progress signal
    .line_valid_i               (line_valid[0:0]),            // Line reception is in progress signal
    .frame_done_pulse_o         (frame_done_pulse[0:0]),      // Frame done signal from debayer
    
    // Data interface
    .line_valid_pixel_sync_o    (line_valid_pixel_sync[0:0]), // Synchronized line valid signal with the data output interface
    .line_valid_sync_fake_i     (line_valid_sync_fake),
    .byte_data_valid_i          (byte_data_valid),            // Pixel data valid signal for each pixel in the pixel data in the byte clock domain
    .byte_data_i                (byte_data),                  // Max width is 2 RGB888 pixels 2*24 = 48 these are pixels in the byte clock domain
    .line_valid_yuv_sync_o      (line_valid_yuv_sync[0:0]),   // Synchronized line valid signal with the data output interface
    .yuv422_data_o              (yuv422_data[0:0]),           // YUV data (YUYV format) if 4ppc is selected, output is YUYV,YUYV if 2ppc output is YUYV if 1ppc output alternates each cycle between YU and YV
    .yuv422_byte_valid_o        (yuv422_byte_valid[0:0]),     // YUV valid each bit corresponds to 16 bits (1 pixel) of the YUV data
    .pixel_data_o               (pixel_data[0:0]),            // Preprocessed data coming from flow control with a specified pixel per clock
    .pixel_byte_valid_o         (pixel_byte_valid[0:0])       // Each bit in the valid corresponds to a byte in the pixel_data_o interface
  );
  
  ////////////////
  // AXI Master //
  ////////////////

  assign frame_width              = `FETCH_FWR_FIELD(reg_q_pixel_sync, "FRAME_WIDTH");
  assign frame_height             = `FETCH_FHR_FIELD(reg_q_pixel_sync, "FRAME_HEIGHT");
  assign frame_ptr0               = `FETCH_FPR0_FIELD(reg_q_pixel_sync, "FRAME_POINTER");
  assign frame_ptr1               = `FETCH_FPR1_FIELD(reg_q_pixel_sync, "FRAME_POINTER");
  assign double_buff_enable_reg   = `FETCH_CCR_FIELD(reg_q_pixel_sync, "DOUB_BUFF_EN");
  assign csi_enable               = `FETCH_CCR_FIELD(reg_q_pixel_sync, "CORE_ENABLE");
  assign output_select            = `FETCH_CCR_FIELD(reg_q_pixel_sync, "OUTPUT_SELECT");
  `AXI_IOASSIGN_MASTER_TO_FLAT(csi, axi_req_m, axi_resp_m)

  axi_master #(
    .AXI_ID_WIDTH               (AXIM_ID_WIDTH),
    .AXI_ADDR_WIDTH             (AXIM_ADDR_WIDTH),
    .AXI_DATA_WIDTH             (AXIM_DATA_WIDTH),
    .AXI_USER_WIDTH             (AXIM_USER_WIDTH),
    .full_req_t                 (axi_req_t),
    .full_resp_t                (axi_resp_t)
  ) axi_master_i (
    // Clocks and reset interface
    .reset_n_i                  (reset_n_i),
    .pixel_clk_i                (pixel_clk_i),
    .line_valid_pixel_i         (line_valid_pixel_sync[0]), // Synchronized line valid signal from ISP
    .pixel_data_i               (pixel_data[0]),            // Pixel data input from flow control
    .pixel_byte_valid_i         (pixel_byte_valid[0]),      // Pixel byte data valid from flow control
    .line_valid_yuv_i           (line_valid_yuv_sync[0]),   // Synchronized line valid signal from ISP
    .yuv422_data_i              (yuv422_data[0]),           // YUV422 data from RGB2YUV block
    .yuv422_byte_valid_i        (yuv422_byte_valid[0]),     // Valid bit for each byte in the data interface
    .stream_stall_o             (stream_stall),
    .double_buff_enable_reg_i   (double_buff_enable_reg),
    .frame_done_pulse_i         (frame_done_pulse[0]),
    .frame_width_i              (frame_width),
    .frame_height_i             (frame_height),
    .frame_ptr0_i               (frame_ptr0),               // Points to preprocessed pixel frame or Y channel location for YUV420 (Y)
    .frame_ptr1_i               (frame_ptr1),               // Points to preprocessed pixel frame or Y channel location for YUV420 (Y)
    .csi_enable_i               (csi_enable),
    .output_select_i            (output_select),            // Select the output: 1 for YUV420, 0 for pixel data

    // AXI address write interface
    .mst_req_o                  (axi_req_m),
    .mst_resp_i                 (axi_resp_m),
    .frame_wr_done_intr_o       (frame_wr_done_intr_o)
  );
endmodule