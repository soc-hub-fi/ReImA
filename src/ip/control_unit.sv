// -----------------------------------------------------------------------------
// Module: control_unit
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// References: MIPI CSI RX specs v1.01
// Description:
//   Top-level integration for Control Unit blocks.
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
`include "mipi_csi_data_types.svh"

module control_unit (
  // Clock and reset interface
  input  logic        reset_n_i,              // Active low reset
  input  logic        rx_byte_clk_hs_i,       // Byte clock from D-PHY (non-continuous)

  // Configuration registers interface
  input  logic [1:0]  vc_id_reg_i [4],        // Virtual channel to process for each ISP pipeline
  input  logic [5:0]  data_type_reg_i [4],    // Datatype to process for each ISP pipeline
  input  logic [2:0]  active_lanes_reg_i,     // Active lanes (1, 2, or 4)
  input  logic [3:0]  clear_frame_data_i,     // Clear `err_frame_data` register
  input  logic [3:0]  clear_frame_sync_i,     // Clear `err_frame_sync` register

  // Error signals interface
  input  logic        err_sot_sync_hs_i,       // SOT sequence corrupted, synchronization not possible
  output logic        err_crc_o,               // CRC error in received packet data
  output logic        err_frame_sync_o [4],        // FS not paired with FE
  output logic        err_frame_data_o [4],        // Frame has corrupted data

  // Stream information interface
  output logic [3:0]  activate_stream_o,        // Activate stream for short packet or payload data
  output logic        header_no_error_o,        // No 1- or 2-bit errors
  output logic        header_corrected_error_o, // Corrected 1-bit error
  output logic        header_error_o,           // 2-bit error detected
  output logic        line_valid_o [4],             // Line reception active signal
  output logic [15:0] line_num_o [4],           // Line number (increments per frame)
  output logic        frame_valid_o [4],            // Frame reception active signal
  output logic [15:0] frame_num_o [4],          // Frame number (increments per FS packet)

  // Data interface
  input  logic        rx_valid_hs_i [4],        // Valid signal for high-speed data from D-PHY
  input  logic [7:0]  rx_data_hs_i [4],         // High-speed data from D-PHY
  output logic        line_valid_sync_fake_o,   // Fake line valid signal
  output logic [3:0]  byte_data_valid_o,        // Pixel data valid signal for each byte
  output logic [47:0] byte_data_o               // Pixel data (max 5 bytes for RAW10)
);

  // Parameters
  parameter int MIPI_GEAR = 8;
  parameter int MIPI_LANES = 4;

  // Internal signals
  logic [MIPI_GEAR-1:0]                 byte_o          [MIPI_LANES];
  logic                                 byte_valid_o    [MIPI_LANES];
  logic [MIPI_GEAR * MIPI_LANES-1:0]    bytes;
  logic [MIPI_LANES-1:0]                bytes_valid;
  logic [MIPI_GEAR * MIPI_LANES-1:0]    lane_bytes;
  logic [MIPI_LANES-1:0]                lane_valid;
  logic                                 sync_code;
  logic [15:0]                          packet_length_dc;
  logic                                 pd_data_valid   [4];
  logic [7:0]                           pd_data         [4];
  logic [31:0]                          packet_header;
  logic                                 packet_header_valid;
  logic [7:0]                           payload_data    [4];
  logic                                 payload_valid   [4];
  logic [15:0]                          received_crc;
  logic [1:0]                           crc_mux_sel;
  logic                                 crc_received_valid;
  logic                                 crc_capture;
  logic                                 header_valid;
  logic [15:0]                          packet_length;
  logic [1:0]                           vc_id;
  logic [5:0]                           data_type;
  logic [35:0]                          src_data;
  logic                                 fifo_input_valid;
  genvar                                i;

  logic [7:0] rx_data_hs_sync_r [4];
  logic       rx_valid_sync_r   [4];

  assign rx_valid_sync_r = rx_valid_hs_i;
  assign rx_data_hs_sync_r = rx_data_hs_i;

  // Protocol Layer
  assign {>>{pd_data_valid}} = lane_valid;
  assign {>>{pd_data}} = lane_bytes;
  assign sync_code = (data_type == `LSC) | (data_type == `LEC) | (data_type == `FSC) | (data_type == `FEC);
  assign packet_length_dc = sync_code ? 0 : packet_length;

  // Instantiate submodules
  cu_packet_decoder cu_packet_decoder_i (
      .reset_n_i(reset_n_i),
      .clk_i(rx_byte_clk_hs_i),
      .active_lanes_i(active_lanes_reg_i),
      .payload_length_i(packet_length_dc),
      .packet_header_o(packet_header),
      .packet_header_valid_o(packet_header_valid),
      .received_crc_o(received_crc),
      .crc_mux_sel_o(crc_mux_sel),
      .crc_received_valid_o(crc_received_valid),
      .crc_capture_o(crc_capture),
      .data_valid_i(rx_valid_sync_r),
      .data_i(rx_data_hs_sync_r),
      .payload_data_o(payload_data),
      .payload_valid_o(payload_valid)
  );

  cu_ecc cu_ecc_i (
      .packet_header_valid_i(packet_header_valid),
      .packet_header_i(packet_header),
      .header_valid_o(header_valid),
      .packet_length_o(packet_length),
      .vc_id_o(vc_id),
      .data_type_o(data_type),
      .no_error_o(header_no_error_o),
      .corrected_error_o(header_corrected_error_o),
      .error_o(header_error_o)
  );

  cu_crc16_top cu_crc16_top_i (
      .reset_n_i(reset_n_i),
      .clk_i(rx_byte_clk_hs_i),
      .init_i(!payload_valid[3]),
      .data_i(payload_data),
      .last_selection_i(crc_mux_sel),
      .received_crc_i(received_crc),
      .crc_received_valid_i(crc_received_valid),
      .crc_capture_i(crc_capture),
      .err_crc_o(err_crc_o)
  );

  cu_stream_controller cu_stream_controller_i (
      .reset_n_i(reset_n_i),
      .clk_i(rx_byte_clk_hs_i),
      .err_crc_i(err_crc_o),
      .vc_id_reg_i(vc_id_reg_i),
      .data_type_reg_i(data_type_reg_i),
      .packet_header_valid_i(header_valid),
      .packet_length_i(packet_length),
      .vc_id_i(vc_id),
      .data_type_i(data_type),
      .err_sot_sync_hs_i(err_sot_sync_hs_i),
      .err_ecc_double_i(header_error_o),
      .clear_frame_data_i(clear_frame_data_i),
      .clear_frame_sync_i(clear_frame_sync_i),
      .activate_stream_o(activate_stream_o),
      .line_valid_o(line_valid_o),
      .line_num_o(line_num_o),
      .frame_valid_o(frame_valid_o),
      .frame_num_o(frame_num_o),
      .err_frame_sync_o(err_frame_sync_o),
      .err_frame_data_o(err_frame_data_o)
  );

  cu_depacker cu_depacker_i (
      .clk_i(rx_byte_clk_hs_i),
      .reset_n_i(reset_n_i),
      .active_lanes_i(active_lanes_reg_i),
      .data_type_i(data_type),
      .payload_data_i(payload_data),
      .payload_valid_i(payload_valid),
      .line_valid_sync_fake_o(line_valid_sync_fake_o),
      .byte_data_o(byte_data_o),
      .byte_data_valid_o(byte_data_valid_o)
  );

endmodule