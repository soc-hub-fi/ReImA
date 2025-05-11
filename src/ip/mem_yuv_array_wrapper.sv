// -----------------------------------------------------------------------------
// Module: mem_yuv_array_wrapper
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// Functionality:
//   A wrapper module for YUV memory arrays. This module provides an interface
//   to access separate memory buffers for Y (luminance), U (chrominance), and
//   V (chrominance) components. It supports different memory implementations
//   for ASIC, FPGA, and generic use cases.
//
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
module mem_yuv_array_wrapper (
  input  logic            reset_n_i,
  input  logic            pixel_clk_i,

  // Y RAM signals
  input  logic  [7:0]     y_buffer_addr_i     [2],
  input  logic            y_buffer_wen_i      [2],
  input  logic  [3:0]     y_buffer_ben_i      [2],
  input  logic  [31:0]    y_buffer_wr_data_i  [2],

  // U RAM signals
  input  logic  [6:0]     u_buffer_addr_i     [2],
  input  logic            u_buffer_wen_i      [2],
  input  logic  [3:0]     u_buffer_ben_i      [2],
  input  logic  [31:0]    u_buffer_wr_data_i  [2],

  // V RAM signals
  input  logic  [6:0]     v_buffer_addr_i     [2],
  input  logic            v_buffer_wen_i      [2],
  input  logic  [3:0]     v_buffer_ben_i      [2],
  input  logic  [31:0]    v_buffer_wr_data_i  [2],

  output logic  [31:0]    y_buffer_rd_data_o  [2],
  output logic  [31:0]    u_buffer_rd_data_o  [2],
  output logic  [31:0]    v_buffer_rd_data_o  [2]
);

// TODO: Add technology-specific memories
`ifdef ASIC
  assign y_buffer_rd_data_o[0] = 0;
  assign u_buffer_rd_data_o[0] = 0;
  assign v_buffer_rd_data_o[0] = 0;
  assign y_buffer_rd_data_o[1] = 0;
  assign u_buffer_rd_data_o[1] = 0;
  assign v_buffer_rd_data_o[1] = 0;
`elsif FPGA
  logic [3:0] y_buffe_we_fpga [2];
  logic [3:0] u_buffe_we_fpga [2];
  logic [3:0] v_buffe_we_fpga [2];

  assign y_buffe_we_fpga[0] = y_buffer_wen_i[0] ? 4'b0000 : ~y_buffer_ben_i[0];
  assign y_buffe_we_fpga[1] = y_buffer_wen_i[1] ? 4'b0000 : ~y_buffer_ben_i[1];
  assign u_buffe_we_fpga[0] = u_buffer_wen_i[0] ? 4'b0000 : ~u_buffer_ben_i[0];
  assign u_buffe_we_fpga[1] = u_buffer_wen_i[1] ? 4'b0000 : ~u_buffer_ben_i[1];
  assign v_buffe_we_fpga[0] = v_buffer_wen_i[0] ? 4'b0000 : ~v_buffer_ben_i[0];
  assign v_buffe_we_fpga[1] = v_buffer_wen_i[1] ? 4'b0000 : ~v_buffer_ben_i[1];

  // Generate Xilinx memories
  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(256)
  ) y_buffer0 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (y_buffer_addr_i[0]),
    .dina   (y_buffer_wr_data_i[0]),
    .wea    (y_buffe_we_fpga[0]),
    .douta  (y_buffer_rd_data_o[0]),
    .regcea (1'b0)
  );

  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(256)
  ) y_buffer1 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (y_buffer_addr_i[1]),
    .dina   (y_buffer_wr_data_i[1]),
    .wea    (y_buffe_we_fpga[1]),
    .douta  (y_buffer_rd_data_o[1]),
    .regcea (1'b0)
  );

  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(128)
  ) u_buffer0 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (u_buffer_addr_i[0]),
    .dina   (u_buffer_wr_data_i[0]),
    .wea    (u_buffe_we_fpga[0]),
    .douta  (u_buffer_rd_data_o[0]),
    .regcea (1'b0)
  );

  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(128)
  ) u_buffer1 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (u_buffer_addr_i[1]),
    .dina   (u_buffer_wr_data_i[1]),
    .wea    (u_buffe_we_fpga[1]),
    .douta  (u_buffer_rd_data_o[1]),
    .regcea (1'b0)
  );

  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(128)
  ) v_buffer0 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (v_buffer_addr_i[0]),
    .dina   (v_buffer_wr_data_i[0]),
    .wea    (v_buffe_we_fpga[0]),
    .douta  (v_buffer_rd_data_o[0]),
    .regcea (1'b0)
  );

  xil_single_port #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(128)
  ) v_buffer1 (
    .clka   (pixel_clk_i),
    .rsta   (!reset_n_i),
    .ena    (1'b1),
    .addra  (v_buffer_addr_i[1]),
    .dina   (v_buffer_wr_data_i[1]),
    .wea    (v_buffe_we_fpga[1]),
    .douta  (v_buffer_rd_data_o[1]),
    .regcea (1'b0)
  );

`else
  generic_memory #(
    .ADDR_WIDTH(8), // 256
    .DATA_WIDTH(32)
  ) y_buffer0 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (y_buffer_addr_i[0]),
    .WEN    (y_buffer_wen_i[0]),
    .D      (y_buffer_wr_data_i[0]),
    .BEN    (y_buffer_ben_i[0]),
    .Q      (y_buffer_rd_data_o[0])
  );

  generic_memory #(
    .ADDR_WIDTH(8), // 256
    .DATA_WIDTH(32)
  ) y_buffer1 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (y_buffer_addr_i[1]),
    .WEN    (y_buffer_wen_i[1]),
    .D      (y_buffer_wr_data_i[1]),
    .BEN    (y_buffer_ben_i[1]),
    .Q      (y_buffer_rd_data_o[1])
  );

  generic_memory #(
    .ADDR_WIDTH(7), // 128
    .DATA_WIDTH(32)
  ) u_buffer0 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (u_buffer_addr_i[0]),
    .WEN    (u_buffer_wen_i[0]),
    .D      (u_buffer_wr_data_i[0]),
    .BEN    (u_buffer_ben_i[0]),
    .Q      (u_buffer_rd_data_o[0])
  );

  generic_memory #(
    .ADDR_WIDTH(7), // 128
    .DATA_WIDTH(32)
  ) u_buffer1 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (u_buffer_addr_i[1]),
    .WEN    (u_buffer_wen_i[1]),
    .D      (u_buffer_wr_data_i[1]),
    .BEN    (u_buffer_ben_i[1]),
    .Q      (u_buffer_rd_data_o[1])
  );

  generic_memory #(
    .ADDR_WIDTH(7), // 128
    .DATA_WIDTH(32)
  ) v_buffer0 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (v_buffer_addr_i[0]),
    .WEN    (v_buffer_wen_i[0]),
    .D      (v_buffer_wr_data_i[0]),
    .BEN    (v_buffer_ben_i[0]),
    .Q      (v_buffer_rd_data_o[0])
  );

  generic_memory #(
    .ADDR_WIDTH(7), // 128
    .DATA_WIDTH(32)
  ) v_buffer1 (
    .CLK    (pixel_clk_i),
    .INITN  (reset_n_i),
    .CEN    (1'b0),
    .A      (v_buffer_addr_i[1]),
    .WEN    (v_buffer_wen_i[1]),
    .D      (v_buffer_wr_data_i[1]),
    .BEN    (v_buffer_ben_i[1]),
    .Q      (v_buffer_rd_data_o[1])
  );
`endif
endmodule