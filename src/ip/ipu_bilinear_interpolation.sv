// -----------------------------------------------------------------------------
// Module: ipu_bilinear_interpolation
// Description:
//   Implements bilinear interpolation for Bayer-patterned image data. Supports
//   RAW8 and RAW10 data types with single, dual, or quad pixels per clock.
//   The module calculates RGB components for each pixel based on the Bayer
//   filter type (RGGB, BGGR, GBRG, GRBG).
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------

`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11

`include "mipi_csi_data_types.svh"
`include "rgb_locate.svh"

`define SHIFT_PIPELINE_3STAGE(DATA, QPIPE, DPIPE) \
  begin \
    DPIPE.pixel_data_q  = DATA; \
    DPIPE.pixel_data_q2 = QPIPE.pixel_data_q; \
    DPIPE.pixel_data_q3 = QPIPE.pixel_data_q2; \
  end

module ipu_bilinear_interpolation #(
  parameter DataWidth = 40,
  parameter ValidWidth = 4
) (
  input  logic                        clk_i,
  input  logic                        reset_n_i,
  input  logic [5:0]                  data_type_i,             // RAW8 or RAW10
  input  logic [2:0]                  pixel_per_clk_i,         // single, dual or quad
  input  logic [1:0]                  bayer_filter_type_i,     // RGGB(00), BGGR(01), GBRG(10), GRBG(11)
  input  logic [2:0][DataWidth+ValidWidth-1:0] pixel_line_i,
  input  logic                        line_done_pulse_i,
  input  logic                        line_counter_i,
  input  logic                        pipe_stall_i,
  input  logic [1:0]                  read_reg_index_i,        // which line RAM is being focused to read for even lines
  input  logic [1:0]                  read_reg_index_plus_1_i,
  input  logic [1:0]                  read_reg_index_minus_1_i,
  output logic                        line_done_pulse_o,
  output logic [3:0]                  pixel_data_valid_o,      // Each bit corresponds to one RGB component of pixel_data_o
  output logic [119:0]                pixel_data_o             // Max RGB components = 3*PPC_max*PIXELWIDTH_max = 3*4*10 = 120
);

  // Pixel width parameters
  localparam int PixelWidth    = 10;
  localparam int PixelWidth10  = 10;
  localparam int PixelWidth8   = 8;

  // type definition
  typedef struct packed {
    logic [(4*10)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_4ppc_raw10_t;

  typedef struct packed {
    logic [(2*10)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_2ppc_raw10_t;

  typedef struct packed {
    logic [(1*10)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_1ppc_raw10_t;

  typedef struct packed {
    logic [(4*8)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_4ppc_raw8_t;

  typedef struct packed {
    logic [(2*8)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_2ppc_raw8_t;

  typedef struct packed {
    logic [(1*8)-1:0] pixel_data_q,
        pixel_data_q2,
        pixel_data_q3;
  } reg_pipe_1ppc_raw8_t;

  typedef struct packed {
    logic [3:0] pixel_valid_q,
        pixel_valid_q2,
        pixel_valid_q3;
  } reg_pipe_valids_t;

  typedef struct packed {
    logic [PixelWidth-1:0]  r;
    logic [PixelWidth-1:0]  g;
    logic [PixelWidth-1:0]  b;
  } rgb_color_t;

  typedef struct {
    rgb_color_t rgb0[4];
    rgb_color_t rgb1[4];
    rgb_color_t rgb2[4];
    rgb_color_t rgb3[4];
  } rgb_4by4_t;

  // RAM output and valid signals
  reg_pipe_valids_t reg_pipe_valids[2:0];

  // RAW10 RAM output signals
  reg_pipe_4ppc_raw10_t reg_pipe_4ppc_raw10_d[2:0],
      reg_pipe_4ppc_raw10_q[2:0],
      reg_pipe_4ppc_raw10_q2[2:0];

  reg_pipe_2ppc_raw10_t reg_pipe_2ppc_raw10_d[2:0],
      reg_pipe_2ppc_raw10_q[2:0],
      reg_pipe_2ppc_raw10_q2[2:0];

  reg_pipe_1ppc_raw10_t reg_pipe_1ppc_raw10_d[2:0],
      reg_pipe_1ppc_raw10_q[2:0],
      reg_pipe_1ppc_raw10_q2[2:0];

  // RAW8 RAM output signals
  reg_pipe_4ppc_raw8_t reg_pipe_4ppc_raw8_d[2:0],
      reg_pipe_4ppc_raw8_q[2:0],
      reg_pipe_4ppc_raw8_q2[2:0];

  reg_pipe_2ppc_raw8_t reg_pipe_2ppc_raw8_d[2:0],
      reg_pipe_2ppc_raw8_q[2:0],
      reg_pipe_2ppc_raw8_q2[2:0];

  reg_pipe_1ppc_raw8_t reg_pipe_1ppc_raw8_d[2:0],
      reg_pipe_1ppc_raw8_q[2:0],
      reg_pipe_1ppc_raw8_q2[2:0];

  // RGB component arrays
  rgb_4by4_t rgb_4by4_array;
  rgb_4by4_t rgb_4by4_array_even;
  rgb_4by4_t rgb_4by4_array_odd;

  // RAM pipeline signals
  logic [(DataWidth*3)-1:0] reg_pipe [2:0];

  // Miscellaneous signals
  logic [1:0] not_used2b;
  int input_width;
  int pixel_width;
  logic odd_signal;
  logic [3:0] pixel_data_valid_q;
  logic [3:0] pixel_data_valid_q2;
  logic line_done_pulse_q;
  logic line_done_pulse_q2;
  logic line_done_pulse_q3;
  logic line_done_pulse_q4;
  logic line_done_pulse_q5;
  logic [ValidWidth-1:0] reg_pipe_valids_q [2:0];
  logic [ValidWidth-1:0] reg_pipe_valids_q2 [2:0];
  logic [ValidWidth-1:0] reg_pipe_valids_q3 [2:0];
  logic [ValidWidth-1:0] reg_pipe_valids_q4;
  logic [ValidWidth-1:0] reg_pipe_valids_q5;

  // Pipeline registers for RAM outputs and valid signals
  always_comb begin
    for (int j=0; j<3; j++) begin
      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][39:0], reg_pipe_4ppc_raw10_q[j], reg_pipe_4ppc_raw10_d[j]);
      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][19:0], reg_pipe_2ppc_raw10_q[j], reg_pipe_2ppc_raw10_d[j]);
      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][9:0],  reg_pipe_1ppc_raw10_q[j], reg_pipe_1ppc_raw10_d[j]);

      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][31:0], reg_pipe_4ppc_raw8_q[j], reg_pipe_4ppc_raw8_d[j]);
      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][15:0], reg_pipe_2ppc_raw8_q[j], reg_pipe_2ppc_raw8_d[j]);
      `SHIFT_PIPELINE_3STAGE(pixel_line_i[j][7:0],  reg_pipe_1ppc_raw8_q[j], reg_pipe_1ppc_raw8_d[j]);
    end
  end

  // Pipeline registers for RAM outputs and valid signals, following lowRISC style
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_done_pulse_q   <= 1'b0;
      line_done_pulse_q2  <= 1'b0;

      for (int j = 0; j < 3; j++) begin
        reg_pipe_valids_q[j]        <= '0;
        reg_pipe_valids_q2[j]       <= '0;
        reg_pipe_4ppc_raw10_q[j]    <= '{default: '0};
        reg_pipe_4ppc_raw10_q2[j]   <= '{default: '0};
        reg_pipe_2ppc_raw10_q[j]    <= '{default: '0};
        reg_pipe_2ppc_raw10_q2[j]   <= '{default: '0};
        reg_pipe_1ppc_raw10_q[j]    <= '{default: '0};
        reg_pipe_1ppc_raw10_q2[j]   <= '{default: '0};
        reg_pipe_4ppc_raw8_q[j]     <= '{default: '0};
        reg_pipe_4ppc_raw8_q2[j]    <= '{default: '0};
        reg_pipe_2ppc_raw8_q[j]     <= '{default: '0};
        reg_pipe_2ppc_raw8_q2[j]    <= '{default: '0};
        reg_pipe_1ppc_raw8_q[j]     <= '{default: '0};
        reg_pipe_1ppc_raw8_q2[j]    <= '{default: '0};
      end
    end else if (!pipe_stall_i) begin
      line_done_pulse_q   <= line_done_pulse_i;
      line_done_pulse_q2  <= line_done_pulse_q;

      for (int j = 0; j < 3; j++) begin
        reg_pipe_valids_q[j]        <= pixel_line_i[j][DataWidth +: ValidWidth];
        reg_pipe_valids_q2[j]       <= reg_pipe_valids_q[j];
        reg_pipe_4ppc_raw10_q[j]    <= reg_pipe_4ppc_raw10_d[j];
        reg_pipe_4ppc_raw10_q2[j]   <= reg_pipe_4ppc_raw10_q[j];
        reg_pipe_2ppc_raw10_q[j]    <= reg_pipe_2ppc_raw10_d[j];
        reg_pipe_2ppc_raw10_q2[j]   <= reg_pipe_2ppc_raw10_q[j];
        reg_pipe_1ppc_raw10_q[j]    <= reg_pipe_1ppc_raw10_d[j];
        reg_pipe_1ppc_raw10_q2[j]   <= reg_pipe_1ppc_raw10_q[j];
        reg_pipe_4ppc_raw8_q[j]     <= reg_pipe_4ppc_raw8_d[j];
        reg_pipe_4ppc_raw8_q2[j]    <= reg_pipe_4ppc_raw8_q[j];
        reg_pipe_2ppc_raw8_q[j]     <= reg_pipe_2ppc_raw8_d[j];
        reg_pipe_2ppc_raw8_q2[j]    <= reg_pipe_2ppc_raw8_q[j];
        reg_pipe_1ppc_raw8_q[j]     <= reg_pipe_1ppc_raw8_d[j];
        reg_pipe_1ppc_raw8_q2[j]    <= reg_pipe_1ppc_raw8_q[j];
      end
    end
  end

  // Pipeline register for pixel data, following lowRISC style
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      for (int j = 0; j < 3; j++) begin
        reg_pipe[j] <= '0;
      end
    end else begin
      for (int j = 0; j < 3; j++) begin
        unique case ({pixel_per_clk_i, data_type_i})
          {3'd4, `RAW10}: reg_pipe[j] <= reg_pipe_4ppc_raw10_q2[j];
          {3'd2, `RAW10}: reg_pipe[j] <= {60'd0, reg_pipe_2ppc_raw10_q2[j]};
          {3'd1, `RAW10}: reg_pipe[j] <= {90'd0, reg_pipe_1ppc_raw10_q2[j]};
          {3'd4, `RAW8} : reg_pipe[j] <= {24'd0, reg_pipe_4ppc_raw8_q2[j]};
          {3'd2, `RAW8} : reg_pipe[j] <= {72'd0, reg_pipe_2ppc_raw8_q2[j]};
          {3'd1, `RAW8} : reg_pipe[j] <= {96'd0, reg_pipe_1ppc_raw8_q2[j]};
          default:        reg_pipe[j] <= '0;
        endcase
      end
    end
  end

  assign rgb_4by4_array = (line_counter_i) ? rgb_4by4_array_odd : rgb_4by4_array_even;

  // Output pixel data logic, following lowRISC SystemVerilog style guidelines
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      not_used2b    <= '0;
      odd_signal    <= 1'b1;
      pixel_data_o  <= '0;
    end else begin
      pixel_data_o <= '0; // Default to zero for unused pixels

      // Update odd_signal based on pixel_data_valid_o
      if (pixel_data_valid_o != 0)
        odd_signal <= ~odd_signal;
      else
        odd_signal <= 1'b1;

      for (int i = 0; i < 4; i++) begin
        if (pixel_per_clk_i != 1) begin
          if (pixel_per_clk_i > i) begin
            {not_used2b, pixel_data_o[((i * (PixelWidth * 3)) + (PixelWidth * 2)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[i].r} + rgb_4by4_array.rgb1[i].r + rgb_4by4_array.rgb2[i].r + rgb_4by4_array.rgb3[i].r) >> 2);
            {not_used2b, pixel_data_o[((i * (PixelWidth * 3)) + PixelWidth) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[i].g} + rgb_4by4_array.rgb1[i].g + rgb_4by4_array.rgb2[i].g + rgb_4by4_array.rgb3[i].g) >> 2);
            {not_used2b, pixel_data_o[(i * (PixelWidth * 3)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[i].b} + rgb_4by4_array.rgb1[i].b + rgb_4by4_array.rgb2[i].b + rgb_4by4_array.rgb3[i].b) >> 2);
          end
        end else begin
          if (!odd_signal) begin
            {not_used2b, pixel_data_o[((0 * (PixelWidth * 3)) + (PixelWidth * 2)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[0].r} + rgb_4by4_array.rgb1[0].r + rgb_4by4_array.rgb2[0].r + rgb_4by4_array.rgb3[0].r) >> 2);
            {not_used2b, pixel_data_o[((0 * (PixelWidth * 3)) + PixelWidth) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[0].g} + rgb_4by4_array.rgb1[0].g + rgb_4by4_array.rgb2[0].g + rgb_4by4_array.rgb3[0].g) >> 2);
            {not_used2b, pixel_data_o[(0 * (PixelWidth * 3)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[0].b} + rgb_4by4_array.rgb1[0].b + rgb_4by4_array.rgb2[0].b + rgb_4by4_array.rgb3[0].b) >> 2);
          end else begin
            {not_used2b, pixel_data_o[((0 * (PixelWidth * 3)) + (PixelWidth * 2)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[1].r} + rgb_4by4_array.rgb1[1].r + rgb_4by4_array.rgb2[1].r + rgb_4by4_array.rgb3[1].r) >> 2);
            {not_used2b, pixel_data_o[((0 * (PixelWidth * 3)) + PixelWidth) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[1].g} + rgb_4by4_array.rgb1[1].g + rgb_4by4_array.rgb2[1].g + rgb_4by4_array.rgb3[1].g) >> 2);
            {not_used2b, pixel_data_o[(0 * (PixelWidth * 3)) +: PixelWidth]} <=
              (({2'b0, rgb_4by4_array.rgb0[1].b} + rgb_4by4_array.rgb1[1].b + rgb_4by4_array.rgb2[1].b + rgb_4by4_array.rgb3[1].b) >> 2);
          end
        end
      end
    end
  end

  // Set input_width and pixel_width according to pixel_per_clk_i and data_type_i, following lowRISC style
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      input_width <= 0;
      pixel_width <= 0;
    end else begin
      unique case ({pixel_per_clk_i, data_type_i})
        {3'd4, `RAW10}: input_width <= 40;
        {3'd2, `RAW10}: input_width <= 20;
        {3'd1, `RAW10}: input_width <= 10;
        {3'd4, `RAW8} : input_width <= 32;
        {3'd2, `RAW8} : input_width <= 16;
        {3'd1, `RAW8} : input_width <= 8;
        default:        input_width <= 0;
      endcase
      pixel_width <= (data_type_i == `RAW10) ? 10 :
                    (data_type_i == `RAW8)  ?  8 : 10;
    end
  end

  // Pipeline registers for valid signals and line done pulse, following lowRISC SystemVerilog style
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      reg_pipe_valids_q3   <= '{default: '0};
      reg_pipe_valids_q4   <= '0;
      reg_pipe_valids_q5   <= '0;
      pixel_data_valid_o   <= '0;
      line_done_pulse_q3   <= 1'b0;
      line_done_pulse_q4   <= 1'b0;
      line_done_pulse_q5   <= 1'b0;
      line_done_pulse_o    <= 1'b0;
    end else begin
      line_done_pulse_q3 <= line_done_pulse_q2;
      line_done_pulse_q4 <= line_done_pulse_q3;
      line_done_pulse_q5 <= line_done_pulse_q4;
      line_done_pulse_o  <= line_done_pulse_q5;

      for (int j = 0; j < 3; j++) begin
        reg_pipe_valids_q3[j] <= (!pipe_stall_i) ? reg_pipe_valids_q2[j] : 4'h0;
      end

      reg_pipe_valids_q4 <= reg_pipe_valids_q3[read_reg_index_i];
      reg_pipe_valids_q5 <= reg_pipe_valids_q4;
      pixel_data_valid_o <= reg_pipe_valids_q5;
    end
  end

/*
The R,G and B components are calculated for each pixel using this combinational block.
    First the bayer method used is the bilinear method in which the RGB components are the average of the surrounding components
    To locate these surrounding components depending on the bayer pattern a certain location pattern can be formed. For example
    RGGB odd line has a green components which has 2 reds on the left and right pixels and 2 blues on the upper and lower pixel
    indicated by the "x" and "y" input to the `RGB_LOCATE() directive. The "." means that the green component is the
    same pixel we are working on so we don't take an average for that. Accordingly, "xy" means that we take the average of the
    upper, lower, left and right pixels. While the "uv" means that we take the average of the corner pixels.
    This method has been used as it is safe and easy to verify.

The odd and even components are calculated for each pixel without regards to its location however the correct component is futher
    sampled using the line number in a later stage.

The for loop is used to calculated 4 pixels concurrently. However it is futher sampled based on the PPC settings and the non needed
    pixels are discarded
*/

  // RGB calculation pipeline, following lowRISC SystemVerilog style guidelines
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      for (int i = 0; i < 4; i++) begin
        rgb_4by4_array_even.rgb0[i] <= '{default: '0};
        rgb_4by4_array_even.rgb1[i] <= '{default: '0};
        rgb_4by4_array_even.rgb2[i] <= '{default: '0};
        rgb_4by4_array_even.rgb3[i] <= '{default: '0};
        rgb_4by4_array_odd.rgb0[i]  <= '{default: '0};
        rgb_4by4_array_odd.rgb1[i]  <= '{default: '0};
        rgb_4by4_array_odd.rgb2[i]  <= '{default: '0};
        rgb_4by4_array_odd.rgb3[i]  <= '{default: '0};
      end
    end else begin
      unique case (bayer_filter_type_i)
        `RGGB: begin
          for (int i = 0; i < 3; i += 2) begin
            // Odd line pixels
            rgb_4by4_array_odd.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "x");
            rgb_4by4_array_odd.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "x");
            rgb_4by4_array_odd.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "x");
            rgb_4by4_array_odd.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "x");

            rgb_4by4_array_odd.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_odd.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_odd.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_odd.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_odd.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "y");
            rgb_4by4_array_odd.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "y");
            rgb_4by4_array_odd.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "y");
            rgb_4by4_array_odd.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "y");

            rgb_4by4_array_odd.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_odd.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_odd.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_odd.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");

            rgb_4by4_array_odd.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "xy");
            rgb_4by4_array_odd.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "xy");
            rgb_4by4_array_odd.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "xy");
            rgb_4by4_array_odd.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "xy");

            rgb_4by4_array_odd.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "uv");
            rgb_4by4_array_odd.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "uv");
            rgb_4by4_array_odd.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "uv");
            rgb_4by4_array_odd.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "uv");
          end

          for (int i = 0; i < 3; i += 2) begin
            // Even line pixels
            rgb_4by4_array_even.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "uv");
            rgb_4by4_array_even.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "uv");
            rgb_4by4_array_even.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "uv");
            rgb_4by4_array_even.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "uv");

            rgb_4by4_array_even.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "xy");
            rgb_4by4_array_even.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "xy");
            rgb_4by4_array_even.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "xy");
            rgb_4by4_array_even.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "xy");

            rgb_4by4_array_even.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_even.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_even.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_even.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_even.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "y");
            rgb_4by4_array_even.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "y");
            rgb_4by4_array_even.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "y");
            rgb_4by4_array_even.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "y");

            rgb_4by4_array_even.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_even.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_even.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_even.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");

            rgb_4by4_array_even.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "x");
            rgb_4by4_array_even.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "x");
            rgb_4by4_array_even.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "x");
            rgb_4by4_array_even.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "x");
          end
        end

        `BGGR: begin
          for (int i = 0; i < 4; i += 2) begin
            // Odd line pixels
            rgb_4by4_array_odd.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "y");
            rgb_4by4_array_odd.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "y");
            rgb_4by4_array_odd.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "y");
            rgb_4by4_array_odd.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "y");

            rgb_4by4_array_odd.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_odd.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_odd.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_odd.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_odd.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "x");
            rgb_4by4_array_odd.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "x");
            rgb_4by4_array_odd.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "x");
            rgb_4by4_array_odd.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "x");

            rgb_4by4_array_odd.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "uv");
            rgb_4by4_array_odd.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "uv");
            rgb_4by4_array_odd.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "uv");
            rgb_4by4_array_odd.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "uv");

            rgb_4by4_array_odd.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "xy");
            rgb_4by4_array_odd.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "xy");
            rgb_4by4_array_odd.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "xy");
            rgb_4by4_array_odd.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "xy");

            rgb_4by4_array_odd.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_odd.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_odd.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_odd.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");
          end

          for (int i = 0; i < 4; i += 2) begin
            // Even line pixels
            rgb_4by4_array_even.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_even.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_even.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_even.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_even.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "xy");
            rgb_4by4_array_even.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "xy");
            rgb_4by4_array_even.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "xy");
            rgb_4by4_array_even.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "xy");

            rgb_4by4_array_even.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "uv");
            rgb_4by4_array_even.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "uv");
            rgb_4by4_array_even.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "uv");
            rgb_4by4_array_even.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "uv");

            rgb_4by4_array_even.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "x");
            rgb_4by4_array_even.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "x");
            rgb_4by4_array_even.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "x");
            rgb_4by4_array_even.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "x");

            rgb_4by4_array_even.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_even.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_even.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_even.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");

            rgb_4by4_array_even.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "y");
            rgb_4by4_array_even.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "y");
            rgb_4by4_array_even.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "y");
            rgb_4by4_array_even.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "y");
          end
        end

        `GBRG: begin
          for (int i = 0; i < 3; i += 2) begin
            // Odd line pixels
            rgb_4by4_array_odd.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "uv");
            rgb_4by4_array_odd.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "uv");
            rgb_4by4_array_odd.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "uv");
            rgb_4by4_array_odd.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "uv");

            rgb_4by4_array_odd.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "xy");
            rgb_4by4_array_odd.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "xy");
            rgb_4by4_array_odd.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "xy");
            rgb_4by4_array_odd.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "xy");

            rgb_4by4_array_odd.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_odd.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_odd.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_odd.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_odd.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "y");
            rgb_4by4_array_odd.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "y");
            rgb_4by4_array_odd.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "y");
            rgb_4by4_array_odd.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "y");

            rgb_4by4_array_odd.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_odd.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_odd.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_odd.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");

            rgb_4by4_array_odd.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "x");
            rgb_4by4_array_odd.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "x");
            rgb_4by4_array_odd.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "x");
            rgb_4by4_array_odd.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "x");
          end

          for (int i = 0; i < 3; i += 2) begin
            // Even line pixels
            rgb_4by4_array_even.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "x");
            rgb_4by4_array_even.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "x");
            rgb_4by4_array_even.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "x");
            rgb_4by4_array_even.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "x");

            rgb_4by4_array_even.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_even.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_even.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_even.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_even.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "y");
            rgb_4by4_array_even.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "y");
            rgb_4by4_array_even.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "y");
            rgb_4by4_array_even.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "y");

            rgb_4by4_array_even.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "uv");
            rgb_4by4_array_even.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "uv");
            rgb_4by4_array_even.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "uv");
            rgb_4by4_array_even.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "uv");

            rgb_4by4_array_even.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "xy");
            rgb_4by4_array_even.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "xy");
            rgb_4by4_array_even.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "xy");
            rgb_4by4_array_even.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "xy");

            rgb_4by4_array_even.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_even.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_even.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_even.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");
          end
        end

        `GRBG: begin
          for (int i = 0; i < 3; i += 2) begin
            // Odd line pixels
            rgb_4by4_array_odd.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_odd.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_odd.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_odd.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_odd.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "xy");
            rgb_4by4_array_odd.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "xy");
            rgb_4by4_array_odd.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "xy");
            rgb_4by4_array_odd.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "xy");

            rgb_4by4_array_odd.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "uv");
            rgb_4by4_array_odd.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "uv");
            rgb_4by4_array_odd.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "uv");
            rgb_4by4_array_odd.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "uv");

            rgb_4by4_array_odd.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "x");
            rgb_4by4_array_odd.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "x");
            rgb_4by4_array_odd.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "x");
            rgb_4by4_array_odd.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "x");

            rgb_4by4_array_odd.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_odd.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_odd.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_odd.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");

            rgb_4by4_array_odd.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "y");
            rgb_4by4_array_odd.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "y");
            rgb_4by4_array_odd.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "y");
            rgb_4by4_array_odd.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "y");
          end

          for (int i = 0; i < 3; i += 2) begin
            // Even line pixels
            rgb_4by4_array_even.rgb0[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "y");
            rgb_4by4_array_even.rgb1[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "y");
            rgb_4by4_array_even.rgb2[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "y");
            rgb_4by4_array_even.rgb3[i+1].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "y");

            rgb_4by4_array_even.rgb0[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, ".");
            rgb_4by4_array_even.rgb1[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, ".");
            rgb_4by4_array_even.rgb2[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, ".");
            rgb_4by4_array_even.rgb3[i+1].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, ".");

            rgb_4by4_array_even.rgb0[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 1, "x");
            rgb_4by4_array_even.rgb1[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 2, "x");
            rgb_4by4_array_even.rgb2[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 3, "x");
            rgb_4by4_array_even.rgb3[i+1].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i+1, 4, "x");

            rgb_4by4_array_even.rgb0[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "uv");
            rgb_4by4_array_even.rgb1[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "uv");
            rgb_4by4_array_even.rgb2[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "uv");
            rgb_4by4_array_even.rgb3[i].r <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "uv");

            rgb_4by4_array_even.rgb0[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, "xy");
            rgb_4by4_array_even.rgb1[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, "xy");
            rgb_4by4_array_even.rgb2[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, "xy");
            rgb_4by4_array_even.rgb3[i].g <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, "xy");

            rgb_4by4_array_even.rgb0[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 1, ".");
            rgb_4by4_array_even.rgb1[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 2, ".");
            rgb_4by4_array_even.rgb2[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 3, ".");
            rgb_4by4_array_even.rgb3[i].b <= `RGB_LOCATE(input_width, pixel_width, read_reg_index_minus_1_i, read_reg_index_plus_1_i, read_reg_index_i, i, 4, ".");
          end
        end
      endcase
    end
  end
endmodule