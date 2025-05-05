/* 
    File: ipu_debayer_filter.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: Gaurav Singh www.CircuitValley.com

    Functionality:
    Extended from Gaurav Singh implementation for debayer filter
    
    -   Support RAW10 and RAW8 data type debayering
    -   Support 1, 2 or 4 Pixel Per clock input and output
    -   Support RGGB, BGGR, RGBG, GRBG bayering filters to support different camera modules
    -   Input characteristics: incase of RAW10 data type input is 4 pixels per cycle and input
        for example in case of BGGR formatorder should be GBGB in case of odd rows and 
        RGRG in case of even rows, where LSByte is the first pixel transmitted and MSByte is the last pixel transmitted.
    -   Output should be at the same throughtput as input

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
module  ipu_debayer_filter (
                        input                   clk_i,
                        input                   reset_n_i,
                        input           [5:0]   data_type_i,                // RAW8 or RAW10
                        input           [2:0]   pixel_per_clk_i,            // single, dual or quad
                        input           [1:0]   bayer_filter_type_i,        // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
                        input                   frame_valid_i,              // This signal is high as long as a frame transmission is in process
                        input                   line_valid_i,               // This signal is high as long as a line transmission is in process
                        input                   line_done_pulse_i,
                        input           [95:0]  pixel_data_i,               // Pixel data composed of 5 bytes max num of bytes needed for RAW10
                        input           [3:0]   pixel_data_valid_i,         // Pixel data valid signal for each byte in the pixel data
                        output logic            line_valid_sync_o,          // synchronized line_valid signal with the data because of the buffering
                        output logic    [3:0]   pixel_data_valid_o,         // Each bit of these correspond to one RGB component of the pixel_data_o
                        output logic    [119:0] pixel_data_o,               // Maximum number of RGB components = 3*PPC_max*PIXELWIDTH_max = 3*4*10 = 120
                        output logic            frame_done_pulse_o
);
    localparam ADDR_WIDTH = 11;
    localparam DATA_WIDTH = 40;
    localparam VALID_WIDTH = 4;
    localparam PIXEL_WIDTH = 10;
    localparam PIXEL_WIDTH10 = 10;
    localparam PIXEL_WIDTH8 = 8;
    localparam [1:0] p0 [8] = {0,0,0,2,2,1,1,0}; // pointer to map ram outputs0 to pipe inputs
    localparam [1:0] p1 [8] = {2,2,1,1,0,0,2,2}; // pointer to map ram outputs1 to pipe inputs
    localparam [1:0] p2 [8] = {1,1,2,0,1,2,0,1}; // pointer to map ram outputs2 to pipe inputs
    logic [(DATA_WIDTH + VALID_WIDTH)-1:0] pixel_data_trun, pixel_data_trun_delayed, pixel_data_trun_delayed2;
    logic line_counter; //only 1 bit so does not actually counts lines of the frame , needed determine if line is odd or even
    logic line_valid_reg;
    logic [1:0] read_ram_index; 	//which line RAM is being focused to read for even lines,  (not which address is being read from line RAM) Must be 2 bits only
    logic [1:0] read_ram_index_plus_1;
    logic [1:0] read_ram_index_minus_1;
    logic [1:0] write_ram_select;	//which line RAM is begin written
    logic [ADDR_WIDTH-1:0] line_address_wr, line_address_rd, line_address_wr_last; 		//which address is being read and written 
    logic [1:0] [(DATA_WIDTH+VALID_WIDTH-1):0] ram_out;
    logic [2:0] [(DATA_WIDTH+VALID_WIDTH-1):0] ram_out_mapped;
    logic [1:0] ram_write_enable;
    logic line_valid_negedge;
    logic frame_done_pulse_pending;
    typedef enum logic [1:0] {IDLE, ONE_LINE_FILLED, ONE_LINE_EXTRACT} state_type;
    state_type current_state, current_state_delayed, current_state_delayed2;
    logic [2:0] idx;
    logic last_line_read_done;
    logic line_active, line_active_corrected;
    logic pipe_stall;
    logic line_done_pulse_delayed;    
    logic line_done_pulse_delayed2;
    logic line_done_pulse_sync;
    logic line_valid_sync;
    // always_ff@(posedge clk_i or negedge reset_n_i) begin
    //     if(!reset_n_i)
    //         debug_counter <= 0;
    //     else begin
    //         if(frame_done_pulse_o)
    //             debug_counter <= 0;
    //         else if(|pixel_data_valid_i)
    //             debug_counter <= debug_counter + 1;
    //     end
    // end

    assign ram_write_enable = (|(pixel_data_trun_delayed2[DATA_WIDTH +:VALID_WIDTH]))? write_ram_select: 2'b00; // bug solved

    assign pixel_data_trun = {pixel_data_valid_i, pixel_data_i[DATA_WIDTH-1:0]};

    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            line_active <= 0;
        else begin
            if(pixel_data_valid_i)
                line_active <= 1;
            else if(line_done_pulse_delayed)
                line_active <= 0;
        end
    end


    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            line_valid_sync <= 0;
        else begin
            if(current_state != IDLE) begin
                if(pixel_data_valid_i)
                    line_valid_sync <= 1;
                else if(line_done_pulse_sync)
                    line_valid_sync <= 0;
            end
        end
    end
    assign line_valid_sync_o = line_valid_sync | (|pixel_data_valid_o);
    assign line_active_corrected = line_active | pixel_data_valid_i;
            // stall pipe when line didn't end and valid = 0, or when line 1 isn't filled yet
    assign pipe_stall = (line_active_corrected & (!pixel_data_trun_delayed2[DATA_WIDTH +:VALID_WIDTH])) | current_state_delayed2==IDLE;
    
    // The 4 buffer lines store pixel data input for further debayer processing, debayering needs at least 2 lines and atmost 3 lines to start. A line buffer can't be read and written at the same time.
    // 
    mem_dual_port_wrapper#( .ADDR_WIDTH             (   ADDR_WIDTH                          ),
                            .DATA_WIDTH             (   DATA_WIDTH + VALID_WIDTH            ),
                            .MEM_NUM                (   2                                   )                   
                    )
        mem_dual_port_wrapper_i(
                            .reset_n_i              (   reset_n_i                           ),
                            .clk_i                  (   clk_i                               ),
                            .ram_write_enable_i     (   ram_write_enable                    ),
                            .ram_read_enable_i      (   2'b11                               ),
                            .ram_write_address_i    (   line_address_wr                     ),
                            .ram_data_i             (   pixel_data_trun_delayed2            ),
                            .ram_read_address_i     (   line_address_rd                     ),
                            .ram_data_o             (   ram_out                             )
                    );

    assign line_valid_negedge = !line_valid_i & line_valid_reg;

    // FSM for output valid control
    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i) begin
            current_state <= IDLE;
            current_state_delayed <= IDLE;
            current_state_delayed2 <= IDLE;
        end
        else begin
            case(current_state)
            IDLE: begin
                if(line_done_pulse_delayed2)
                    current_state <= ONE_LINE_FILLED;
            end
            ONE_LINE_FILLED: begin
                if(!frame_valid_i)
                    current_state <= ONE_LINE_EXTRACT;                
            end
            ONE_LINE_EXTRACT: begin
                if(last_line_read_done)
                    current_state <= IDLE;
            end
            endcase
            current_state_delayed <= current_state;
            current_state_delayed2 <= current_state_delayed;
        end
    end

    assign last_line_read_done = (current_state == ONE_LINE_EXTRACT) & (line_address_rd>=line_address_wr_last);

    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            line_address_rd <= 0;
            line_valid_reg <= 0;
            pixel_data_trun_delayed <= 0;
            pixel_data_trun_delayed2 <= 0;
            line_done_pulse_delayed <= 0;
            line_done_pulse_delayed2  <= 0;
        end
        else begin
            line_valid_reg <= line_valid_i;
            pixel_data_trun_delayed <= pixel_data_trun;
            pixel_data_trun_delayed2 <= pixel_data_trun_delayed;

            line_done_pulse_delayed <= line_done_pulse_i;
            line_done_pulse_delayed2 <= line_done_pulse_delayed;
                
            //* line address read logic
            if(line_done_pulse_i || frame_done_pulse_o) // reset line address read when going into wait 3 cycles state
                line_address_rd <= 0;
            else if((pixel_data_valid_i) || current_state==ONE_LINE_EXTRACT)
                line_address_rd <= line_address_rd+1;
        end
    end

    assign frame_done_pulse_o = frame_done_pulse_pending && !line_valid_sync_o;

    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i)
            frame_done_pulse_pending <= 0;
        else begin
            if(frame_done_pulse_o)
                frame_done_pulse_pending <= 0;
            else if(last_line_read_done)
                frame_done_pulse_pending <= 1;
        end
    end

    always @(posedge clk_i or negedge reset_n_i) begin	 //address should increment at "falling" edge of "ram_clk". It is inverted from clk_i
        if(!reset_n_i) begin
            line_address_wr <= 1;
            line_address_wr_last <= 0;
        end
        else begin
            if ((!line_valid_i && line_valid_reg) || line_done_pulse_delayed2 ) begin
                line_address_wr <= 1;
                line_address_wr_last <= line_address_wr; 
            end
            else
                if (pixel_data_trun_delayed2[DATA_WIDTH +:VALID_WIDTH])
                    line_address_wr <= line_address_wr + 1'b1;
        end
    end

    always @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            write_ram_select <= 2'b01;	//on first line ram[0] will be selected 
            line_counter <= 1;				//on first line line_counter --> 1 --> odd 
            read_ram_index <= 2'd0;		//on first line read from ram 2 (1 + 1 at rising edge of line_valid_i)
            read_ram_index_plus_1 <= 2'd1;
            read_ram_index_minus_1 <= 2'd2;
        end
        else begin
            if((line_valid_negedge || line_done_pulse_i)) begin
                write_ram_select <= {write_ram_select[0], write_ram_select[1]};
            end

            if(current_state==IDLE) begin
                read_ram_index <= 2'd0;		//on first line read from ram 2 (1 + 1 at rising edge of line_valid_i)
                read_ram_index_plus_1 <= 2'd1;
                read_ram_index_minus_1 <= 2'd2;
                line_counter <= 1'b1;
            end
            else if(line_done_pulse_sync) begin // current line out is done
                line_counter <= !line_counter;
                read_ram_index 	<= read_ram_index  + 1'b1;
                read_ram_index_plus_1  <= read_ram_index_plus_1 	+ 1'b1;
                read_ram_index_minus_1  <= read_ram_index_minus_1 	+ 1'b1;
                if(read_ram_index + 1 == 3)
                    read_ram_index <= 2'd0;
                if(read_ram_index_plus_1 + 1 == 3)
                    read_ram_index_plus_1 <= 2'd0;
                if(read_ram_index_minus_1 + 1 == 3)
                    read_ram_index_minus_1 <= 2'd0;
            end
        end
    end
    //************** Mapping logic
    // p0 [8] = {0,0,0,2,2,1,1,0,0};
    // p1 [8] = {2,2,1,1,0,0,2,2,1};
    // p2 [8] = {1,1,2,0,1,2,0,1,2};
    always_comb begin
        ram_out_mapped[p0[idx]] = ram_out[0];
        ram_out_mapped[p1[idx]] = ram_out[1];
        ram_out_mapped[p2[idx]] = pixel_data_trun_delayed2;
    end

    always @(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            idx <= 0;
        end
        else begin
            if(line_done_pulse_delayed2) begin
                idx <= idx + 1;
                if(idx==7)
                    idx <= 2;
            end
            else if(current_state==IDLE)
                idx <= 0;
        end
    end

    //*************
    ipu_bilinear_interpolation #(   .DATA_WIDTH(DATA_WIDTH), 
                                    .VALID_WIDTH(VALID_WIDTH))
        ipu_bilinear_interpolation_i(
                                    .clk_i(clk_i),
                                    .reset_n_i(reset_n_i),
                                    .data_type_i(data_type_i),
                                    .pixel_per_clk_i(pixel_per_clk_i),
                                    .bayer_filter_type_i(bayer_filter_type_i),
                                    .pixel_line_i(ram_out_mapped),
                                    .line_done_pulse_i(line_done_pulse_delayed2),
                                    .line_counter_i(line_counter),
                                    .pipe_stall_i(pipe_stall),
                                    .read_ram_index_i(read_ram_index),
                                    .read_ram_index_plus_1_i(read_ram_index_plus_1),
                                    .read_ram_index_minus_1_i(read_ram_index_minus_1),
                                    .line_done_pulse_o(line_done_pulse_sync),
                                    .pixel_data_valid_o(pixel_data_valid_o),
                                    .pixel_data_o(pixel_data_o)
                    );

    `ifndef SYNTHESIS
        // Define the counter
        integer outcounter;
        always @(posedge clk_i, negedge reset_n_i) begin
            if(!reset_n_i)
                outcounter <= 0;
            else begin
                if(line_done_pulse_sync)
                    outcounter <= 0;
                else if(pixel_data_valid_o)
                    outcounter <= outcounter + 1;
            end
        end
    `endif
endmodule