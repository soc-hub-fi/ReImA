// Module: cu_depacker
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// References: According to MIPI CSI RX specs v1.01

// Functionality:
//  Input should look like this (demonstration only)
//  Lane 0-----data_i[0]-----  <ECC>               <data3, Y2> ..
//  Lane 1-----data_i[1]-----  <WCount MSByte>     <data2, V1> ..
//  Lane 2-----data_i[2]-----  <WCount LSByte>     <data1, Y1> ..
//  Lane 3-----data_i[3]-----  <DataID>            <data0, U1> ..

//  Payload data type can be YUV422-8bit, RGB888, RGB656, RAW8 or RAW10
//  The number of active lanes must be 1, 2 or 4 lanes
//  The module takes in csi2 packets and sends pixel formatted data
//  Incase of YUV422-8bit, RGB888, RGB656, RAW8 data type no bit re-ordering is needed only insures that
//  the output is in the form of complete pixels
//  Incase of raw10, bit re-ordering is needed
//  Each data type has its own depacking logic
//  RAW10 always goes out in 5 bytes format because it is specified in the specs that the minimum replicated unit is 5 bytes long
//  YUV422 goes out in 4 bytes format
//  Others differ in the number of pixels per cycle
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>

`include "mipi_csi_data_types.svh"

module cu_depacker (
  input                   clk_i,
  input                   reset_n_i,
  input           [2:0]   active_lanes_i,             // Active lanes coming from config register can be 1, 2, or 4 lanes active
  input           [5:0]   data_type_i,                // Video data type such as RGB, RAW, etc.
  input   logic   [7:0]   payload_data_i      [4],    // MIPI data 8 bits wide, 4 data lanes
  input   logic           payload_valid_i     [4],    // Valid signal for each lane
  output  logic           line_valid_sync_fake_o,     // Fake line valid for non-line code transfers
  output  logic   [47:0]  byte_data_o,                // Max width is 2 RGB888 pixels: 2 * 24 = 48
  output  logic   [3:0]   byte_data_valid_o           // Pixel data valid signal for each pixel in the pixel data
);

  logic [7:0]  payload_data_r       [4];  // Mipi data 8 bits wide 4 data lanes
  logic        payload_valid_r      [4];
  logic [7:0]  payload_data_r2      [4];
  logic        payload_valid_r2     [4];
  logic        counter_reset;
  logic [2:0]  counter_reset_value;
  logic [2:0]  event_counter;
  logic [31:0] yuv422_pixels;
  logic        yuv422_counter_reset;
  logic        yuv422_pixels_valid;
  logic [2:0]  yuv422_reset_value;
  logic [47:0] rgb888_pixels_4lanes;
  logic [47:0] rgb888_pixels_2lanes;
  logic [47:0] rgb888_pixels_1lanes;
  logic [47:0] rgb888_pixels;
  logic        rgb888_counter_reset;
  logic        rgb888_pixels_valid;
  logic [2:0]  rgb888_reset_value;
  logic [31:0] rgb565_pixels;
  logic [5:0]  rgb888_pixels_4lanes_valid;
  logic [5:0]  rgb888_pixels_2lanes_valid;
  logic [5:0]  rgb888_pixels_1lanes_valid;
  logic [5:0]  rgb565_valid_num_bytes;
  logic [3:0]  rgb565_valid_num_pixels;
  logic [2:0]  rgb565_counter_limit;
  logic        rgb565_counter_reset;
  logic        rgb565_pixels_valid;
  logic [2:0]  rgb565_reset_value;
  logic [31:0] raw8_pixels;
  logic [3:0]  raw8_valid_num;
  logic        raw8_counter_reset;
  logic        raw8_pixels_valid;
  logic [2:0]  raw8_reset_value;
  logic [4:0]  index_lsb;
  logic [39:0] raw10_pixels;
  logic [2:0]  raw10_counter_limit;
  logic [2:0]  raw10_reset_value;
  logic        raw10_counter_reset;
  logic        raw10_pixels_valid;
  logic [63:0] data_pipe_r;
  logic [5:0]  valid_pipe_r;
  logic [5:0]  rgb888_valid_num_bytes;
  logic [3:0]  rgb888_valid_num_pixels;
  logic [2:0]  num_of_valids;
  logic [2:0]  num_of_valids_r;
  logic [5:0]  data_type_r;

  assign transmission_active = payload_valid_i[0] | payload_valid_i[1] | payload_valid_i[2] | payload_valid_i[3];
  assign num_of_valids = payload_valid_i[0] + payload_valid_i[1] + payload_valid_i[2] + payload_valid_i[3];

  always_ff @(posedge clk_i or negedge reset_n_i) begin
      if (!reset_n_i) begin
          event_counter <= 0;
      end else begin
          if (!transmission_active) begin
              event_counter <= 0;
          end else if (counter_reset) begin
              event_counter <= counter_reset_value;
          end else if (transmission_active) begin
              event_counter <= event_counter + 1;
          end
      end
  end

  always_ff @(posedge clk_i or negedge reset_n_i) begin
      if (!reset_n_i) begin
          data_pipe_r <= 0;
          valid_pipe_r <= 0;
          num_of_valids_r <= 0;
          data_type_r <= 0;
      end else begin
          num_of_valids_r <= num_of_valids;
          data_type_r <= data_type_i;
          if (transmission_active) begin
              data_pipe_r <= data_pipe_r << (num_of_valids * 8); // shifted by the amount of data available each cycle
              valid_pipe_r <= (valid_pipe_r << (num_of_valids)); // shifted by the amount of data available each cycle    
          end
          for (int i = 0; i < 4; i++) begin
              if (payload_valid_i[i]) begin
                  data_pipe_r[(i * 8 - (4 - active_lanes_i) * 8 - (active_lanes_i - num_of_valids) * 8) +: 8] <= payload_data_i[i]; // pipeline range allocated for the data is a function of the number of active lanes
                  valid_pipe_r[(i - (4 - active_lanes_i))] <= 1; // pipeline range allocated for the data is a function of the number of active lanes
              end
          end
          if (counter_reset) begin
              valid_pipe_r <= 0;
          end
      end
  end

  always_ff @(posedge clk_i or negedge reset_n_i) begin
      if (!reset_n_i) begin
          for (int i = 0; i < 4; i++) begin
              payload_data_r[i] <= 0;
              payload_data_r2[i] <= 0;
              payload_valid_r[i] <= 0;
              payload_valid_r2[i] <= 0;
          end
      end else begin
          for (int i = 0; i < 4; i++) begin
              payload_data_r[i] <= payload_data_i[i];
              payload_data_r2[i] <= payload_data_r[i];
              payload_valid_r[i] <= payload_valid_i[i];
              payload_valid_r2[i] <= payload_valid_r[i];
          end
      end
  end

  assign line_valid_sync_fake_o = payload_valid_r2[3] | payload_valid_r2[2] | payload_valid_r2[1] | payload_valid_r2[0]; // fake line valid for non line code transfers

  // YUV422 depacking logic
  // * YUV output, The output is always 2 pixels(4 bytes) in all cases of active channels. The input is also always multiple of 2 pixels.
  assign yuv422_pixels = data_pipe_r[31:0];
  assign yuv422_counter_reset = (event_counter == unsigned'(3'd4 >> active_lanes_i[2:1])); // each time limit comes valid is high and counter resets yuv422
  assign yuv422_pixels_valid = yuv422_counter_reset;
  assign yuv422_reset_value = 1;

  // RGB888 depacking logic
  assign rgb888_pixels_4lanes = (event_counter == 1) ? {24'd0, payload_data_r[1], payload_data_r[2], payload_data_r[3]} : 
                                (event_counter == 2) ? {24'd0, payload_data_r[2], payload_data_r[3], payload_data_r2[0]} : 
                                (event_counter == 3) ? {payload_data_r[0], payload_data_r[1], payload_data_r[2], payload_data_r[3], payload_data_r2[0], payload_data_r2[1]} : 
                                48'd0;
  assign rgb888_pixels_2lanes = (event_counter == 2) ? {24'd0, payload_data_r[3], payload_data_r2[2], payload_data_r2[3]} : 
                                (event_counter == 3) ? {24'd0, payload_data_r[2], payload_data_r[3], payload_data_r2[2]} : 
                                48'd0;
  assign rgb888_pixels_1lanes = (event_counter == 3) ? {{24'd0, {data_pipe_r[0 +: 8], data_pipe_r[8 +: 8], data_pipe_r[16 +: 8]}}} : 
                                48'd0;
  assign rgb888_pixels = (active_lanes_i == 4) ? rgb888_pixels_4lanes : 
                        (active_lanes_i == 2) ? rgb888_pixels_2lanes : 
                        rgb888_pixels_1lanes;
  assign rgb888_pixels_4lanes_valid = (event_counter == 1) ? {3'd0, payload_valid_r[1], payload_valid_r[2], payload_valid_r[3]} : 
                                      (event_counter == 2) ? {3'd0, payload_valid_r[2], payload_valid_r[3], payload_valid_r2[0]} : 
                                      (event_counter == 3) ? {payload_valid_r[0], payload_valid_r[1], payload_valid_r[2], payload_valid_r[3], payload_valid_r2[0], payload_valid_r2[1]} : 
                                      6'd0;
  assign rgb888_pixels_2lanes_valid = (event_counter == 2) ? {3'd0, payload_valid_r[3], payload_valid_r2[2], payload_valid_r2[3]} : 
                                      (event_counter == 3) ? {3'd0, payload_valid_r[2], payload_valid_r[3], payload_valid_r2[2]} : 
                                      6'd0;
  assign rgb888_pixels_1lanes_valid = 6'b000111;
  assign rgb888_valid_num_bytes = (active_lanes_i == 4) ? rgb888_pixels_4lanes_valid : 
                                  (active_lanes_i == 2) ? rgb888_pixels_2lanes_valid : 
                                  rgb888_pixels_1lanes_valid;
  assign rgb888_valid_num_pixels = (rgb888_valid_num_bytes == 6'b111111) ? 4'b0011 : 
                                  (rgb888_valid_num_bytes == 6'b000111) ? 4'b0001 : 
                                  4'b0000;
  assign rgb888_counter_reset = (event_counter == 3);
  assign rgb888_pixels_valid = (active_lanes_i == 4) ? (event_counter == 1 || event_counter == 2 || event_counter == 3) : 
                              (active_lanes_i == 2) ? (event_counter == 2 || event_counter == 3) : 
                              (active_lanes_i == 1) ? (event_counter == 3) : 
                              1'b0;
  assign rgb888_reset_value = 3'd1;

  // RGB565 depacking logic
  assign rgb565_pixels = (active_lanes_i == 4 || active_lanes_i == 2) ? {payload_data_r[0], payload_data_r[1], payload_data_r[2], payload_data_r[3]} : 
                        {16'd0, data_pipe_r[7:0], data_pipe_r[15:8]};
  assign rgb565_valid_num_bytes = (active_lanes_i == 4 || active_lanes_i == 2) ? {2'b00, payload_valid_r[0], payload_valid_r[1], payload_valid_r[2], payload_valid_r[3]} : 
                                  {4'd0, 2'b11};
  assign rgb565_valid_num_pixels = (rgb565_valid_num_bytes == 6'b001111) ? 4'b0011 : 
                                  (rgb565_valid_num_bytes == 6'b000011) ? 4'b0001 : 
                                  4'b0000;
  assign rgb565_counter_limit = (active_lanes_i == 4) ? 3'd1 : 
                                (active_lanes_i == 2) ? 3'd1 : 
                                (active_lanes_i == 1) ? 3'd2 : 
                                3'd0;
  assign rgb565_counter_reset = (event_counter == rgb565_counter_limit);
  assign rgb565_pixels_valid = rgb565_counter_reset;
  assign rgb565_reset_value = 3'd1;

  // RAW8 depacking logic
  assign raw8_pixels = {payload_data_r[0], payload_data_r[1], payload_data_r[2], payload_data_r[3]};
  assign raw8_valid_num = {payload_valid_r[0], payload_valid_r[1], payload_valid_r[2], payload_valid_r[3]};
  assign raw8_counter_reset = (event_counter == 1);
  assign raw8_pixels_valid = raw8_counter_reset;
  assign raw8_reset_value = 3'd1;

  // RAW10 depacking logic
  // index = 24 16 8 0
  assign index_lsb = (active_lanes_i == 4) ? ((5'd5 - event_counter) << 3) - ((5'd4 - num_of_valids_r) << 3) : 
                    (active_lanes_i == 2 && event_counter == 3) ? 5'd8 - ((5'd2 - num_of_valids_r) << 3) : 
                    5'd0;
  assign raw10_pixels = {data_pipe_r[index_lsb + 8 +: 8], data_pipe_r[index_lsb + 6 +: 2], data_pipe_r[index_lsb + 16 +: 8], data_pipe_r[index_lsb + 4 +: 2], data_pipe_r[index_lsb + 24 +: 8], data_pipe_r[index_lsb + 2 +: 2], data_pipe_r[index_lsb + 32 +: 8], data_pipe_r[index_lsb + 0 +: 2]};
  assign raw10_counter_limit = (active_lanes_i == 4) ? 3'd5 : 
                              (active_lanes_i == 2) ? 3'd7 : 
                              (active_lanes_i == 1) ? 3'd5 : 
                              3'd0;
  assign raw10_reset_value = (active_lanes_i == 4) ? 3'd1 : 
                            (active_lanes_i == 2) ? 3'd3 : 
                            (active_lanes_i == 1) ? 3'd1 : 
                            3'd0;
  assign raw10_counter_reset = (event_counter == raw10_counter_limit);
  assign raw10_pixels_valid = (active_lanes_i == 4) ? (event_counter != 0 && event_counter != 1) : 
                              (active_lanes_i == 2) ? ((event_counter == 3) | (event_counter == 5)) : 
                              (active_lanes_i == 1) ? (event_counter == 5) : 
                              1'b0;

  always_comb begin
      byte_data_o = 48'd0;
      byte_data_valid_o = 4'd0;
      counter_reset = 1'b0;
      counter_reset_value = 1'b0;
      case (data_type_r)
          `YUV422_8: begin
              byte_data_o = {16'd0, yuv422_pixels}; // 32 bit
              byte_data_valid_o = yuv422_pixels_valid ? 4'b0011 : 4'b000; // the output will always be 4 bytes
              counter_reset = yuv422_counter_reset;
              counter_reset_value = yuv422_reset_value;
          end
          `RGB888: begin
              byte_data_o = rgb888_pixels; // 48 bit
              byte_data_valid_o = rgb888_pixels_valid ? rgb888_valid_num_pixels : 4'b0000;
              counter_reset = rgb888_counter_reset;
              counter_reset_value = rgb888_reset_value;
          end
          `RGB565: begin
              byte_data_o = {16'd0, rgb565_pixels}; // 32
              byte_data_valid_o = rgb565_pixels_valid ? rgb565_valid_num_pixels : 4'b0000;
              counter_reset = rgb565_counter_reset;
              counter_reset_value = rgb565_reset_value;
          end
          `RAW8: begin
              byte_data_o = {16'd0, raw8_pixels}; // 32
              byte_data_valid_o = raw8_pixels_valid ? raw8_valid_num : 4'b0000;
              counter_reset = raw8_counter_reset;
              counter_reset_value = raw8_reset_value;
          end
          `RAW10: begin
              byte_data_o = {8'd0, raw10_pixels}; // 40
              byte_data_valid_o = raw10_pixels_valid ? 4'b1111 : 4'b0000; // the output will always be 4 pixels
              counter_reset = raw10_counter_reset;
              counter_reset_value = raw10_reset_value;
          end
          default: begin
              byte_data_o = {16'd0, yuv422_pixels}; // 32 bit
              byte_data_valid_o = yuv422_pixels_valid ? 4'b0011 : 4'b000; // the output will always be 4 bytes
              counter_reset = yuv422_counter_reset;
              counter_reset_value = yuv422_reset_value;
          end
      endcase
  end

endmodule