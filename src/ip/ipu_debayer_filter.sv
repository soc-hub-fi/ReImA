//---------------------------------------------------------------------------------
// Module: ipu_debayer_filter
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// References: Gaurav Singh www.CircuitValley.com
// Functionality:
//  Extended from Gaurav Singh implementation for debayer filter
//  Support RAW10 and RAW8 data type debayering
//  Support 1, 2 or 4 Pixel Per clock input and output
//  Support RGGB, BGGR, RGBG, GRBG bayering filters to support different camera modules
//  Input characteristics: incase of RAW10 data type input is 4 pixels per cycle and input
//  for example in case of BGGR formatorder should be GBGB in case of odd rows and 
//  RGRG in case of even rows, where LSByte is the first pixel transmitted and MSByte is the last pixel transmitted.
//  Output should be at the same throughtput as input
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//---------------------------------------------------------------------------------
module ipu_debayer_filter (
  input  logic              clk_i,
  input  logic              reset_n_i,
  input  logic [5:0]        data_type_i,          // RAW8 or RAW10
  input  logic [2:0]        pixel_per_clk_i,      // single, dual or quad
  input  logic [1:0]        bayer_filter_type_i,  // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
  input  logic              frame_valid_i,        // High during frame transmission
  input  logic              line_valid_i,         // High during line transmission
  input  logic              line_done_pulse_i,
  input  logic [95:0]       pixel_data_i,         // Pixel data (max 5 bytes for RAW10)
  input  logic [3:0]        pixel_data_valid_i,   // Valid signal for each byte in pixel_data_i
  output logic              line_valid_sync_o,    // Synchronized line_valid signal
  output logic [3:0]        pixel_data_valid_o,   // Valid signal for each RGB component in pixel_data_o
  output logic [119:0]      pixel_data_o,         // RGB components (max 3*PPC_max*PIXELWIDTH_max = 120 bits)
  output logic              frame_done_pulse_o
);
  // Parameters
  localparam AddrWidth = 11;
  localparam DataWidth = 40;
  localparam ValidWidth = 4;
  localparam [1:0] p0 [8] = {0,0,0,2,2,1,1,0}; // pointer to map ram outputs0 to pipe inputs
  localparam [1:0] p1 [8] = {2,2,1,1,0,0,2,2}; // pointer to map ram outputs1 to pipe inputs
  localparam [1:0] p2 [8] = {1,1,2,0,1,2,0,1}; // pointer to map ram outputs2 to pipe inputs

 // Internal signals
  logic [(DataWidth + ValidWidth)-1:0] pixel_data_trun_d, 
      pixel_data_trun_q, 
      pixel_data_trun_q2;
  logic line_counter; //only 1 bit so does not actually counts lines of the frame , needed determine if line is odd or even
  logic line_valid_q;
  logic [1:0] read_ram_index; 	//which line RAM is being focused to read for even lines,  (not which address is being read from line RAM) Must be 2 bits only
  logic [1:0] read_ram_index_plus_1;
  logic [1:0] read_ram_index_minus_1;
  logic [1:0] write_ram_select;	//which line RAM is begin written
  logic [AddrWidth-1:0] line_address_wr_q, 
      line_address_rd_q,
      line_address_wr_q2; 		//which address is being read and written 
  logic [1:0] [(DataWidth+ValidWidth-1):0] reg_out;
  logic [2:0] [(DataWidth+ValidWidth-1):0] reg_out_mapped;
  logic [1:0] ram_write_enable;
  logic line_valid_negedge;
  logic frame_done_pulse_pending;
  logic [2:0] idx;
  logic last_line_read_done;
  logic line_active, line_active_corrected;
  logic pipe_stall;
  logic line_done_pulse_q,
      line_done_pulse_q2;    
  logic line_done_pulse_sync;
  logic line_valid_sync;

  typedef enum logic [1:0] {Idle, OneLineFilled, OneLineExtract} line_state_e;
  line_state_e line_state_q, 
      line_state_q2,
      line_state_q3;

  assign ram_write_enable = (|(pixel_data_trun_q2[DataWidth +:ValidWidth]))? write_ram_select: 2'b00; // bug solved

  assign pixel_data_trun_d = {pixel_data_valid_i, pixel_data_i[DataWidth-1:0]};

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_active <= 1'b0;
    end else begin
      if (pixel_data_valid_i) begin
        line_active <= 1'b1;
      end else if (line_done_pulse_q) begin
        line_active <= 1'b0;
      end
    end
  end

  always_ff@(posedge clk_i, negedge reset_n_i) begin
      if(!reset_n_i)
          line_valid_sync <= 0;
      else begin
          if(line_state_q != Idle) begin
              if(pixel_data_valid_i)
                  line_valid_sync <= 1;
              else if(line_done_pulse_sync)
                  line_valid_sync <= 0;
          end
      end
  end

  assign line_valid_sync_o = line_valid_sync | (|pixel_data_valid_o);
  assign line_active_corrected = line_active | pixel_data_valid_i;

  // Stall pipe when line didn't end and valid = 0, or when line 1 isn't filled yet
  assign pipe_stall = (line_active_corrected && 
              (!pixel_data_trun_q2[DataWidth +: ValidWidth])) || 
              (line_state_q3 == Idle);
              
  // The 4 buffer lines store pixel data input for further debayer processing, debayering needs at least 2 lines and atmost 3 lines to start. A line buffer can't be read and written at the same time.
  mem_dual_port_wrapper #(
    .AddrWidth    (AddrWidth),
    .DataWidth    (DataWidth + ValidWidth),
    .MEM_NUM      (2)
  ) mem_dual_port_wrapper_i (
    .reset_n_i              (reset_n_i),
    .clk_i                  (clk_i),
    .ram_write_enable_i     (ram_write_enable),
    .ram_read_enable_i      (2'b11),
    .ram_write_address_i    (line_address_wr_q),
    .ram_data_i             (pixel_data_trun_q2),
    .ram_read_address_i     (line_address_rd_q),
    .ram_data_o             (reg_out)
  );

  assign line_valid_negedge = !line_valid_i & line_valid_q;

  // FSM for output valid control
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_state_q  <= Idle;
      line_state_q2 <= Idle;
      line_state_q3 <= Idle;
    end else begin
      case (line_state_q)
        Idle: begin
          if (line_done_pulse_q2) begin
            line_state_q <= OneLineFilled;
          end
        end
        OneLineFilled: begin
          if (!frame_valid_i) begin
            line_state_q <= OneLineExtract;
          end
        end
        OneLineExtract: begin
          if (last_line_read_done) begin
            line_state_q <= Idle;
          end
        end
      endcase
      line_state_q2 <= line_state_q;
      line_state_q3 <= line_state_q2;
    end
  end

  assign last_line_read_done = (line_state_q == OneLineExtract) && 
                  (line_address_rd_q >= line_address_wr_q2);

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_address_rd_q       <= '0;
      line_valid_q        <= 1'b0;
      pixel_data_trun_q     <= '0;
      pixel_data_trun_q2    <= '0;
      line_done_pulse_q <= 1'b0;
      line_done_pulse_q2 <= 1'b0;
    end else begin
      line_valid_q        <= line_valid_i;
      pixel_data_trun_q     <= pixel_data_trun_d;
      pixel_data_trun_q2    <= pixel_data_trun_q;

      line_done_pulse_q <= line_done_pulse_i;
      line_done_pulse_q2 <= line_done_pulse_q;

      // Line address read logic
      if (line_done_pulse_i || frame_done_pulse_o) begin
        line_address_rd_q   <= '0;
      end else if (pixel_data_valid_i || (line_state_q == OneLineExtract)) begin
        line_address_rd_q   <= line_address_rd_q + 1'b1;
      end
    end
  end

  assign frame_done_pulse_o = frame_done_pulse_pending && !line_valid_sync_o;

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      frame_done_pulse_pending <= 1'b0;
    end else begin
      if (frame_done_pulse_o) begin
        frame_done_pulse_pending <= 1'b0;
      end else if (last_line_read_done) begin
        frame_done_pulse_pending <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_address_wr_q <= 1;
      line_address_wr_q2 <= 0;
    end else begin
      if ((!line_valid_i && line_valid_q) || line_done_pulse_q2) begin
        line_address_wr_q <= 1;
        line_address_wr_q2 <= line_address_wr_q;
      end else if (pixel_data_trun_q2[DataWidth +: ValidWidth]) begin
        line_address_wr_q <= line_address_wr_q + 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      write_ram_select         <= 2'b01;  // On first line, ram[0] will be selected
      line_counter             <= 1'b1;  // On first line, line_counter --> 1 --> odd
      read_ram_index           <= 2'd0;  // On first line, read from ram 2 (1 + 1 at rising edge of line_valid_i)
      read_ram_index_plus_1    <= 2'd1;
      read_ram_index_minus_1   <= 2'd2;
    end else begin
      if (line_valid_negedge || line_done_pulse_i) begin
        write_ram_select <= {write_ram_select[0], write_ram_select[1]};
      end

      if (line_state_q == Idle) begin
        read_ram_index         <= 2'd0;  // On first line, read from ram 2 (1 + 1 at rising edge of line_valid_i)
        read_ram_index_plus_1  <= 2'd1;
        read_ram_index_minus_1 <= 2'd2;
        line_counter           <= 1'b1;
      end else if (line_done_pulse_sync) begin  // Current line out is done
        line_counter           <= ~line_counter;
        read_ram_index         <= (read_ram_index + 1'b1) % 3;
        read_ram_index_plus_1  <= (read_ram_index_plus_1 + 1'b1) % 3;
        read_ram_index_minus_1 <= (read_ram_index_minus_1 + 1'b1) % 3;
      end
    end
  end
  //************** Mapping logic
  // p0 [8] = {0,0,0,2,2,1,1,0,0};
  // p1 [8] = {2,2,1,1,0,0,2,2,1};
  // p2 [8] = {1,1,2,0,1,2,0,1,2};
  always_comb begin
    reg_out_mapped[p0[idx]] = reg_out[0];
    reg_out_mapped[p1[idx]] = reg_out[1];
    reg_out_mapped[p2[idx]] = pixel_data_trun_q2;
  end

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      idx <= 3'd0;
    end else begin
      if (line_done_pulse_q2) begin
        idx <= idx + 1'b1;
        if (idx == 3'd7) begin
          idx <= 3'd2;
        end
      end else if (line_state_q == Idle) begin
        idx <= 3'd0;
      end
    end
  end

  //*************
  ipu_bilinear_interpolation #(
    .DataWidth(DataWidth),
    .ValidWidth(ValidWidth)
  ) u_ipu_bilinear_interpolation (
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .data_type_i(data_type_i),
    .pixel_per_clk_i(pixel_per_clk_i),
    .bayer_filter_type_i(bayer_filter_type_i),
    .pixel_line_i(reg_out_mapped),
    .line_done_pulse_i(line_done_pulse_q2),
    .line_counter_i(line_counter),
    .pipe_stall_i(pipe_stall),
    .read_reg_index_i(read_ram_index),
    .read_reg_index_plus_1_i(read_ram_index_plus_1),
    .read_reg_index_minus_1_i(read_ram_index_minus_1),
    .line_done_pulse_o(line_done_pulse_sync),
    .pixel_data_valid_o(pixel_data_valid_o),
    .pixel_data_o(pixel_data_o)
  );

`ifndef SYNTHESIS
  // Define the counter
  integer outcounter;
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      outcounter <= 0;
    end else begin
      if (line_done_pulse_sync) begin
        outcounter <= 0;
      end else if (pixel_data_valid_o) begin
        outcounter <= outcounter + 1;
      end
    end
  end
`endif
endmodule