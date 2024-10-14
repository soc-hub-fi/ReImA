/*
    File: isp_axi_master.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: 

    Functionality: 
    -   converts yuv422 input to yuv420 by buffering Y,U and V channels in separate buffers and sending Y transaction then U then V and so on
        because they are located in different memory locations.
    -   This module is made specifically for integration with AXI mast interface for that reason but other interfaces can work as well
    -   The module includes 6 memories 3 are being written while 3 are being read, each memory corresponds to Y U or V channel
    -   For YUV450 The module works only for PPC=2 as it leads to the maximum throughput possible for the system due to AXI 32bit interface constraint
    -   Inputs can also be preprocessed pixels coming from flow control block which are saved in 2 buffers one for reading and one for writing in a time
    -   Other pixel formats to be supported later
    Authors: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
`include "axi/typedef.svh"
module csi_axi_master#( parameter int unsigned              AXI_ID_WIDTH    = 32'd0,
                        parameter int unsigned              AXI_ADDR_WIDTH  = 32'd0,
                        parameter int unsigned              AXI_DATA_WIDTH  = 32'd0,
                        parameter int unsigned              AXI_USER_WIDTH  = 32'd0,
                        parameter type                      full_req_t      = logic,
                        parameter type                      full_resp_t     = logic          
                )
                    (
                    // clock and reset interface
                    input                                   reset_n_i,
                    input                                   pixel_clk_i,

                    // data interface
                    input                                   frame_done_pulse_i,
                    output logic                            stream_stall_o,
                    input                                   line_valid_pixel_i,         // Line valid high signal should remain high even if the stall is coming
                    input           [95:0]                  pixel_data_i,               // Pixel data input from flow control 
                    input           [11:0]                  pixel_byte_valid_i,         // Pixel byte data valid  from flow control
                    input                                   line_valid_yuv_i,           // Line valid high signal should remain high even if the stall is coming
                    input           [63:0]                  yuv422_data_i,              // YUV422 coming from rgb2yuv block
                    input           [7:0]                   yuv422_byte_valid_i,        // Valid bit for each byte in the data interface
                    
                    // configuration interface
                    input                                   double_buff_enable_reg_i,   // Enable double buffering when disabled only frame_ptr0_i is selected 
                    input           [11:0]                  frame_width_i,              // Frame width for aw ptr calculation
                    input           [11:0]                  frame_height_i,             // Frame hight for aw ptr calculation
                    input           [AXI_ADDR_WIDTH-1:0]    frame_ptr0_i,               // Frame pointers0 for aw_write
                    input           [AXI_ADDR_WIDTH-1:0]    frame_ptr1_i,               // Frame pointers1 for aw_write
                    input                                   csi_enable_i,               // Should be toggelled high after configuration done
                    input                                   output_select_i,            // Select the output 1 for yuv420, 0 for pixel data

                    // Axi address write interface
                    output full_req_t                       mst_req_o,                  // Master request
                    input  full_resp_t                      mst_resp_i,                  // Master response

                    // Interrupt
                    output logic                            frame_wr_done_intr_o
            );

    // Redo the signal declaration
    //YUV part
    logic                           posedge_line_valid;
    logic                           line_valid_reg;
    logic                           odd_line;
    logic                           odd_line_latched;
        // y ram signals
    logic   [7:0]                   y_buffer_addr     [2];
    logic                           y_buffer_wen      [2];
    logic   [3:0]                   y_buffer_ben      [2];
    logic   [31:0]                  y_buffer_wr_data  [2];
    logic   [31:0] 	                y_wr_data;
    logic   [7:0] 	                y_rd_addr;
    logic   [31:0] 	                y_rd_data;
    logic   [3:0]                   y_ben;
    logic   [31:0]                  y_buffer_rd_data  [2];
        // u ram signals
    logic   [6:0]                   u_buffer_addr     [2];
    logic                           u_buffer_wen      [2];
    logic   [3:0]                   u_buffer_ben      [2];
    logic   [31:0]                  u_buffer_wr_data  [2];
    logic   [31:0] 	                u_wr_data;
    logic   [6:0] 	                u_rd_addr;
    logic   [31:0] 	                u_rd_data;
    logic   [3:0]                   uv_ben;
    logic   [31:0]                  u_buffer_rd_data  [2];
        // v ram signals
    logic   [6:0]                   v_buffer_addr     [2];
    logic                           v_buffer_wen      [2];
    logic   [3:0]                   v_buffer_ben      [2];
    logic   [31:0]                  v_buffer_wr_data  [2];
    logic   [31:0] 	                v_wr_data;
    logic   [6:0] 	                v_rd_addr;
    logic   [31:0] 	                v_rd_data;
    logic   [31:0]                  v_buffer_rd_data  [2];

    logic                           buffer_insert;
    logic                           buff_wr_done;
    logic                           buff_wr_done_latch;
    logic                           buff_rd_done;
    logic                           switch_yuv_buff;
    logic   [7:0]                   yuv_wr_addr;
    logic   [1:0]                   yuv_ptr;
    logic                           yuv_ptr_rst;
    logic                           yuv_addr_incr;
    logic   [7:0]                   yuv_wraddr_last;

        // Extract FSM
    typedef enum logic [1:0] {IDLE0, Y_EXT, U_EXT, V_EXT} ext_statetype;
    ext_statetype ext_state,  ext_state_delayed;
        // byte valids and data

    logic   [3:0]                   y_byte_valid;
    logic   [3:0]                   u_byte_valid;
    logic   [3:0]                   v_byte_valid;
    logic   [31:0]                  yuv420_data_last;
    logic   [31:0]                  yuv420_data_next;
    logic   [31:0]                  yuv420_data;          // Output Y U or V depending on the channel code provided
    logic   [3:0]                   yuv420_byte_valid;    // Byte valid for each data byte in the output data interface
    logic                           yuv420_data_valid;    // Valid bit that indecates the validity of the data so the byte_valid alone isn't enough made for AXI
    logic                           yuv_read_done;
    logic                           yuv_read_done_r;
    logic                           m_axi_wready_reg;
    logic                           wready_negedge;
    logic                           pick_last;
    logic                           normal_operation;
    logic                           normal_operation_latch;
    logic                           normal_operation_s;
    logic                           m_axi_wready_reg2;
        // length counters
    logic   [7:0]                   max_count;
    logic   [7:0]                   curr_count;
    logic                           wlast_yuv;
    logic                           wready_stage0;
    
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
        // AW FSM
    typedef enum logic [1:0] {IDLE1, SEND_Y_WREQ, SEND_U_WREQ, SEND_V_WREQ} req_statetype;
    req_statetype req_state, req_next_state;
    
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
    logic			                pixel_write_index;
    logic                           yuv_write_index;
    logic                           dual_buffer_select;
    logic   [5:0]                   line_tracker;
    logic                           frame_done_pending;
    logic   [4:0]                   interrupt_counter;
    logic   [31:0]                  debug_counter;
    // Extract FSM
    typedef enum logic [1:0] {IDLE3, WAIT_WR_DONE, WAIT_LINE_NEGEDGE, WAIT_RD_DONE} line_statetype;
    line_statetype line_state;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            debug_counter <= 0;
        end
        else begin
            if(frame_wr_done_intr_o)
                debug_counter <= 0;
            else if(line_valid_yuv_i && !stream_stall_o)
                debug_counter <= debug_counter+1;
        end
    end

    typedef enum logic {IDLE2, SEND_PIX_WREQ} pixel_req_statetype;
    pixel_req_statetype             pixel_req_state, pixel_req_state_next;
    assign csi_enable_pulse = csi_enable_i & !csi_enable_reg;
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            csi_enable_reg <= 0;
        end
        else begin
            csi_enable_reg <= csi_enable_i;
        end
    end

    always_comb begin
        // Tie all above signals to 0
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
    logic negedge_line_valid;
    logic line_valid_out;
    logic line_valid_out_r;
    logic posedge_line_valid_out;
    logic negedge_line_valid_out;
//* YUV420 logic works with ppc 2 only 32bit
    assign posedge_line_valid = !line_valid_reg & line_valid_yuv_i;
    assign negedge_line_valid = line_valid_reg & !line_valid_yuv_i;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            line_valid_out_r <= 0; 
            line_state <= IDLE3;
        end
        else begin
            line_valid_out_r <= line_valid_out;

            case (line_state)
                IDLE3: begin
                    if(line_valid_yuv_i)
                        line_state <= WAIT_WR_DONE;
                end
                WAIT_WR_DONE: begin
                    if(buff_wr_done)
                        line_state <= WAIT_LINE_NEGEDGE;
                end
                WAIT_LINE_NEGEDGE: begin
                    if(negedge_line_valid)
                        line_state <= WAIT_RD_DONE;
                end
                WAIT_RD_DONE: begin
                    if(buff_rd_done && !buff_wr_done)
                        line_state <= IDLE3;
                end
                default: line_state <= IDLE3;
            endcase
        end
    end
    assign line_valid_out = (line_state==WAIT_LINE_NEGEDGE || line_state==WAIT_RD_DONE);
    assign posedge_line_valid_out = line_valid_out & ~line_valid_out_r;
    assign negedge_line_valid_out = ~line_valid_out & line_valid_out_r;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            line_valid_reg <=0;
            odd_line <= 1;
        end
        else begin
            line_valid_reg <= line_valid_yuv_i;
            if(negedge_line_valid_out)
                odd_line <= !odd_line;
        end
    end

    // YUV memory array for each channel there are two memories one for reading and one for writing
    yuv_mem_array_wrapper
    yuv_mem_array_wrapper_i(
                    .reset_n_i			(reset_n_i),
                    .pixel_clk_i		(pixel_clk_i),
                    
                    // y ram signals
                    .y_buffer_addr_i	(y_buffer_addr),
                    .y_buffer_wen_i		(y_buffer_wen),
                    .y_buffer_ben_i		(y_buffer_ben),
                    .y_buffer_wr_data_i	(y_buffer_wr_data),

                    // u ram signals
                    .u_buffer_addr_i	(u_buffer_addr),
                    .u_buffer_wen_i		(u_buffer_wen),
                    .u_buffer_ben_i		(u_buffer_ben),
                    .u_buffer_wr_data_i	(u_buffer_wr_data),

                    // v ram signals
                    .v_buffer_addr_i		(v_buffer_addr),
                    .v_buffer_wen_i		(v_buffer_wen),
                    .v_buffer_wr_data_i	(v_buffer_wr_data),
                    .v_buffer_ben_i		(v_buffer_ben),
                    
                    .y_buffer_rd_data_o	(y_buffer_rd_data),
                    .u_buffer_rd_data_o	(u_buffer_rd_data),
                    .v_buffer_rd_data_o	(v_buffer_rd_data)
                );

    always_comb begin
        // defaults
        // insert y
        y_buffer_addr       = '{0,0};
        y_buffer_wen        = '{0,0};
        y_buffer_ben        = '{0,0};
        y_buffer_wr_data    = '{0,0};
        // insert u
        u_buffer_addr       = '{0,0};
        u_buffer_wen        = '{0,0};
        u_buffer_ben        = '{0,0};
        u_buffer_wr_data    = '{0,0};
        // insert v
        v_buffer_addr       = '{0,0};
        v_buffer_wen        = '{0,0};
        v_buffer_ben        = '{0,0};
        v_buffer_wr_data    = '{0,0};

        // insert y
        y_buffer_addr       [yuv_write_index]   = yuv_wr_addr;
        y_buffer_wen        [yuv_write_index]   = 0;
        y_buffer_ben        [yuv_write_index]   = y_ben;
        y_buffer_wr_data    [yuv_write_index]	= y_wr_data;

        y_buffer_addr       [!yuv_write_index] 	= y_rd_addr;
        y_buffer_wen        [!yuv_write_index]  = 1;
        y_buffer_ben        [!yuv_write_index]  = 0;
        y_buffer_wr_data    [!yuv_write_index] 	= 0;
        y_rd_data						        = y_buffer_rd_data[!yuv_write_index];

        // insert u
        u_buffer_addr       [yuv_write_index]   = yuv_wr_addr[7:1];
        u_buffer_wen        [yuv_write_index]   = 0;
        u_buffer_ben        [yuv_write_index]   = uv_ben;
        u_buffer_wr_data    [yuv_write_index]	= u_wr_data;

        u_buffer_addr       [!yuv_write_index] 	= u_rd_addr; 
        u_buffer_wen        [!yuv_write_index]  = 1;
        u_buffer_ben[       !yuv_write_index]   = 0;
        u_buffer_wr_data    [!yuv_write_index] 	= 0;
        u_rd_data						        = u_buffer_rd_data[!yuv_write_index];

        // insert v
        v_buffer_addr       [yuv_write_index]   = yuv_wr_addr[7:1];
        v_buffer_wen        [yuv_write_index]   = 0;
        v_buffer_ben        [yuv_write_index]   = uv_ben;
        v_buffer_wr_data    [yuv_write_index]	= v_wr_data;

        v_buffer_addr       [!yuv_write_index] 	= v_rd_addr; 
        v_buffer_wen        [!yuv_write_index]  = 1;
        v_buffer_ben        [!yuv_write_index]  = 0;
        v_buffer_wr_data    [!yuv_write_index] 	= 0;
        v_rd_data						        = v_buffer_rd_data[!yuv_write_index];
    end

    // write logic //? write index points to the memory to be written

    assign y_wr_data 	= {16'd0, yuv422_data_i[31:24], yuv422_data_i[15:8]} 	<< (yuv_ptr[0]*16);
    assign u_wr_data 	= {24'd0, yuv422_data_i[23:16]} 						<< (yuv_ptr*8);
    assign v_wr_data 	= {24'd0, yuv422_data_i[7:0]} 						    << (yuv_ptr*8);

    assign y_ben 		= ~({2'b00,2'b11} << (yuv_ptr[0]*2));
    assign uv_ben 		= ~({3'b000,1'b1} << (yuv_ptr));

    assign buffer_insert = |yuv422_byte_valid_i & !yuv_stream_stall;

    assign buff_wr_done = ((yuv_wr_addr==255 & yuv_ptr==3) | (yuv_wr_addr>0 & !line_valid_yuv_i & yuv_ptr==0)) ;    // write buffer done when full or line is done while waiting for the read to be done
                                                                                                                    // Add yuvptr==0 to make sure that we always send 32 bits
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin // wr ptr and wr addr logic
        if(!reset_n_i) begin
            buff_wr_done_latch <= 0;
        end
        else begin
            if(switch_yuv_buff)
                buff_wr_done_latch <= 0;
            else if(buff_wr_done)
                buff_wr_done_latch <= 1;
        end
    end

    assign buff_rd_done = (ext_state==IDLE0);
    assign switch_yuv_buff = (buff_wr_done|buff_wr_done_latch) & buff_rd_done; //! Should wait for AW to be sent also not only W!!!
    assign yuv_addr_incr = yuv_ptr[0] & buffer_insert;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin // wr ptr and wr addr logic
        if(!reset_n_i) begin
            yuv_wr_addr <= 0;
            yuv_ptr <= 0;
            yuv_wraddr_last <= 0;
            yuv_write_index <= 0;
            odd_line_latched <= 0;
        end
        else begin
            // switching logic
            if(switch_yuv_buff) begin
                yuv_write_index <= !yuv_write_index;
                odd_line_latched <= odd_line;
                yuv_ptr <= 0;
            end
            if(buffer_insert)
                yuv_ptr <= yuv_ptr + 2'd1;
            
            // address logic address increment for Y and UV are deduced from it
            if(switch_yuv_buff)begin // reset
                yuv_wr_addr <= 0;
                yuv_wraddr_last <= yuv_ptr==0? yuv_wr_addr-8'd1: yuv_wr_addr; // subtract 1 incase of the not valid write situation
            end
            else if(yuv_addr_incr)
                yuv_wr_addr <= yuv_wr_addr + 8'd1;
        end
    end

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin // wr ptr and wr addr logic
        if(!reset_n_i) begin
            y_rd_addr <= 0;
            u_rd_addr <= 0;
            v_rd_addr <= 0;
        end
        else begin
            if(switch_yuv_buff)
                y_rd_addr <= 0;
            else if(ext_state==Y_EXT && mst_resp_i.w_ready && y_rd_addr!=yuv_wraddr_last)
                y_rd_addr <= y_rd_addr + 8'd1;
            
            if(switch_yuv_buff)
                u_rd_addr <= 0;
            else if(ext_state==U_EXT && mst_resp_i.w_ready  && u_rd_addr!=yuv_wraddr_last[7:1])
                u_rd_addr <= u_rd_addr + 7'd1;

            if(switch_yuv_buff)
                v_rd_addr <= 0;
            else if(ext_state==V_EXT && mst_resp_i.w_ready && v_rd_addr!=yuv_wraddr_last[7:1])
                v_rd_addr <= v_rd_addr + 7'd1;
        end
    end

    /*
    FSM breakdown
    The Y, U, and V channels are separated for YUV420 datatype because each of them is located in a different memory region
    In Y_EXT ext_state we get the Y component pixels output, and in U_EXT ext_state we get the U component and so on
    We output 256 entries of Y then 128 entries of U then 128 entries of V
    If we assume that the time taken to fill the buffers is T then getting the Y out takes (1/2)T, then getting U out takes (1/4)T then getting V out takes (1/4)T 
    Which compined alligns with the time required to get the buffer full again so we utilized 100% of the time window and bus width
    */

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            ext_state <= IDLE0;
            ext_state_delayed <= IDLE0;
        end
        else begin
            ext_state_delayed <= ext_state;
            case(ext_state)
            IDLE0: begin
                if(switch_yuv_buff)
                    ext_state <= Y_EXT;
            end
            Y_EXT: begin
                if(odd_line) begin // we send uv on odd lines only (it doesn't matter if its odd really as long as we skip one line)
                    if(wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid) begin
                        ext_state <= U_EXT;
                    end
                end
                else if(wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid)
                    ext_state <= IDLE0;
            end
            U_EXT: begin
                if(wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid)
                    ext_state <= V_EXT;
            end
            V_EXT: begin
                if(wlast_yuv && mst_resp_i.w_ready && mst_req_o.w_valid)
                    ext_state <= IDLE0;
            end
            endcase
        end
    end

    assign max_count = (ext_state==Y_EXT)? yuv_wraddr_last: ((ext_state==U_EXT)? {1'b0, yuv_wraddr_last[7:1]}: ((ext_state==V_EXT)? {1'b0, yuv_wraddr_last[7:1]}: 8'd0));
    assign curr_count = (ext_state==Y_EXT)? y_rd_addr: ((ext_state==U_EXT)? {1'b0, u_rd_addr}: ((ext_state==V_EXT)? {1'b0, v_rd_addr}: 8'd0));

    // alignment logic
    assign normal_operation_s = mst_resp_i.w_ready && m_axi_wready_reg2 && ext_state!=IDLE0;
    assign normal_operation = normal_operation_latch | normal_operation_s;  // On normal operation there is latched data on data last so valid doesn't need to be deasserted
                                                                            // And pick last is active
                                                                            // Otherwise data valid keeps deasserting
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            normal_operation_latch <= 0;
            m_axi_wready_reg2 <= 0;
        end
        else begin
            m_axi_wready_reg2 <= mst_resp_i.w_ready;
            if(wlast_yuv && mst_resp_i.w_ready) begin
                normal_operation_latch <= 0;
                m_axi_wready_reg2 <= 0;
            end
            else if(normal_operation_s) // Add ext_state to make sure that we are in the right state
                normal_operation_latch <= 1;
        end
    end

    assign yuv_read_done = (odd_line? (ext_state==V_EXT): (ext_state==Y_EXT)) & wlast_yuv;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            yuv420_data_valid <= 0;
            m_axi_wready_reg <= 0;
            yuv420_data_last <= 0;
            pick_last <= 0;
        end
        else begin
            m_axi_wready_reg <= mst_resp_i.w_ready;

            if((yuv_read_done || (!normal_operation&&!wlast_yuv)) && mst_resp_i.w_ready && yuv420_data_valid) // valid should be deasserted each time after a successfull transfer untill it becomes normal operation
                yuv420_data_valid <= 0;
            else if(ext_state!=IDLE0)
                yuv420_data_valid <= 1;

            if(wready_negedge)
                yuv420_data_last <= yuv420_data_next;

            if(curr_count>0 && normal_operation)
                pick_last <= !mst_resp_i.w_ready;
                
        end
    end
    assign wready_negedge = !mst_resp_i.w_ready & m_axi_wready_reg;

    assign yuv420_data_next     =   (ext_state==Y_EXT)? y_rd_data:      ((ext_state==U_EXT)? u_rd_data:     ((ext_state==V_EXT)? v_rd_data: 32'd0));
    assign yuv420_data          =   pick_last? yuv420_data_last: yuv420_data_next;
    assign yuv420_byte_valid    =   (ext_state!=IDLE0)? 4'b1111: 4'b0000;

    // AXI logic
    
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            wlast_yuv <= 0;
        end
        else begin
            if(wlast_yuv && mst_req_o.w_valid && mst_resp_i.w_ready)
                wlast_yuv <= 0;
            else if(!normal_operation && (curr_count==max_count-1) && mst_req_o.w_valid && mst_resp_i.w_ready) // Add this to end early if there is no latched output
                wlast_yuv <= 1;
            else if((curr_count==max_count) && mst_req_o.w_valid && mst_resp_i.w_ready) // if there is a latched output we end up with 2 cycles at the end
                wlast_yuv <= 1;
        end
    end

    
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            frmptr_rst_pending <= 0;
            dual_buffer_select <= 0;
        end
        else begin
            if(frame_done_pulse_i) begin
                frmptr_rst_pending <= 1;
                dual_buffer_select <= !dual_buffer_select;
            end
            else if(frmptr_rst)
                frmptr_rst_pending <= 0;
        end
    end

    assign frmptr_rst = frmptr_rst_pending & posedge_line_valid;
    assign load_ptr = frmptr_rst | csi_enable_pulse;

    /*always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            line_tracker <= 0;
        end
        else begin
            
            if(posedge_line_valid && !(ext_state_delayed!=ext_state && ext_state==IDLE0) && !yuv_read_done_r && yuv_read_done && !line_valid_yuv_i && !buff_wr_done_latch)
                line_tracker <= line_tracker;
            else begin
                if(posedge_line_valid && !(ext_state_delayed!=ext_state && ext_state==IDLE0))
                    line_tracker <= line_tracker + 1;
                else if(!yuv_read_done_r && yuv_read_done && !line_valid_yuv_i && !buff_wr_done_latch)
                    line_tracker <= line_tracker - 1;
            end
        end
    end*/

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            frame_done_pending <= 0;
            yuv_read_done_r <= 0;
        end
        else begin
            yuv_read_done_r <= yuv_read_done;
            if(frame_wr_done_intr_o)
                frame_done_pending <= 0; 
            else if(frame_done_pulse_i)
                frame_done_pending <= 1;
        end
    end

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            interrupt_counter <= 0;
            frame_wr_done_intr_o <= 0;
        end
        else begin
            if(frame_done_pending & (!yuv_read_done_r && yuv_read_done && !line_valid_yuv_i && !buff_wr_done_latch))
                frame_wr_done_intr_o <= 1;
            else if(interrupt_counter == 23)
                frame_wr_done_intr_o <= 0;

            if(frame_wr_done_intr_o)
                interrupt_counter <= interrupt_counter + 1;
            else
                interrupt_counter <= 0;
        end
    end

    //assign frame_wr_done_intr_o = frame_done_pending & (!yuv_read_done_r && yuv_read_done && !line_valid_yuv_i && !buff_wr_done_latch);
    assign y_addr_start = (dual_buffer_select && double_buff_enable_reg_i)? frame_ptr1_i: frame_ptr0_i;
    assign u_addr_start = y_addr_start + frame_width_i*frame_height_i;
    assign v_addr_start = u_addr_start + (frame_width_i*frame_height_i>>2);
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            req_state <= IDLE1;
            y_awaddr_next <= 0;
            u_awaddr_next <= 0;
            v_awaddr_next <= 0;
        end
        else begin
            if(load_ptr) begin
                y_awaddr_next <= y_addr_start;
                u_awaddr_next <= u_addr_start;
                v_awaddr_next <= v_addr_start;
            end
            else if((req_state!=req_next_state) && (req_next_state==IDLE1)) begin
                if(odd_line) begin
                    y_awaddr_next <= y_awaddr_next + (({3'd0, yuv_wraddr_last}+1)<<2);
                    u_awaddr_next <= u_awaddr_next + (({3'd0, yuv_wraddr_last[7:1]}+1)<<2);
                    v_awaddr_next <= v_awaddr_next + (({3'd0, yuv_wraddr_last[7:1]}+1)<<2);
                end
                else
                    y_awaddr_next <= y_awaddr_next + (({3'd0, yuv_wraddr_last}+1)<<2);
            end
            req_state <= req_next_state;
        end
    end

    always_comb begin
        awvalid[1] = 0;
        awaddr[1] = 0;
        awlen[1] = 0;
        req_next_state = IDLE1;
        case (req_state)
            IDLE1: begin
                if(switch_yuv_buff)
                    req_next_state = SEND_Y_WREQ;
                else
                    req_next_state = IDLE1;
            end
            SEND_Y_WREQ: begin
                awvalid[1] = 1;
                awaddr[1] = y_awaddr_next;
                awlen[1] = yuv_wraddr_last;
                if(mst_resp_i.aw_ready) begin
                    if(odd_line)
                        req_next_state = SEND_U_WREQ;
                    else
                        req_next_state = IDLE1;
                end
                else
                    req_next_state = SEND_Y_WREQ;
            end
            SEND_U_WREQ: begin
                awvalid[1] = 1;
                awaddr[1] = u_awaddr_next;
                awlen[1] = {1'b0, yuv_wraddr_last[7:1]};
                if(mst_resp_i.aw_ready)
                    req_next_state = SEND_V_WREQ;
                else
                    req_next_state = SEND_U_WREQ;
            end
            SEND_V_WREQ: begin
                awvalid[1] = 1;
                awaddr[1] = v_awaddr_next;
                awlen[1] = {1'b0, yuv_wraddr_last[7:1]};
                if(mst_resp_i.aw_ready)
                    req_next_state = IDLE1;
                else
                    req_next_state = SEND_V_WREQ;
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
    // ext_state is at V_EXT while req_state is not at IDLE yet means that the AW channel wasn't sent yet
    assign yuv_stream_stall = (ext_state!=IDLE0 & !mst_resp_i.w_ready) | ((ext_state==V_EXT)&(req_state!=IDLE1)) | (!buff_rd_done & (buff_wr_done_latch | buff_wr_done)); // update this to stall when ext_state!=IDLE0 instead of valid BUG
                                                                                                                                                // Add the buff_rd_done to make sure that we don't write while the buffer is being read
    assign stream_stall_o = yuv_stream_stall;
    /*always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i)
            stream_stall_o <= 0;
        else
            stream_stall_o <= output_select_i? yuv_stream_stall: pixel_stream_stall;  
    end*/

    // tie unused signals
    always_comb begin
        // Initialize signals to avoid latchs first
        mst_req_o.aw = '0;
        mst_req_o.aw.id = '0;
        mst_req_o.aw_valid = 1'b0;
        mst_req_o.aw.cache = 4'd0;
        mst_req_o.aw.atop = 6'd0;
        mst_req_o.w = '0;
        mst_req_o.w_valid = 1'b0;
        mst_req_o.b_ready = 1'b1;
        mst_req_o.ar = '0;
        mst_req_o.ar.id = '0;
        mst_req_o.ar_valid = 1'b1;
        mst_req_o.r_ready = 1'b1;
        // Muxes
        mst_req_o.aw_valid     = awvalid[output_select_i];
        mst_req_o.aw.addr      = awaddr[output_select_i];
        mst_req_o.aw.len       = awlen[output_select_i];
        mst_req_o.aw.size      = awsize[output_select_i];
        mst_req_o.aw.burst     = awburst[output_select_i];
        mst_req_o.w.data       = wdata[output_select_i];
        mst_req_o.w.last       = wlast[output_select_i];
        mst_req_o.w.strb       = wstrb[output_select_i];
        mst_req_o.w_valid      = wvalid[output_select_i];
    end
    // Counter assertion to count the number of (yuv420_data_valid && mst_resp_i.w_ready) occurences during ext_state==Y_EXT and U_EXT and V_EXT
    // When the state moves from Y_EXT to U_EXT the counter should be 0 and when the state moves from U_EXT to V_EXT the counter should be 0
    // When the state moves from V_EXT to IDLE0 the counter should be 0
    // During Y_EXT the counter should reach 129 and during U_EXT and V_EXT the counter should reach 65
    // If the counter doesn't reach the expected value then the assertion is triggered
    `ifndef SYNTHESIS
        // Define the counter
        integer ycounter;
        integer ucounter;
        integer vcounter;
        integer incounter;
        logic posedge_line_valid_latch;
        logic reset;
        logic odd_line_latched_reg;
        logic trigger;
        logic [2:0] y_counter_r;
        assign trigger = negedge_line_valid_out;
        assign reset = posedge_line_valid_latch & ext_state==IDLE0 & ext_state_delayed != ext_state;
        // Reset the counter when transitioning between states
        always @(posedge pixel_clk_i, negedge reset_n_i) begin
            if(!reset_n_i) begin
                ycounter <= 0;
                ucounter <= 0;
                vcounter <= 0;
                incounter <= 0;
                odd_line_latched_reg <= 0;
                y_counter_r <= 0;
            end
            else begin
                if(trigger)
                    y_counter_r <= 0;
                else if(ext_state == Y_EXT && ext_state != ext_state_delayed)
                    y_counter_r <= y_counter_r + 1;

                if(trigger)
                    posedge_line_valid_latch <= 1;
                else if(reset)
                    posedge_line_valid_latch <= 0;

                if(posedge_line_valid)
                    incounter <= 0;
                else if(yuv422_byte_valid_i && !stream_stall_o)
                    incounter <= incounter + 1;

                if (trigger)
                    ycounter <= 0;
                else if(ext_state==Y_EXT && yuv420_data_valid && mst_resp_i.w_ready)
                    ycounter <= ycounter + 1;
                
                if (trigger)
                    ucounter <= 0;
                else if(ext_state==U_EXT && yuv420_data_valid && mst_resp_i.w_ready)
                    ucounter <= ucounter + 1;

                if (trigger)
                    vcounter <= 0;
                else if(ext_state==V_EXT && yuv420_data_valid && mst_resp_i.w_ready)
                    vcounter <= vcounter + 1;
            end
        end

        // Define properties for the assertions
        // disable the assertion if counter is zero
        property p_Y_EXT;
            @(posedge pixel_clk_i)
            (trigger) |-> ##1 ($past(ycounter) == 'd960);
            //(posedge_line_valid) |-> ##1 ($past(ycounter) == 'd128);
        endproperty

        property p_U_EXT;
            @(posedge pixel_clk_i)
            (trigger && odd_line) |-> ##1 ($past(ucounter) == 'd480);
            //(posedge_line_valid && odd_line) |-> ##1 ($past(ucounter) == 'd64);
        endproperty

        property p_V_EXT;
            @(posedge pixel_clk_i)
            (trigger && odd_line) |-> ##1 ($past(vcounter) == 'd480);
            //(posedge_line_valid && odd_line) |-> ##1 ($past(vcounter) == 'd64);
        endproperty

        // Assert the properties
        assert property (p_Y_EXT) else $error("Assertion failed: counter did not reach 960 in Y_EXT state, counter=%0d", $past(ycounter));
        assert property (p_U_EXT) else $error("Assertion failed: counter did not reach 480 in U_EXT state, counter=%0d", $past(ucounter));
        assert property (p_V_EXT) else $error("Assertion failed: counter did not reach 480 in V_EXT state, counter=%0d", $past(vcounter));

        // Address sent should be YYUV YYUV YYUV YYUV Assertion check that the address is sent in the correct order
        // Check that the first and the second address request on the AW channel is between frame_ptr_i and frame_ptr1_i 
        // and the third is between frame_ptr1_i and frame_ptr2_i 
        // and fourth address request is larger than frame_ptr2_i
    `endif

endmodule