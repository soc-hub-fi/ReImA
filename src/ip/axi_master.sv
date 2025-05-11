//------------------------------------------------------------------------------
// Module : axi_master
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// References: MIPI CSI RX specs v1.01

// Functionality: 
// -   converts yuv422 input to yuv420 by buffering Y,U and V channels in separate buffers and sending Y transaction then U then V and so on
//     because they are located in different memory locations.
// -   This module is made specifically for integration with AXI mast interface for that reason but other interfaces can work as well
// -   The module includes 6 memories 3 are being written while 3 are being read, each memory corresponds to Y U or V channel
// -   For YUV450 The module works only for PPC=2 as it leads to the maximum throughput possible for the system due to AXI 32bit interface constraint
// -   Inputs can also be preprocessed pixels coming from flow control block which are saved in 2 buffers one for reading and one for writing in a time
// -   Other pixel formats to be supported later
// Authors: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//------------------------------------------------------------------------------
`include "axi/typedef.svh"
module axi_master #(
  parameter int unsigned AXI_ID_WIDTH    = 32'd0,
  parameter int unsigned AXI_ADDR_WIDTH  = 32'd0,
  parameter int unsigned AXI_DATA_WIDTH  = 32'd0,
  parameter int unsigned AXI_USER_WIDTH  = 32'd0,
  parameter type         full_req_t      = logic,
  parameter type         full_resp_t     = logic
) (
  // Clock and Reset Interface
  input  logic                          reset_n_i,
  input  logic                          pixel_clk_i,

  // Data Interface
  input  logic                          frame_done_pulse_i,
  output logic                          stream_stall_o,
  input  logic                          line_valid_pixel_i,      // Line valid high signal, remains high even if stalled
  input  logic [95:0]                   pixel_data_i,            // Pixel data input from flow control
  input  logic [11:0]                   pixel_byte_valid_i,      // Pixel byte data valid from flow control
  input  logic                          line_valid_yuv_i,        // Line valid high signal, remains high even if stalled
  input  logic [63:0]                   yuv422_data_i,           // YUV422 from rgb2yuv block
  input  logic [7:0]                    yuv422_byte_valid_i,     // Valid bit for each byte in the data interface

  // Configuration Interface
  input  logic                          double_buff_enable_reg_i, // Enable double buffering; when disabled, only frame_ptr0_i is selected
  input  logic [11:0]                   frame_width_i,            // Frame width for AW pointer calculation
  input  logic [11:0]                   frame_height_i,           // Frame height for AW pointer calculation
  input  logic [AXI_ADDR_WIDTH-1:0]     frame_ptr0_i,             // Frame pointer 0 for AW write
  input  logic [AXI_ADDR_WIDTH-1:0]     frame_ptr1_i,             // Frame pointer 1 for AW write
  input  logic                          csi_enable_i,             // Should be toggled high after configuration done
  input  logic                          output_select_i,          // Select output: 1 for yuv420, 0 for pixel data

  // AXI Address Write Interface
  output full_req_t                     mst_req_o,                // Master request
  input  full_resp_t                    mst_resp_i,               // Master response

  // Interrupt
  output logic                          frame_wr_done_intr_o
);
  // YUV signal declarations (lowRISC style)
  // YUV part
  logic         posedge_line_valid;
  logic         line_valid_reg;
  logic         odd_line;
  logic         odd_line_latched;

  // Y RAM signals
  logic [7:0]   y_buffer_addr [2];
  logic         y_buffer_wen  [2];
  logic [3:0]   y_buffer_ben  [2];
  logic [31:0]  y_buffer_wr_data [2];
  logic [31:0]  y_buffer_rd_data [2];
  logic [31:0]  y_wr_data;
  logic [7:0]   y_rd_addr;
  logic [31:0]  y_rd_data;
  logic [3:0]   y_ben;

  // U RAM signals
  logic [6:0]   u_buffer_addr [2];
  logic         u_buffer_wen  [2];
  logic [3:0]   u_buffer_ben  [2];
  logic [31:0]  u_buffer_wr_data [2];
  logic [31:0]  u_buffer_rd_data [2];
  logic [31:0]  u_wr_data;
  logic [6:0]   u_rd_addr;
  logic [31:0]  u_rd_data;
  logic [3:0]   uv_ben;

  // V RAM signals
  logic [6:0]   v_buffer_addr [2];
  logic         v_buffer_wen  [2];
  logic [3:0]   v_buffer_ben  [2];
  logic [31:0]  v_buffer_wr_data [2];
  logic [31:0]  v_buffer_rd_data [2];
  logic [31:0]  v_wr_data;
  logic [6:0]   v_rd_addr;
  logic [31:0]  v_rd_data;

  // Buffer control
  logic         buffer_insert;
  logic         buff_wr_done;
  logic         buff_wr_done_latch;
  logic         buff_rd_done;
  logic         switch_yuv_buff;
  logic [7:0]   yuv_wr_addr;
  logic [1:0]   yuv_ptr;
  logic         yuv_ptr_rst;
  logic         yuv_addr_incr;
  logic [7:0]   yuv_wraddr_last;

  // Extract FSM
  typedef enum logic [1:0] {
    ExtIdle,
    ExtY,
    ExtU,
    ExtV
  } ext_state_e;
  ext_state_e ext_state_q, ext_state_q2;

  // byte valids and data
  logic   [3:0]   y_byte_valid;
  logic   [3:0]   u_byte_valid;
  logic   [3:0]   v_byte_valid;
  logic   [31:0]  yuv420_data_last;
  logic   [31:0]  yuv420_data_next;
  logic   [31:0]  yuv420_data;          // Output Y U or V depending on the channel code provided
  logic   [3:0]   yuv420_byte_valid;    // Byte valid for each data byte in the output data interface
  logic           yuv420_data_valid;    // Valid bit that indecates the validity of the data so the byte_valid alone isn't enough made for AXI
  logic           yuv_read_done;
  logic           yuv_read_done_r;
  logic           m_axi_wready_reg;
  logic           wready_negedge;
  logic           pick_last;
  logic           normal_operation;
  logic           normal_operation_latch;
  logic           normal_operation_s;
  logic           m_axi_wready_reg2;

  // length counters
  logic   [7:0]   max_count;
  logic   [7:0]   curr_count;
  logic           wlast_yuv;
  logic           wready_stage0;
    
  // aw addr signals
  logic                           frmptr_rst_pending;
  logic                           frmptr_rst;
  logic                           load_ptr;
  logic [AXI_ADDR_WIDTH-1:0]      y_addr_start;
  logic [AXI_ADDR_WIDTH-1:0]      u_addr_start;
  logic [AXI_ADDR_WIDTH-1:0]      v_addr_start;
  logic [AXI_ADDR_WIDTH-1:0]      y_awaddr_next;
  logic [AXI_ADDR_WIDTH-1:0]      u_awaddr_next;
  logic [AXI_ADDR_WIDTH-1:0]      v_awaddr_next;

  // AW FSM (Address Write FSM)
  typedef enum logic [1:0] {
    ReqIdle,
    ReqSendY,
    ReqSendU,
    ReqSendV
  } req_state_e;

  req_state_e req_state_q, req_state_d;
    
  //pixel part
  logic   [7:0]                   pixel_buffer_addr     [2];
  logic                           pixel_buffer_wen      [2];
  logic   [3:0]                   pixel_buffer_ben      [2];
  logic   [31:0]                  pixel_buffer_wr_data  [2];
  logic   [31:0]                  pixel_buffer_rd_data  [2];
  logic                           valid_input;
  logic   [2:0]                   num_of_valid_bytes;
  logic                           line_switch;
  logic                           pixel_wr_addr_incr;
  logic   [31:0]                  pixel_wr_data;
  logic   [31:0]                  pixel_rd_data;
  logic   [3:0]                   pixel_ben;
  logic   [2:0]                   p_ptr;
  logic   [7:0]                   pixel_wr_addr;
  logic   [7:0]                   pixel_wraddr_last;
  logic                           pixel_read_done;
  logic                           pixel_buff_full;
  logic   [7:0]                   pixel_rd_addr;
  logic                           line_data_valid;
  logic   [AXI_ADDR_WIDTH-1:0]    pixel_awaddr_prev;
  logic   [AXI_ADDR_WIDTH-1:0]    pixel_awaddr_next;
  logic                           csi_enable_reg;
  logic                           csi_enable_pulse;
  logic                           awvalid             [2];
  logic   [AXI_ADDR_WIDTH-1:0]    awaddr              [2];
  logic   [7:0]                   awlen               [2];
  logic   [31:0]                  wdata               [2];
  logic                           wlast               [2];
  logic   [AXI_DATA_WIDTH/8-1:0]  wstrb               [2];
  logic   [2:0]                   awsize              [2];
  logic   [1:0]                   awburst             [2];
  logic                           wvalid              [2];
  logic                           pixel_stream_stall;
  logic                           yuv_stream_stall;
  logic			                      pixel_write_index;
  logic                           yuv_write_index;
  logic                           dual_buffer_select;
  logic   [5:0]                   line_tracker;
  logic                           frame_done_pending;
  logic   [4:0]                   interrupt_counter;
  logic   [31:0]                  debug_counter;

  logic negedge_line_valid;
  logic line_valid_out;
  logic line_valid_out_r;
  logic posedge_line_valid_out;
  logic negedge_line_valid_out;

  // Extract FSM (line state machine)
  typedef enum logic [1:0] {
    LineIdle,
    LineWaitWrDone,
    LineWaitLineNegedge,
    LineWaitRdDone
  } line_state_e;

  line_state_e line_state_q;

  // Debug counter: increments on each valid YUV line not stalled, resets on frame write done interrupt
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      debug_counter <= 32'd0;
    end else if (frame_wr_done_intr_o) begin
      debug_counter <= 32'd0;
    end else if (line_valid_yuv_i && !stream_stall_o) begin
      debug_counter <= debug_counter + 32'd1;
    end
  end

  // csi_enable_pulse: asserted for one cycle when csi_enable_i rises
  assign csi_enable_pulse = csi_enable_i && !csi_enable_reg;

  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      csi_enable_reg <= 1'b0;
    end else begin
      csi_enable_reg <= csi_enable_i;
    end
  end

  // Tie all above signals to 0
  always_comb begin
    wvalid[0] = 0;
    wdata[0] = 0;
    wlast[0] = 0;
    wstrb[0] = 0;
    awsize[0] = 0;
    awburst[0] = 0;
    awvalid[0] = 0;
    awaddr[0] = 0;
    awlen[0] = 0;
    pixel_stream_stall = 0;
    pixel_write_index = 0;
    valid_input = 0;
    num_of_valid_bytes = 0;
    line_switch = 0;
    pixel_wr_addr_incr = 0;
    pixel_wr_data = 0;
    pixel_ben = 0;
  end

    
  // YUV420 logic works with ppc 2 only 32bit
  // Detect posedge and negedge of line_valid_yuv_i
  assign posedge_line_valid = (~line_valid_reg) & line_valid_yuv_i;
  assign negedge_line_valid = line_valid_reg & (~line_valid_yuv_i);

  // Line state machine and output register
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_valid_out_r <= 1'b0;
      line_state_q     <= LineIdle;
    end else begin
      line_valid_out_r <= line_valid_out;

      unique case (line_state_q)
        LineIdle: begin
          if (line_valid_yuv_i) begin
            line_state_q <= LineWaitWrDone;
          end
        end
        LineWaitWrDone: begin
          if (buff_wr_done) begin
            line_state_q <= LineWaitLineNegedge;
          end
        end
        LineWaitLineNegedge: begin
          if (negedge_line_valid) begin
            line_state_q <= LineWaitRdDone;
          end
        end
        LineWaitRdDone: begin
          if (buff_rd_done && !buff_wr_done) begin
            line_state_q <= LineIdle;
          end
        end
        default: begin
          line_state_q <= LineIdle;
        end
      endcase
    end
  end
    
  // Generate line_valid_out, posedge and negedge signals
  assign line_valid_out        = (line_state_q == LineWaitLineNegedge) || (line_state_q == LineWaitRdDone);
  assign posedge_line_valid_out = line_valid_out && !line_valid_out_r;
  assign negedge_line_valid_out = !line_valid_out && line_valid_out_r;

  // Register line_valid_yuv_i and toggle odd_line on negedge_line_valid_out
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_valid_reg <= 1'b0;
      odd_line      <= 1'b1;
    end else begin
      line_valid_reg <= line_valid_yuv_i;
      if (negedge_line_valid_out) begin
        odd_line <= ~odd_line;
      end
    end
  end

  // YUV memory array for each channel: two memories per channel (read/write)
  mem_yuv_array_wrapper u_mem_yuv_array_wrapper (
    .reset_n_i         (reset_n_i),
    .pixel_clk_i       (pixel_clk_i),

    // Y RAM signals
    .y_buffer_addr_i   (y_buffer_addr),
    .y_buffer_wen_i    (y_buffer_wen),
    .y_buffer_ben_i    (y_buffer_ben),
    .y_buffer_wr_data_i(y_buffer_wr_data),

    // U RAM signals
    .u_buffer_addr_i   (u_buffer_addr),
    .u_buffer_wen_i    (u_buffer_wen),
    .u_buffer_ben_i    (u_buffer_ben),
    .u_buffer_wr_data_i(u_buffer_wr_data),

    // V RAM signals
    .v_buffer_addr_i   (v_buffer_addr),
    .v_buffer_wen_i    (v_buffer_wen),
    .v_buffer_ben_i    (v_buffer_ben),
    .v_buffer_wr_data_i(v_buffer_wr_data),

    .y_buffer_rd_data_o(y_buffer_rd_data),
    .u_buffer_rd_data_o(u_buffer_rd_data),
    .v_buffer_rd_data_o(v_buffer_rd_data)
  );

  // Buffer control logic (lowRISC style)
  always_comb begin
    // Default assignments
    y_buffer_addr      = '{default: '0};
    y_buffer_wen       = '{default: 1'b0};
    y_buffer_ben       = '{default: 4'b0};
    y_buffer_wr_data   = '{default: 32'b0};
    u_buffer_addr      = '{default: '0};
    u_buffer_wen       = '{default: 1'b0};
    u_buffer_ben       = '{default: 4'b0};
    u_buffer_wr_data   = '{default: 32'b0};
    v_buffer_addr      = '{default: '0};
    v_buffer_wen       = '{default: 1'b0};
    v_buffer_ben       = '{default: 4'b0};
    v_buffer_wr_data   = '{default: 32'b0};

    // Write port (active buffer)
    y_buffer_addr[yuv_write_index]    = yuv_wr_addr;
    y_buffer_wen[yuv_write_index]     = 1'b0;
    y_buffer_ben[yuv_write_index]     = y_ben;
    y_buffer_wr_data[yuv_write_index] = y_wr_data;

    u_buffer_addr[yuv_write_index]    = yuv_wr_addr[7:1];
    u_buffer_wen[yuv_write_index]     = 1'b0;
    u_buffer_ben[yuv_write_index]     = uv_ben;
    u_buffer_wr_data[yuv_write_index] = u_wr_data;

    v_buffer_addr[yuv_write_index]    = yuv_wr_addr[7:1];
    v_buffer_wen[yuv_write_index]     = 1'b0;
    v_buffer_ben[yuv_write_index]     = uv_ben;
    v_buffer_wr_data[yuv_write_index] = v_wr_data;

    // Read port (inactive buffer)
    y_buffer_addr[!yuv_write_index]    = y_rd_addr;
    y_buffer_wen[!yuv_write_index]     = 1'b1;
    y_buffer_ben[!yuv_write_index]     = 4'b0;
    y_buffer_wr_data[!yuv_write_index] = 32'b0;
    y_rd_data                          = y_buffer_rd_data[!yuv_write_index];

    u_buffer_addr[!yuv_write_index]    = u_rd_addr;
    u_buffer_wen[!yuv_write_index]     = 1'b1;
    u_buffer_ben[!yuv_write_index]     = 4'b0;
    u_buffer_wr_data[!yuv_write_index] = 32'b0;
    u_rd_data                          = u_buffer_rd_data[!yuv_write_index];

    v_buffer_addr[!yuv_write_index]    = v_rd_addr;
    v_buffer_wen[!yuv_write_index]     = 1'b1;
    v_buffer_ben[!yuv_write_index]     = 4'b0;
    v_buffer_wr_data[!yuv_write_index] = 32'b0;
    v_rd_data                          = v_buffer_rd_data[!yuv_write_index];
  end

  // write logic //? write index points to the memory to be written

  // Write data and byte enable generation (lowRISC style)
  assign y_wr_data = {16'd0, yuv422_data_i[31:24], yuv422_data_i[15:8]} << (yuv_ptr[0] * 16);
  assign u_wr_data = {24'd0, yuv422_data_i[23:16]} << (yuv_ptr * 8);
  assign v_wr_data = {24'd0, yuv422_data_i[7:0]} << (yuv_ptr * 8);

  assign y_ben  = ~(4'b0011 << (yuv_ptr[0] * 2));
  assign uv_ben = ~(4'b0001 << yuv_ptr);

  assign buffer_insert = |yuv422_byte_valid_i;

  // Buffer write done: when buffer is full or line ends and pointer is at start
  assign buff_wr_done = ((yuv_wr_addr == 8'd255 && yuv_ptr == 2'd3) ||
                          (yuv_wr_addr > 8'd0 && !line_valid_yuv_i && yuv_ptr == 2'd0));

  // Buffer write done latch logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      buff_wr_done_latch <= 1'b0;
    end else if (switch_yuv_buff) begin
      buff_wr_done_latch <= 1'b0;
    end else if (buff_wr_done) begin
      buff_wr_done_latch <= 1'b1;
    end
  end

  // Buffer read done: active when extraction FSM is idle
  assign buff_rd_done = (ext_state_q == ExtIdle);

  // Switch YUV buffer: only when both write is done (or latched) and read is done
  assign switch_yuv_buff = (buff_wr_done || buff_wr_done_latch) && buff_rd_done;

  // YUV address increment: increment on even pointer and buffer insert
  assign yuv_addr_incr = (yuv_ptr[0] == 1'b1) && buffer_insert;

  // YUV write pointer and address logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      yuv_wr_addr      <= '0;
      yuv_ptr          <= '0;
      yuv_wraddr_last  <= '0;
      yuv_write_index  <= '0;
      odd_line_latched <= '0;
    end else begin
      // Switch buffer on buffer switch event
      if (switch_yuv_buff) begin
        yuv_write_index  <= ~yuv_write_index;
        odd_line_latched <= odd_line;
        yuv_ptr          <= '0;
        yuv_wr_addr      <= '0;
        // Subtract 1 if yuv_ptr is 0 (no valid write in last cycle)
        yuv_wraddr_last  <= (yuv_ptr == 2'd0) ? (yuv_wr_addr - 8'd1) : yuv_wr_addr;
      end else begin
        // Increment pointer on buffer insert
        if (buffer_insert) begin
          yuv_ptr <= yuv_ptr + 2'd1;
        end
        // Increment address when pointer wraps (every 2 cycles)
        if (yuv_addr_incr) begin
          yuv_wr_addr <= yuv_wr_addr + 8'd1;
        end
      end
    end
  end

  // Read pointer/address logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      y_rd_addr <= '0;
      u_rd_addr <= '0;
      v_rd_addr <= '0;
    end else begin
      // Y channel read address
      if (switch_yuv_buff) begin
        y_rd_addr <= '0;
      end else if ((ext_state_q == ExtY) && mst_resp_i.w_ready && (y_rd_addr != yuv_wraddr_last)) begin
        y_rd_addr <= y_rd_addr + 8'd1;
      end

      // U channel read address
      if (switch_yuv_buff) begin
        u_rd_addr <= '0;
      end else if ((ext_state_q == ExtU) && mst_resp_i.w_ready && (u_rd_addr != yuv_wraddr_last[7:1])) begin
        u_rd_addr <= u_rd_addr + 7'd1;
      end

      // V channel read address
      if (switch_yuv_buff) begin
        v_rd_addr <= '0;
      end else if ((ext_state_q == ExtV) && mst_resp_i.w_ready && (v_rd_addr != yuv_wraddr_last[7:1])) begin
        v_rd_addr <= v_rd_addr + 7'd1;
      end
    end
  end

  /*
  FSM breakdown
  The Y, U, and V channels are separated for YUV420 datatype because each of them is located in a different memory region
  In ExtY ext_state_q we get the Y component pixels output, and in ExtU ext_state_q we get the U component and so on
  We output 256 entries of Y then 128 entries of U then 128 entries of V
  If we assume that the time taken to fill the buffers is T then getting the Y out takes (1/2)T, then getting U out takes (1/4)T then getting V out takes (1/4)T 
  Which compined alligns with the time required to get the buffer full again so we utilized 100% of the time window and bus width
  */

  // Extraction FSM: controls Y, U, V channel output sequencing
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      ext_state_q  <= ExtIdle;
      ext_state_q2 <= ExtIdle;
    end else begin
      ext_state_q2 <= ext_state_q;
      unique case (ext_state_q)
        ExtIdle: begin
          if (switch_yuv_buff) begin
            ext_state_q <= ExtY;
          end
        end
        ExtY: begin
          if (wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid) begin
            if (odd_line) begin
              ext_state_q <= ExtU;
            end else begin
              ext_state_q <= ExtIdle;
            end
          end
        end
        ExtU: begin
          if (wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid) begin
            ext_state_q <= ExtV;
          end
        end
        ExtV: begin
          if (wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid) begin
            ext_state_q <= ExtIdle;
          end
        end
        default: begin
          ext_state_q <= ExtIdle;
        end
      endcase
    end
  end

  // Calculate max_count and curr_count for each extraction state (lowRISC style)
  always_comb begin
    unique case (ext_state_q)
      ExtY: begin
        max_count  = yuv_wraddr_last;
        curr_count = y_rd_addr;
      end
      ExtU, ExtV: begin
        max_count  = {1'b0, yuv_wraddr_last[7:1]};
        curr_count = (ext_state_q == ExtU) ? {1'b0, u_rd_addr} : {1'b0, v_rd_addr};
      end
      default: begin
        max_count  = 8'd0;
        curr_count = 8'd0;
      end
    endcase
  end

  // Alignment logic (lowRISC style)
  assign normal_operation_s = (mst_resp_i.w_ready && m_axi_wready_reg2 && ext_state_q != ExtIdle);
  assign normal_operation   = normal_operation_latch | normal_operation_s;

  // normal_operation_latch and m_axi_wready_reg2 logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      normal_operation_latch <= 1'b0;
      m_axi_wready_reg2      <= 1'b0;
    end else begin
      m_axi_wready_reg2 <= mst_resp_i.w_ready;
      if (wlast_yuv && mst_resp_i.w_ready) begin
        normal_operation_latch <= 1'b0;
        m_axi_wready_reg2      <= 1'b0;
      end else if (normal_operation_s) begin
        normal_operation_latch <= 1'b1;
      end
    end
  end

  // yuv_read_done: Indicates completion of YUV extraction for the current line
  assign yuv_read_done = (odd_line ? (ext_state_q == ExtV) : (ext_state_q == ExtY)) & wlast_yuv;

  // YUV420 data valid and last data logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      yuv420_data_valid <= 1'b0;
      m_axi_wready_reg  <= 1'b0;
      yuv420_data_last  <= 32'b0;
      pick_last         <= 1'b0;
    end else begin
      m_axi_wready_reg <= mst_resp_i.w_ready;

      // Deassert data valid after successful transfer or when not in normal operation
      if ((yuv_read_done || (!normal_operation && !wlast_yuv)) && mst_resp_i.w_ready && yuv420_data_valid) begin
        yuv420_data_valid <= 1'b0;
      end else if (ext_state_q != ExtIdle) begin
        yuv420_data_valid <= 1'b1;
      end

      // Latch last data on w_ready negedge
      if (wready_negedge) begin
        yuv420_data_last <= yuv420_data_next;
      end

      // Pick last data if not ready in normal operation and not at first count
      if (curr_count > 0 && normal_operation) begin
        pick_last <= ~mst_resp_i.w_ready;
      end else begin
        pick_last <= 1'b0;
      end
    end
  end

  // Detect negative edge of w_ready
  assign wready_negedge = (~mst_resp_i.w_ready) & m_axi_wready_reg;

  // Select next YUV420 data based on extraction state
  always_comb begin
    unique case (ext_state_q)
      ExtY:   yuv420_data_next = y_rd_data;
      ExtU:   yuv420_data_next = u_rd_data;
      ExtV:   yuv420_data_next = v_rd_data;
      default:yuv420_data_next = 32'd0;
    endcase
  end

  // Output YUV420 data, possibly using last value if required
  assign yuv420_data = pick_last ? yuv420_data_last : yuv420_data_next;

  // Byte valid for YUV420 output
  assign yuv420_byte_valid = (ext_state_q != ExtIdle) ? 4'b1111 : 4'b0000;
  
  ////////////////
  // AXI logic //
  ////////////////
    
  // wlast_yuv generation (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      wlast_yuv <= 1'b0;
    end else begin
      // Clear wlast_yuv after successful transfer
      if (wlast_yuv && mst_req_o.w_valid && mst_resp_i.w_ready) begin
        wlast_yuv <= 1'b0;
      end
      // Set wlast_yuv when last data is being transferred (no latched output)
      else if (!normal_operation && (curr_count == max_count - 1) && mst_req_o.w_valid && mst_resp_i.w_ready) begin
        wlast_yuv <= 1'b1;
      end
      // Set wlast_yuv when last data is being transferred (latched output)
      else if ((curr_count == max_count) && mst_req_o.w_valid && mst_resp_i.w_ready) begin
        wlast_yuv <= 1'b1;
      end
    end
  end

    
  // Frame pointer reset and dual buffer select logic (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      frmptr_rst_pending <= 1'b0;
      dual_buffer_select <= 1'b0;
    end else begin
      // Set pending reset and toggle buffer select on frame done pulse
      if (frame_done_pulse_i) begin
        frmptr_rst_pending <= 1'b1;
        dual_buffer_select <= ~dual_buffer_select;
      end
      // Clear pending reset after frame pointer reset
      if (frmptr_rst) begin
        frmptr_rst_pending <= 1'b0;
      end
    end
  end

  // Frame pointer reset: asserted when pending and new line starts
  assign frmptr_rst = frmptr_rst_pending && posedge_line_valid;
  // Load pointer on frame pointer reset or CSI enable pulse
  assign load_ptr   = frmptr_rst || csi_enable_pulse;

  // Frame done pending and YUV read done register (lowRISC style)
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      frame_done_pending <= 1'b0;
      yuv_read_done_r    <= 1'b0;
    end else begin
      yuv_read_done_r <= yuv_read_done;
      if (frame_wr_done_intr_o) begin
        frame_done_pending <= 1'b0;
      end else if (frame_done_pulse_i) begin
        frame_done_pending <= 1'b1;
      end
    end
  end

  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      interrupt_counter <= '0;
      frame_wr_done_intr_o <= 1'b0;
    end else begin
      if (frame_done_pending && !yuv_read_done_r && yuv_read_done && !line_valid_yuv_i && !buff_wr_done_latch) begin
        frame_wr_done_intr_o <= 1'b1;
      end else if (interrupt_counter == 5'd23) begin
        frame_wr_done_intr_o <= 1'b0;
      end

      if (frame_wr_done_intr_o) begin
        interrupt_counter <= interrupt_counter + 1;
      end else begin
        interrupt_counter <= '0;
      end
    end
  end

  // Address calculation for Y, U, and V channels
  assign y_addr_start = (dual_buffer_select && double_buff_enable_reg_i) ? frame_ptr1_i : frame_ptr0_i;
  assign u_addr_start = y_addr_start + frame_width_i * frame_height_i;
  assign v_addr_start = u_addr_start + (frame_width_i * frame_height_i >> 2);

  // Address update and state transition logic
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      req_state_q     <= ReqIdle;
      y_awaddr_next   <= '0;
      u_awaddr_next   <= '0;
      v_awaddr_next   <= '0;
    end else begin
      if (load_ptr) begin
        y_awaddr_next <= y_addr_start;
        u_awaddr_next <= u_addr_start;
        v_awaddr_next <= v_addr_start;
      end else if ((req_state_q != req_state_d) && (req_state_d == ReqIdle)) begin
        if (odd_line) begin
          y_awaddr_next <= y_awaddr_next + (({3'd0, yuv_wraddr_last} + 1) << 2);
          u_awaddr_next <= u_awaddr_next + (({3'd0, yuv_wraddr_last[7:1]} + 1) << 2);
          v_awaddr_next <= v_awaddr_next + (({3'd0, yuv_wraddr_last[7:1]} + 1) << 2);
        end else begin
          y_awaddr_next <= y_awaddr_next + (({3'd0, yuv_wraddr_last} + 1) << 2);
        end
      end
      req_state_q <= req_state_d;
    end
  end

  always_comb begin
    // Default assignments
    awvalid[1] = 1'b0;
    awaddr[1]  = '0;
    awlen[1]   = '0;
    req_state_d = ReqIdle;

    unique case (req_state_q)
      ReqIdle: begin
        if (switch_yuv_buff) begin
          req_state_d = ReqSendY;
        end else begin
          req_state_d = ReqIdle;
        end
      end

      ReqSendY: begin
        awvalid[1] = 1'b1;
        awaddr[1]  = y_awaddr_next;
        awlen[1]   = yuv_wraddr_last;
        if (mst_resp_i.aw_ready) begin
          if (odd_line) begin
            req_state_d = ReqSendU;
          end else begin
            req_state_d = ReqIdle;
          end
        end else begin
          req_state_d = ReqSendY;
        end
      end

      ReqSendU: begin
        awvalid[1] = 1'b1;
        awaddr[1]  = u_awaddr_next;
        awlen[1]   = {1'b0, yuv_wraddr_last[7:1]};
        if (mst_resp_i.aw_ready) begin
          req_state_d = ReqSendV;
        end else begin
          req_state_d = ReqSendU;
        end
      end

      ReqSendV: begin
        awvalid[1] = 1'b1;
        awaddr[1]  = v_awaddr_next;
        awlen[1]   = {1'b0, yuv_wraddr_last[7:1]};
        if (mst_resp_i.aw_ready) begin
          req_state_d = ReqIdle;
        end else begin
          req_state_d = ReqSendV;
        end
      end

      default: begin
        req_state_d = ReqIdle;
      end
    endcase
  end

  always_comb begin
    awsize[1] = 3'b010; // 4 bytes
    awburst[1] = 2'b01; // INCR
    wdata[1] = yuv420_data;
    wstrb[1] = yuv420_byte_valid;
    wvalid[1] = yuv420_data_valid;
    wlast[1] = wlast_yuv;
  end

  // stall logic (Should stall reading and writing in all stages of the pipeline)
  // stall when write is valid but there is no write ready with it or when 
  // ext_state_q is at ExtV while req_state_q is not at IDLE yet means that the AW channel wasn't sent yet
  assign yuv_stream_stall = (ext_state_q != ExtIdle && !mst_resp_i.w_ready) ||
                ((ext_state_q == ExtV) && (req_state_q != ReqIdle)) ||
                (!buff_rd_done && (buff_wr_done_latch || buff_wr_done)); // Ensure stall when ext_state_q != ExtIdle
                                            // Add buff_rd_done to prevent writes during buffer read
  assign stream_stall_o = yuv_stream_stall;

  // Tie unused signals
  always_comb begin
    // Default assignments to avoid latches
    mst_req_o.aw          = '0;
    mst_req_o.aw.id       = '0;
    mst_req_o.aw_valid    = 1'b0;
    mst_req_o.aw.cache    = 4'd0;
    mst_req_o.aw.atop     = 6'd0;
    mst_req_o.w           = '0;
    mst_req_o.w_valid     = 1'b0;
    mst_req_o.b_ready     = 1'b1;
    mst_req_o.ar          = '0;
    mst_req_o.ar.id       = '0;
    mst_req_o.ar_valid    = 1'b1;
    mst_req_o.r_ready     = 1'b1;

    // Mux assignments
    mst_req_o.aw_valid    = awvalid[output_select_i];
    mst_req_o.aw.addr     = awaddr[output_select_i];
    mst_req_o.aw.len      = awlen[output_select_i];
    mst_req_o.aw.size     = awsize[output_select_i];
    mst_req_o.aw.burst    = awburst[output_select_i];
    mst_req_o.w.data      = wdata[output_select_i];
    mst_req_o.w.last      = wlast[output_select_i];
    mst_req_o.w.strb      = wstrb[output_select_i];
    mst_req_o.w_valid     = wvalid[output_select_i];
  end
  
  // Counter assertion to count the number of (yuv420_data_valid && mst_resp_i.w_ready) occurrences during ext_state_q == ExtY, ExtU, and ExtV
  // When the state transitions from ExtY to ExtU, the counter should reset to 0, and similarly for ExtU to ExtV and ExtV to ExtIdle
  // During ExtY, the counter should reach 129, and during ExtU and ExtV, the counter should reach 65
  // If the counter does not reach the expected value, the assertion is triggered
  `ifndef SYNTHESIS
    // Define counters
    integer y_counter;
    integer u_counter;
    integer v_counter;
    logic trigger;

    // Trigger reset on state transitions
    assign trigger = (ext_state_q != ext_state_q2);

    // Counter logic
    always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
      if (!reset_n_i) begin
        y_counter <= 0;
        u_counter <= 0;
        v_counter <= 0;
      end else begin
        if (trigger) begin
          y_counter <= 0;
          u_counter <= 0;
          v_counter <= 0;
        end else begin
          if (ext_state_q == ExtY && yuv420_data_valid && mst_resp_i.w_ready) begin
            y_counter <= y_counter + 1;
          end
          if (ext_state_q == ExtU && yuv420_data_valid && mst_resp_i.w_ready) begin
            u_counter <= u_counter + 1;
          end
          if (ext_state_q == ExtV && yuv420_data_valid && mst_resp_i.w_ready) begin
            v_counter <= v_counter + 1;
          end
        end
      end
    end

    // Define properties for assertions
    property p_Y_EXT;
      @(posedge pixel_clk_i)
      (trigger && ext_state_q2 == ExtY) |-> ##1 ($past(y_counter) == 129);
    endproperty

    property p_U_EXT;
      @(posedge pixel_clk_i)
      (trigger && ext_state_q2 == ExtU) |-> ##1 ($past(u_counter) == 65);
    endproperty

    property p_V_EXT;
      @(posedge pixel_clk_i)
      (trigger && ext_state_q2 == ExtV) |-> ##1 ($past(v_counter) == 65);
    endproperty

    // Assert the properties
    assert property (p_Y_EXT) else $error("Assertion failed: y_counter did not reach 129 in ExtY state, counter=%0d", $past(y_counter));
    assert property (p_U_EXT) else $error("Assertion failed: u_counter did not reach 65 in ExtU state, counter=%0d", $past(u_counter));
    assert property (p_V_EXT) else $error("Assertion failed: v_counter did not reach 65 in ExtV state, counter=%0d", $past(v_counter));
  `endif

endmodule