//---------------------------------------------------------------------------------
// Module: ipu_flow_control
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// Functionality:
//  Programmable module to control the number of pixels per clock sent to the ISP modules
//  Support YUV422_8, RGB888, RGB565, RAW8, RAW10 datatypes
//  Includes an Async FIFO to separate the byte clock domain and the pixel clock domain
//  pixel_clk_i needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
//  byte_clk_i is usually 1/8 of the line rate coming from the DPHY
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//---------------------------------------------------------------------------------
`include "mipi_csi_data_types.svh"
module ipu_flow_control (
  input  logic            byte_reset_n_i,             // Active low reset for the byte clock domain
  input  logic            byte_clk_i,                 // Byte clock usually 1/8 of the line rate coming from the DPHY
  input  logic            pixel_reset_n_i,            // Active low reset for the pixel clock domain
  input  logic            pixel_clk_i,                // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
  input  logic  [2:0]     pixel_per_clk_i,            // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
  input  logic  [5:0]     data_type_i,                // Video data type such as RGB, RAW..etc
  input  logic            line_valid_i,               // Line valid in from short packet decoding
  input  logic            frame_valid_i,              // Frame valid in from short packet decoding
  input  logic            line_valid_sync_fake_i,
  input  logic  [47:0]    byte_data_i,                // Max width is 2 RGB888 pixels 2*24 = 48
  input  logic  [3:0]     byte_data_valid_i,          // Pixel data valid signal for each pixel in the pixel data

  output logic            dst_clear_pending_o,        // Clear pending signal for the CDC FIFO
  output logic            src_clear_pending_o,        // Clear pending signal for the CDC FIFO
  output logic            line_done_pulse_o,
  output logic            line_valid_sync_o,          // Line valid signal synchronized with the output data because of buffering delay
  output logic            frame_valid_sync_o,         // Frame valid signal synchronized with the output data because of the buffering delay
  output logic  [95:0]    pixel_data_o,               // Depending on the datatype some of the bits might not be used. Maximum Width(RGB888) = (8+8+8) * 4 = 96
  output logic  [3:0]     pixel_data_valid_o,         // Each bit corresponds to a pixel in the pixel_data_o port
  output logic  [11:0]    byte_valid_o                // Providing byte valid for flexibility
);

  // Parameter definitions
  parameter int YUV422Width = 16;
  parameter int RGB888Width = 24;
  parameter int RGB565Width = 16;
  parameter int RAW8Width = 8;
  parameter int RAW10Width = 10;

  // Internal signals
  logic pipe_extract;
  logic pipe_insert;
  logic [4:0] pixel_counter;
  logic [4:0] empty_space;
  logic [3:0] num_of_valids;
  logic [191:0] pixel_data;
  logic [3:0] pixel_data_valid;
  logic line_valid_negedge;
  logic line_valid_posedge;
  logic line_valid_q;
  logic frame_valid_negedge;
  logic frame_valid_posedge;
  logic frame_valid_q;
  logic byte_data_valid_negedge;
  logic line_valid_sync_fake_q;
  logic line_code_operative;
  logic line_done_pulse;
  logic line_done_latch;
  logic [51:0] fifo_wrdata;
  logic fifo_wincr;

  // Byte valid signals for different data types
  logic [11:0] byte_valid_yuv422;
  logic [11:0] byte_valid_rgb888;
  logic [11:0] byte_valid_rgb565;
  logic [11:0] byte_valid_raw8;
  logic [11:0] byte_valid_raw10;

  // Pixel data pipes
  logic [6 * YUV422Width - 1:0] yuv422_pipe;
  logic [6 * RGB888Width - 1:0] rgb888_pipe;
  logic [6 * RGB565Width - 1:0] rgb565_pipe;
  logic [6 * RAW8Width - 1:0] raw8_pipe;
  logic [6 * RAW10Width - 1:0] raw10_pipe;

  // FIFO signals
  logic fifo_rvalid;
  logic [51:0] fifo_data;
  logic ram_valid;

  // Synchronization signals
  logic line_valid_sync_q;
  logic line_done_pulse_q;

  // Debug counter
  logic [31:0] debug_counter;

  typedef enum logic [2:0] {
    FrameValid, 
    LineValid, 
    LineInvalid, 
    FrameInvalid
  } sync_state_e;
  sync_state_e sync_state;
    
    

  assign pixel_data[191:48] = '0;

  // Line_valid and frame_valid signals encoding logic.
  // A line valid negedge is encoded as zero valids in the line buffer and a line valid posedge is encoded as 4 valids.
  // A frame valid negedge is encoded as zero valids in the line buffer and a frame valid posedge is encoded as 4 valids.
  assign line_valid_negedge     = ~line_valid_i & line_valid_q;
  assign line_valid_posedge     = line_valid_i & ~line_valid_q;
  assign frame_valid_negedge    = ~frame_valid_i & frame_valid_q;
  assign frame_valid_posedge    = frame_valid_i & ~frame_valid_q;
  assign byte_data_valid_negedge = ~line_valid_sync_fake_i & line_valid_sync_fake_q;

  always_ff @(posedge byte_clk_i or negedge byte_reset_n_i) begin
    if (!byte_reset_n_i) begin
      line_valid_q            <= 1'b0;
      frame_valid_q           <= 1'b0;
      line_valid_sync_fake_q  <= 1'b0;
      line_code_operative     <= 1'b0;
    end else begin
      if (line_valid_posedge) begin
        line_code_operative <= 1'b1;
      end
      line_valid_sync_fake_q <= line_valid_sync_fake_i;
      line_valid_q           <= line_valid_i;
      frame_valid_q          <= frame_valid_i;
    end
  end

  assign fifo_wrdata = (frame_valid_posedge || line_valid_posedge) ? 
                       52'h0000_0000_0000_f : 
                       (frame_valid_negedge || line_valid_negedge || byte_data_valid_negedge) ? 
                       52'h0000_0000_0000_0 : 
                       {byte_data_i, byte_data_valid_i};

  assign fifo_wincr = frame_valid_posedge || 
                      frame_valid_negedge || 
                      line_valid_posedge || 
                      line_valid_negedge || 
                      byte_data_valid_negedge || 
                      (|byte_data_valid_i);

    //! We need some calculations for the fifo depth here
  (* KEEP_HIERARCHY = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  cdc_fifo_gray_clearable #(
    // The width of the default logic type.
    .WIDTH                  (52),
    // The FIFO's depth given as 2**LOG_DEPTH.
    .LOG_DEPTH              (4),
    .SYNC_STAGES            (4),
    .CLEAR_ON_ASYNC_RESET   (1)
  ) u_cdc_fifo_gray_clearable (
    .src_rst_ni             (byte_reset_n_i),
    .src_clk_i              (byte_clk_i),
    .src_clear_i            (1'b0),  // Use reset for clear
    .src_clear_pending_o    (src_clear_pending_o),  // Send to status register
    .src_data_i             (fifo_wrdata),
    .src_valid_i            (fifo_wincr),
    .src_ready_o            (),  // Not throttle_ram_full

    .dst_rst_ni             (pixel_reset_n_i),
    .dst_clk_i              (pixel_clk_i),
    .dst_clear_i            (1'b0),  // Use reset for clear
    .dst_clear_pending_o    (dst_clear_pending_o),
    .dst_data_o             (fifo_data),  // 52 bits
    .dst_valid_o            (fifo_rvalid),  // Not empty
    .dst_ready_i            (1'b1)  // Always ready to accept data
  );

  assign {pixel_data[47:0], pixel_data_valid} = fifo_data;

  // Pixel counter tracks the number of pixels available in the pipe
  always_ff @(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
    if (!pixel_reset_n_i) begin
      pixel_counter <= 5'd0;
    end else begin
      // Pixel counter logic takes 1 cycle
      if (pipe_insert && pipe_extract) begin
        pixel_counter <= num_of_valids + pixel_counter - pixel_per_clk_i;
      end else if (pipe_insert) begin
        pixel_counter <= num_of_valids + pixel_counter;
      end else if (pipe_extract) begin
        pixel_counter <= pixel_counter - pixel_per_clk_i;
      end
    end
  end

  assign empty_space    = pipe_extract ? (pixel_counter - pixel_per_clk_i) : pixel_counter;
  assign ram_valid      = fifo_rvalid; // Trial signal
  assign num_of_valids  = pixel_data_valid[3] + pixel_data_valid[2] + pixel_data_valid[1] + pixel_data_valid[0];
  assign pipe_extract   = (pixel_counter >= pixel_per_clk_i); // Add stall here
  assign pipe_insert    = (ram_valid && (sync_state == FrameValid) && (pixel_data_valid != 4'h0));

  always_ff @(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
    if (!pixel_reset_n_i) begin
      frame_valid_sync_o <= 1'b0;
      sync_state <= FrameInvalid;
      line_valid_sync_q <= 1'b0;
      line_done_latch <= 1'b0;
    end else begin
      if (line_done_pulse) begin
        line_done_latch <= 1'b1;
      end else if (ram_valid && (pixel_data_valid == 4'hF)) begin
        line_done_latch <= 1'b0;
      end

      case (sync_state)
        FrameInvalid: begin
          frame_valid_sync_o <= 1'b0;
          if (ram_valid && (pixel_data_valid == 4'hF)) begin
            sync_state <= FrameValid;
          end
        end

        FrameValid: begin
          frame_valid_sync_o <= 1'b1;
          if (ram_valid && (pixel_data_valid == 4'hF) && 1'b0) begin
            sync_state <= LineValid;
          end else if (ram_valid && (pixel_data_valid == 4'h0) && line_done_latch) begin
            sync_state <= FrameInvalid;
          end
        end

        LineValid: begin
          line_valid_sync_q <= 1'b1;
          if (ram_valid && (pixel_data_valid == 4'h0)) begin
            sync_state <= LineInvalid;
          end
        end

        LineInvalid: begin
          line_valid_sync_q <= 1'b0;
          if (ram_valid && (pixel_data_valid == 4'hF)) begin
            sync_state <= LineValid;
          end else if (ram_valid && (pixel_data_valid == 4'h0)) begin
            sync_state <= FrameInvalid;
          end
        end
      endcase
    end
  end

  assign line_done_pulse = ~line_done_latch & ram_valid & (pixel_data_valid == 4'h0) & (sync_state == FrameValid);

  // Fill the pipe when insert signal is high and empty it when extract is high
  always_ff @(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
    if (!pixel_reset_n_i) begin
      yuv422_pipe <= '0;
      rgb888_pipe <= '0;
      rgb565_pipe <= '0;
      raw8_pipe   <= '0;
      raw10_pipe  <= '0;
    end else begin
      if (pipe_insert) begin
        for (int i = 0; i < 4; i++) begin
          if (pixel_data_valid[i]) begin
            yuv422_pipe[(i + empty_space) * YUV422Width +: YUV422Width] <= 
              pixel_data[i * YUV422Width +: YUV422Width];
            rgb888_pipe[(i + empty_space) * RGB888Width +: RGB888Width] <= 
              pixel_data[i * RGB888Width +: RGB888Width];
            rgb565_pipe[(i + empty_space) * RGB565Width +: RGB565Width] <= 
              pixel_data[i * RGB565Width +: RGB565Width];
            raw8_pipe[(i + empty_space) * RAW8Width +: RAW8Width] <= 
              pixel_data[i * RAW8Width +: RAW8Width];
            raw10_pipe[(i + empty_space) * RAW10Width +: RAW10Width] <= 
              pixel_data[i * RAW10Width +: RAW10Width];
          end
        end
      end else if (pipe_extract) begin
        yuv422_pipe <= yuv422_pipe >> ({6'd0, pixel_per_clk_i} * YUV422Width);
        rgb888_pipe <= rgb888_pipe >> ({6'd0, pixel_per_clk_i} * RGB888Width);
        rgb565_pipe <= rgb565_pipe >> ({6'd0, pixel_per_clk_i} * RGB565Width);
        raw8_pipe   <= raw8_pipe >> ({6'd0, pixel_per_clk_i} * RAW8Width);
        raw10_pipe  <= raw10_pipe >> ({6'd0, pixel_per_clk_i} * RAW10Width);
      end
    end
  end

  assign byte_valid_yuv422 = pipe_extract ? 
    (pixel_per_clk_i == 4 ? 12'b0000_1111_1111 : 
      pixel_per_clk_i == 2 ? 12'b0000_0000_1111 : 
      pixel_per_clk_i == 1 ? 12'b0000_0000_0011 : 
                12'b0000_0000_0000) : 
    12'b0000_0000_0000;

  assign byte_valid_rgb888 = pipe_extract ? 
    (pixel_per_clk_i == 4 ? 12'b1111_1111_1111 : 
      pixel_per_clk_i == 2 ? 12'b0000_0011_1111 : 
      pixel_per_clk_i == 1 ? 12'b0000_0000_0111 : 
                12'b0000_0000_0000) : 
    12'b0000_0000_0000;

  assign byte_valid_rgb565 = pipe_extract ? 
    (pixel_per_clk_i == 4 ? 12'b0000_1111_1111 : 
      pixel_per_clk_i == 2 ? 12'b0000_0000_1111 : 
      pixel_per_clk_i == 1 ? 12'b0000_0000_0011 : 
                12'b0000_0000_0000) : 
    12'b0000_0000_0000;

  assign byte_valid_raw8 = pipe_extract ? 
    (pixel_per_clk_i == 4 ? 12'b0000_0000_1111 : 
      pixel_per_clk_i == 2 ? 12'b0000_0000_0011 : 
      pixel_per_clk_i == 1 ? 12'b0000_0000_0001 : 
                12'b0000_0000_0000) : 
    12'b0000_0000_0000;

  assign byte_valid_raw10 = pipe_extract ? 
    (pixel_per_clk_i == 4 ? 12'b0000_0000_1111 : 
      pixel_per_clk_i == 2 ? 12'b0000_0000_0011 : 
      pixel_per_clk_i == 1 ? 12'b0000_0000_0001 : 
                12'b0000_0000_0000) : 
    12'b0000_0000_0000;

  always_ff @(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
    if (!pixel_reset_n_i) begin
      pixel_data_o         <= '0;
      pixel_data_valid_o   <= '0;
      byte_valid_o         <= '0;
      line_valid_sync_o    <= '0;
      line_done_pulse_o    <= '0;
      line_done_pulse_q    <= '0;
    end else begin
      line_done_pulse_q    <= line_done_pulse;
      line_done_pulse_o    <= line_done_pulse_q;
      line_valid_sync_o    <= line_valid_sync_q;
      pixel_data_o         <= '0;
      byte_valid_o         <= (data_type_i == `YUV422_8) ? byte_valid_yuv422 :
                              (data_type_i == `RGB888)   ? byte_valid_rgb888 :
                              (data_type_i == `RGB565)   ? byte_valid_rgb565 :
                              (data_type_i == `RAW8)     ? byte_valid_raw8 :
                              (data_type_i == `RAW10)    ? byte_valid_raw10 : 12'd0;
      pixel_data_valid_o   <= pipe_extract ? ((pixel_per_clk_i == 4) ? 4'b1111 :
                                              (pixel_per_clk_i == 2) ? 4'b0011 :
                                              (pixel_per_clk_i == 1) ? 4'b0001 : 4'b0000) : 4'b0000;
      case (data_type_i)
        `YUV422_8: pixel_data_o <= {32'd0, yuv422_pipe};  // 64 bits
        `RGB888:   pixel_data_o <= {rgb888_pipe};         // 96 bits
        `RGB565:   pixel_data_o <= {32'd0, rgb565_pipe};  // 64 bits
        `RAW8:     pixel_data_o <= {64'd0, raw8_pipe};    // 32 bits
        `RAW10:    pixel_data_o <= {56'd0, raw10_pipe};   // 40 bits
        default:   pixel_data_o <= '0;
      endcase
    end
  end

//TODO: Make an assert statement to compare the outputs and the inputs
//TODO: Make an assert statemnt for Timeout pixels
`ifndef ASIC
  `ifndef FPGA
    always_ff @(posedge byte_clk_i or negedge byte_reset_n_i) begin
      if (!byte_reset_n_i) begin
        debug_counter <= 0;
      end else begin
        if (!frame_valid_i) begin
          debug_counter <= 0;
        end else if (|byte_data_valid_i) begin
          debug_counter <= debug_counter + 1;
        end
      end
    end

    // Define the counter
    integer valid_in_c;
    integer valid_in_r;
    logic line_valid_sync_r2;
    integer valid_o_c;

    always_ff @(posedge byte_clk_i or negedge byte_reset_n_i) begin
      if (!byte_reset_n_i) begin
        valid_in_c <= 0;
      end else begin
        if (line_valid_posedge || (!line_valid_sync_fake_i && line_valid_sync_fake_q)) begin
          valid_in_c <= 0;
          valid_in_r <= valid_in_c;
        end else begin
          valid_in_c <= valid_in_c + byte_data_valid_i[3] + byte_data_valid_i[2] +
                        byte_data_valid_i[1] + byte_data_valid_i[0];
        end
      end
    end

    // Reset the counter when transitioning between states
    always_ff @(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
      if (!pixel_reset_n_i) begin
        valid_o_c <= 0;
        line_valid_sync_r2 <= 0;
      end else begin
        line_valid_sync_r2 <= line_valid_sync_o;
        if ((line_valid_sync_o && !line_valid_sync_r2) || line_done_pulse_o) begin
          valid_o_c <= 0;
        end else begin
          valid_o_c <= valid_o_c + pixel_data_valid_o[3] + pixel_data_valid_o[2] +
                       pixel_data_valid_o[1] + pixel_data_valid_o[0];
        end
      end
    end

    // Define properties for the assertions
    property ineqout_val;
      @(posedge pixel_clk_i)
      (pixel_data_valid_o) |-> 
        (pixel_data_o[19:0] == $past(byte_data_i[19:0], 10)) || 
        (pixel_data_o[19:0] == $past(byte_data_i[19:0], 9)) || 
        (pixel_data_o[19:0] == $past(byte_data_i[19:0], 8)) || 
        (pixel_data_o[19:0] == $past(byte_data_i[39:20], 10)) || 
        (pixel_data_o[19:0] == $past(byte_data_i[39:20], 9)) || 
        (pixel_data_o[19:0] == $past(byte_data_i[39:20], 8));
    endproperty

    assert property (ineqout_val) else 
      $fatal("Assertion failed (flow control): output doesn't match input, output = %h, input = %h",
             pixel_data_o[19:0], $past(byte_data_i[19:0], 9));

  `endif
`endif
endmodule