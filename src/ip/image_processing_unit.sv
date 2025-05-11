//---------------------------------------------------------------------
// Module: image_processing_unit
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// References: According to MIPI CSI RX specs v1.01

// Functionality: 
//    The module is a top level integration for Image Signal Processing and Pixel control logic
//    You can instantiate a variable number of ISP pipelines which corresponds to the number of
//    Virtual Channels supported in the design
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//----------------------------------------------------------------------
module image_processing_unit #(
  parameter PIPELINE_WIDTH = 4 // Number of ISP pipelines
) (
  input  logic                        byte_reset_n_i,                           // Active low reset
  input  logic                        byte_clk_i,                               // Byte clock, usually 1/8 of the line rate from the DPHY
  input  logic                        pixel_reset_n_i,                          // Active low reset for pixel domain
  input  logic                        pixel_clk_i,                              // Pixel clock, must be > ((line rate * #ActiveLanes) / (PPC * BitsPerPixel))
  input  logic                        isp_clk_enable_i,
  input  logic [3:0]                  activate_stream_i,                        // Selects which ISP pipeline receives data
  input  logic [2:0]                  pixel_per_clk_reg_i [PIPELINE_WIDTH],     // Pixels per clock for each pipeline (1, 2, or 4)
  input  logic [5:0]                  data_type_reg_i [PIPELINE_WIDTH],         // Data type for each pipeline
  input  logic [1:0]                  bayer_filter_type_reg_i [PIPELINE_WIDTH], // Bayer filter type: RGGB(00), BGGR(01), GBRG(10), GRBG(11)
  input  logic [PIPELINE_WIDTH-1:0]   frame_valid_i,                            // Frame reception in progress for each pipeline
  input  logic [PIPELINE_WIDTH-1:0]   line_valid_i,                             // Line reception in progress for each pipeline
  output logic [PIPELINE_WIDTH-1:0]   line_valid_pixel_sync_o,                  // Synchronized line_valid with data output
  output logic [PIPELINE_WIDTH-1:0]   line_valid_yuv_sync_o,                    // Synchronized line_valid for YUV output
  output logic [PIPELINE_WIDTH-1:0]   frame_done_pulse_o,                       // Frame done pulse from debayer
  input  logic                        line_valid_sync_fake_i,
  input  logic [3:0]                  byte_data_valid_i,                        // Pixel data valid for each pixel in byte clock domain
  input  logic [47:0]                 byte_data_i,                              // Up to 2 RGB888 pixels (2*24=48 bits) in byte clock domain
  output logic [63:0]                 yuv422_data_o [PIPELINE_WIDTH],           // YUV data (YUYV format)
  output logic [7:0]                  yuv422_byte_valid_o [PIPELINE_WIDTH],     // YUV valid, each bit for 16 bits (1 pixel)
  output logic [95:0]                 pixel_data_o [PIPELINE_WIDTH],            // Preprocessed data from flow control
  output logic [11:0]                 pixel_byte_valid_o [PIPELINE_WIDTH]       // Each bit valid for a byte in pixel_data_o
);

  // flow control signals
  logic           dst_clear_pending [PIPELINE_WIDTH];
  logic           src_clear_pending [PIPELINE_WIDTH];
  logic           frame_valid_sync [PIPELINE_WIDTH];
  logic           line_valid_sync_fake [PIPELINE_WIDTH];
  logic [3:0]     byte_data_valid [PIPELINE_WIDTH];
  logic [3:0]     pixel_data_valid [PIPELINE_WIDTH];
  logic           line_done_pulse [PIPELINE_WIDTH];

  // debayer filter signals
  logic           line_valid_sync3 [PIPELINE_WIDTH];
  logic           line_valid_sync2 [PIPELINE_WIDTH];
  logic [3:0]     rgb_data_valid [PIPELINE_WIDTH];
  logic [119:0]   rgb_data [PIPELINE_WIDTH];

  for(genvar i=0; i<PIPELINE_WIDTH; i++) begin: ipu_gen

    //////////////////
    // Flow Control //
    //////////////////
    
    //* The flow control configuration registers can be dynamically changed during runtime however
    //* When reading a line you don't want to mix different virtual channels or different datatypes
    //* In the same line buffer so separate these into different flow controls for each isp pipeline
    
    assign byte_data_valid[i]       = (activate_stream_i [i])? byte_data_valid_i:4'd0;
    assign line_valid_sync_fake[i]  = (activate_stream_i [i])? line_valid_sync_fake_i:1'd0;

    ipu_flow_control ipu_flow_control_i (
      // Clocks and Reset
      .byte_reset_n_i        (byte_reset_n_i),
      .byte_clk_i            (byte_clk_i),
      .pixel_reset_n_i       (pixel_reset_n_i),
      .pixel_clk_i           (pixel_clk_i),

      // Configuration Interface
      .pixel_per_clk_i       (pixel_per_clk_reg_i[i]),
      .data_type_i           (data_type_reg_i[i]),

      // Data Interface
      .line_valid_i          (line_valid_i[i]),
      .frame_valid_i         (frame_valid_i[i]),
      .line_valid_sync_fake_i(line_valid_sync_fake[i]),
      .byte_data_valid_i     (byte_data_valid[i]),
      .byte_data_i           (byte_data_i),
      .dst_clear_pending_o   (dst_clear_pending[i]),
      .src_clear_pending_o   (src_clear_pending[i]),
      .line_valid_sync_o     (line_valid_pixel_sync_o[i]),
      .line_done_pulse_o     (line_done_pulse[i]),
      .frame_valid_sync_o    (frame_valid_sync[i]),
      .pixel_data_valid_o    (pixel_data_valid[i]),
      .pixel_data_o          (pixel_data_o[i]),
      .byte_valid_o          (pixel_byte_valid_o[i])
    );

    ////////////////////
    // Debayer Filter //
    ////////////////////

    ipu_debayer_filter ipu_debayer_filter_i (
      // Clocks and Reset
      .reset_n_i           (pixel_reset_n_i),
      .clk_i               (pixel_clk_i),

      // Configuration Interface
      .data_type_i         (data_type_reg_i[i]),
      .pixel_per_clk_i     (pixel_per_clk_reg_i[i]),
      .bayer_filter_type_i (bayer_filter_type_reg_i[i]),

      // Data Interface
      .frame_valid_i       (frame_valid_sync[i]),
      .line_valid_i        (line_valid_pixel_sync_o[i]),
      .line_done_pulse_i   (line_done_pulse[i]),
      .line_valid_sync_o   (line_valid_sync2[i]),
      .pixel_data_i        (pixel_data_o[i]),
      .pixel_data_valid_i  (pixel_data_valid[i]),
      .pixel_data_valid_o  (rgb_data_valid[i]),
      .pixel_data_o        (rgb_data[i]),
      .frame_done_pulse_o  (frame_done_pulse_o[i])
    );

    //////////////////////
    // Color Conversion //
    //////////////////////

    ipu_color_conversion ipu_color_conversion_i (
      // Clocks and Reset
      .reset_n_i           (pixel_reset_n_i),
      .pixel_clk_i         (pixel_clk_i),

      // Configuration Interface
      .pixel_per_clk_i     (pixel_per_clk_reg_i[i]),
      .data_type_i         (data_type_reg_i[i]),

      // Data Interface
      .line_valid_i        (line_valid_sync2[i]),
      .line_valid_sync_o   (line_valid_yuv_sync_o[i]),
      .rgb_data_valid_i    (rgb_data_valid[i]),
      .rgb_data_i          (rgb_data[i]),
      .yuv_byte_valid_o    (yuv422_byte_valid_o[i]),
      .yuv_data_o          (yuv422_data_o[i])
    );

  end: ipu_gen

endmodule