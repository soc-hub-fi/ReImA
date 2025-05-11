// -----------------------------------------------------------------------------
// Module: mem_pixel_array_wrapper
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// Functionality:
//   A wrapper module for memory pixel arrays. This module provides an interface
//   to access memory buffers for pixel data. It supports different memory
//   implementations for ASIC, FPGA, and generic use cases.
//
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
module mem_pixel_array_wrapper (
  input  logic            reset_n_i,
  input  logic            pixel_clk_i,

  input  logic  [7:0]     buffer_addr_i     [2],
  input  logic            buffer_wen_i      [2],
  input  logic  [3:0]     buffer_ben_i      [2],
  input  logic  [31:0]    buffer_wr_data_i  [2],
  output logic  [31:0]    buffer_rd_data_o  [2]
);

// TODO: Add technology-specific memories
`ifdef ASIC
  assign buffer_rd_data_o[0] = 0;
  assign buffer_rd_data_o[1] = 0;
`elsif FPGA
  xil_single_port #(
      .NB_COL(4),
      .COL_WIDTH(32),
      .RAM_DEPTH(256)
  ) u_buffer0 (
      .clka   (pixel_clk_i),
      .rsta   (!reset_n_i),
      .ena    (1'b1),
      .addra  (buffer_addr_i[0]),
      .dina   (buffer_wr_data_i[0]),
      .wea    (!buffer_ben_i[0]),
      .douta  (buffer_rd_data_o[0]),
      .regcea (1'b0)
  );

  xil_single_port #(
      .NB_COL(4),
      .COL_WIDTH(32),
      .RAM_DEPTH(256)
  ) u_buffer1 (
      .clka   (pixel_clk_i),
      .rsta   (!reset_n_i),
      .ena    (1'b1),
      .addra  (buffer_addr_i[1]),
      .dina   (buffer_wr_data_i[1]),
      .wea    (!buffer_ben_i[1]),
      .douta  (buffer_rd_data_o[1]),
      .regcea (1'b0)
  );
`else
  generic_memory #(
      .ADDR_WIDTH(8),
      .DATA_WIDTH(32)
  ) u_buffer0 (
      .CLK    (pixel_clk_i),
      .INITN  (reset_n_i),
      .CEN    (1'b0),
      .A      (buffer_addr_i[0]),
      .WEN    (buffer_wen_i[0]),
      .D      (buffer_wr_data_i[0]),
      .BEN    (buffer_ben_i[0]),
      .Q      (buffer_rd_data_o[0])
  );

  generic_memory #(
      .ADDR_WIDTH(8),
      .DATA_WIDTH(32)
  ) u_buffer1 (
      .CLK    (pixel_clk_i),
      .INITN  (reset_n_i),
      .CEN    (1'b0),
      .A      (buffer_addr_i[1]),
      .WEN    (buffer_wen_i[1]),
      .D      (buffer_wr_data_i[1]),
      .BEN    (buffer_ben_i[1]),
      .Q      (buffer_rd_data_o[1])
  );
`endif

endmodule