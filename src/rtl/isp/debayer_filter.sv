/* 
    File: debayer_filter.sv
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
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
`include "mipi_csi_data_types.svh"
`include "rgb_locate.svh"
module  debayer_filter (
                        input                   clk_i,
                        input                   reset_n_i,
                        input                   stream_stall_i,
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
    logic [(DATA_WIDTH + VALID_WIDTH)-1:0] pixel_data_trun;
    logic odd_signal;
    logic line_counter; //only 1 bit so does not actually counts lines of the frame , needed determine if line is odd or even

    logic [(PIXEL_WIDTH - 1):0]R1[4];
    logic [(PIXEL_WIDTH - 1):0]R2[4];
    logic [(PIXEL_WIDTH - 1):0]R3[4];
    logic [(PIXEL_WIDTH - 1):0]R4[4];


    logic [(PIXEL_WIDTH - 1):0]B1[4];
    logic [(PIXEL_WIDTH - 1):0]B2[4];
    logic [(PIXEL_WIDTH - 1):0]B3[4];
    logic [(PIXEL_WIDTH - 1):0]B4[4];

    logic [(PIXEL_WIDTH - 1):0]G1[4];
    logic [(PIXEL_WIDTH - 1):0]G2[4];
    logic [(PIXEL_WIDTH - 1):0]G3[4];
    logic [(PIXEL_WIDTH - 1):0]G4[4];


    logic [(PIXEL_WIDTH - 1):0]R1_even[4];
    logic [(PIXEL_WIDTH - 1):0]R2_even[4];
    logic [(PIXEL_WIDTH - 1):0]R3_even[4];
    logic [(PIXEL_WIDTH - 1):0]R4_even[4];


    logic [(PIXEL_WIDTH - 1):0]B1_even[4];
    logic [(PIXEL_WIDTH - 1):0]B2_even[4];
    logic [(PIXEL_WIDTH - 1):0]B3_even[4];
    logic [(PIXEL_WIDTH - 1):0]B4_even[4];

    logic [(PIXEL_WIDTH - 1):0]G1_even[4];
    logic [(PIXEL_WIDTH - 1):0]G2_even[4];
    logic [(PIXEL_WIDTH - 1):0]G3_even[4];
    logic [(PIXEL_WIDTH - 1):0]G4_even[4];

    logic [(PIXEL_WIDTH - 1):0]R1_odd[4];
    logic [(PIXEL_WIDTH - 1):0]R2_odd[4];
    logic [(PIXEL_WIDTH - 1):0]R3_odd[4];
    logic [(PIXEL_WIDTH - 1):0]R4_odd[4];

    logic [(PIXEL_WIDTH - 1):0]B1_odd[4];
    logic [(PIXEL_WIDTH - 1):0]B2_odd[4];
    logic [(PIXEL_WIDTH - 1):0]B3_odd[4];
    logic [(PIXEL_WIDTH - 1):0]B4_odd[4];


    logic [(PIXEL_WIDTH - 1):0]G1_odd[4];
    logic [(PIXEL_WIDTH - 1):0]G2_odd[4];
    logic [(PIXEL_WIDTH - 1):0]G3_odd[4];
    logic [(PIXEL_WIDTH - 1):0]G4_odd[4];
    
    logic line_valid_reg;
    logic [1:0]read_ram_index; 	//which line RAM is being focused to read for even lines,  (not which address is being read from line RAM) Must be 2 bits only
    logic [1:0] read_ram_index_plus_1;
    logic [1:0] read_ram_index_minus_1;
    logic [3:0]write_ram_select;	//which line RAM is begin written
    logic [ADDR_WIDTH-1:0] line_address_wr, line_address_rd, line_address_wr_last; 		//which address is being read and written 
    logic [3:0] [(DATA_WIDTH+VALID_WIDTH-1):0] ram_out;
    logic [(DATA_WIDTH-1):0]ram_out_reg[3:0];
    logic [(DATA_WIDTH-1):0]last_ram_outputs[3:0]; //one clock cycle delayed output of line RAMs
    logic [(DATA_WIDTH-1):0]last_ram_outputs_stage2[3:0]; //two clock cycle delayed output of RAMs 
    logic [VALID_WIDTH-1:0] ram_out_reg_valids[3:0];
    logic [VALID_WIDTH-1:0] last_ram_valids[3:0];
    logic [VALID_WIDTH-1:0] last_ram_valids_reg[3:0];
    logic [((4*10)-1):0]ram_out_reg_4ppc_raw10[3:0];
    logic [((4*10)-1):0]last_ram_outputs_4ppc_raw10[3:0];
    logic [((4*10)-1):0]last_ram_outputs_stage2_4ppc_raw10[3:0];
    logic [((2*10)-1):0]ram_out_reg_2ppc_raw10[3:0];
    logic [((2*10)-1):0]last_ram_outputs_2ppc_raw10[3:0];
    logic [((2*10)-1):0]last_ram_outputs_stage2_2ppc_raw10[3:0];
    logic [((1*10)-1):0]ram_out_reg_1ppc_raw10[3:0];
    logic [((1*10)-1):0]last_ram_outputs_1ppc_raw10[3:0];
    logic [((1*10)-1):0]last_ram_outputs_stage2_1ppc_raw10[3:0];
    logic [((4*8)-1):0]ram_out_reg_4ppc_raw8[3:0];
    logic [((4*8)-1):0]last_ram_outputs_4ppc_raw8[3:0];
    logic [((4*8)-1):0]last_ram_outputs_stage2_4ppc_raw8[3:0];
    logic [((2*8)-1):0]ram_out_reg_2ppc_raw8[3:0];
    logic [((2*8)-1):0]last_ram_outputs_2ppc_raw8[3:0];
    logic [((2*8)-1):0]last_ram_outputs_stage2_2ppc_raw8[3:0];
    logic [((1*8)-1):0]ram_out_reg_1ppc_raw8[3:0];
    logic [((1*8)-1):0]last_ram_outputs_1ppc_raw8[3:0];
    logic [((1*8)-1):0]last_ram_outputs_stage2_1ppc_raw8[3:0];
    logic [3:0] ram_write_enable;
    logic ram_clk;
    logic [1:0] not_used2b;
    logic [((DATA_WIDTH*3)-1):0]ram_pipe[3:0];
    logic [((4*10*3)-1):0]ram_pipe_4ppc_raw10[3:0];
    logic [((2*10*3)-1):0]ram_pipe_2ppc_raw10[3:0];
    logic [((1*10*3)-1):0]ram_pipe_1ppc_raw10[3:0];
    logic [((4*8*3)-1):0]ram_pipe_4ppc_raw8[3:0];
    logic [((2*8*3)-1):0]ram_pipe_2ppc_raw8[3:0];
    logic [((1*8*3)-1):0]ram_pipe_1ppc_raw8[3:0];
    logic line_valid_negedge;
    logic [2:0] overload_counter, read_counter;
    logic wait_1line_done, wait_2lines_done;
    logic output_is_valid;
    logic [VALID_WIDTH-1:0] pixel_data_valid_reg;
    logic line_valid_sync_reg;
    logic frame_done_pulse_pending;
    logic [VALID_WIDTH-1:0] pixel_data_valid_reg2;
    logic line_valid_sync_reg2;
    typedef enum logic [2:0] {IDLE, WAIT_3C1, OUTPUT_VALID1, WAIT_LINE_NEGEDGE, WAIT_3C2 , OUTPUT_VALID2} state_type;
    state_type current_state, next_state;
    integer i;
    integer input_width;
    integer pixel_width;
    logic line_done_latch;
    logic [31:0] debug_counter;
    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i)
            debug_counter <= 0;
        else begin
            if(frame_done_pulse_o)
                debug_counter <= 0;
            else if(|pixel_data_valid_i && !stream_stall_i)
                debug_counter <= debug_counter + 1;
        end
    end
    //assign ram_clk = !clk_i; //! is that fine in asic?
    assign ram_write_enable = (|(pixel_data_valid_i))? write_ram_select: 4'b0000; // bug solved
    // truncation logic

    assign pixel_data_trun = {pixel_data_valid_i, pixel_data_i[DATA_WIDTH-1:0]};

    // The 4 buffer lines store pixel data input for further debayer processing, debayering needs at least 2 lines and atmost 3 lines to start. A line buffer can't be read and written at the same time.
    // 
    dual_port_ram_wrapper#( .ADDR_WIDTH             (   ADDR_WIDTH                          ),
                            .DATA_WIDTH             (   DATA_WIDTH + VALID_WIDTH            ),
                            .MEM_NUM                (   4                                   )                   
                    )
    line_ram_wrapper_i(
                            .reset_n_i              (   reset_n_i                           ),
                            .clk_i                  (   clk_i                             ),
                            .ram_write_enable_i     (   ram_write_enable                    ),
                            .ram_read_enable_i      (   4'b1111                             ),
                            .ram_write_address_i    (   line_address_wr                     ),
                            .ram_data_i             (   pixel_data_trun                     ),
                            .ram_read_address_i     (   line_address_rd                     ),
                            .ram_data_o             (   ram_out                             )
                    );

    assign line_valid_negedge = !line_valid_i & line_valid_reg;
    // After frame_valid signal goes 0->1 we need to wait for 2 lines to be written into the RAMs
    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i) begin
            wait_1line_done <= 0;
            wait_2lines_done <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                if(!frame_valid_i) begin// reset
                    wait_1line_done <= 0;
                    wait_2lines_done <= 0;
                end
                else if(line_valid_negedge || line_done_pulse_i) begin
                    wait_1line_done <= 1;
                    wait_2lines_done <= wait_1line_done;
                end
            end
        end
    end
    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            line_done_latch <= 0;
        else begin
            if(line_done_pulse_i) //&& (current_state == OUTPUT_VALID1 || current_state == OUTPUT_VALID2))
                line_done_latch <= 1;
            else if(current_state == WAIT_3C1 && !stream_stall_i)
                line_done_latch <= 0;
            end
    end
    // FSM for output valid control
    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            current_state <= IDLE;
        else
            if(!stream_stall_i)
                current_state <= next_state;
    end

    always_comb begin
        next_state = IDLE;
        case(current_state)
        IDLE: begin // wait untill 2 lines are filled
            if(wait_2lines_done)
                next_state = WAIT_3C1;
            else
                next_state = IDLE;
            end
        WAIT_3C1: begin // wait 3 cycles untill pixel is shifted to the middle of the ram pipe
            if(read_counter==3)
                next_state = OUTPUT_VALID1;
            else
                next_state = WAIT_3C1;
            end
        OUTPUT_VALID1: begin // pixel output is valid
            if(frame_valid_i && (line_address_rd >= line_address_wr_last) && (read_counter==2)) // 
                next_state = WAIT_LINE_NEGEDGE;
            else if(!frame_valid_i && (line_address_rd >= line_address_wr_last) && (read_counter==2)) // when frame ends wait untill all buffer line is read and pixel is shifted to the middle of the ram pipe
                next_state = WAIT_3C2;
            else
                next_state = OUTPUT_VALID1;
            end
        WAIT_LINE_NEGEDGE: begin // wait unitill second line is written
            if(!frame_valid_i) // if the frame end gets delayed
                next_state = WAIT_3C2;
            else if(line_valid_negedge || line_done_pulse_i || line_done_latch)
                next_state = WAIT_3C1;
            else
                next_state = WAIT_LINE_NEGEDGE;
            end
        WAIT_3C2: begin
            if(overload_counter==1) // when overload counter ==2 this means we transmitted the last 2 lines
                next_state = IDLE;
            else if(read_counter==3) // output the last 2 lines stuck in the line buffers because you neglicted 2 lines earlier
                next_state = OUTPUT_VALID2;
            else
                next_state = WAIT_3C2;
            end
        OUTPUT_VALID2: begin // pixel output is valid send the last 2 lines
            if((line_address_rd >= line_address_wr_last) && (read_counter==2)) // when frame ends wait untill all buffer line is read and pixel is shifted to the middle of the ram pipe
                next_state = WAIT_3C2;
            else
                next_state = OUTPUT_VALID2;
            end
        endcase
    end

    assign output_is_valid = (current_state==OUTPUT_VALID1) || (current_state==OUTPUT_VALID2);
    //assign pixel_data_valid_o = (output_is_valid)? last_ram_valids_reg[read_ram_index]:4'd0;
    //assign line_valid_sync_o = output_is_valid;
    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            pixel_data_valid_o <= 0;
            line_valid_sync_o <= 0;
            pixel_data_valid_reg <= 0;
            line_valid_sync_reg <= 0;
            pixel_data_valid_reg2 <= 0;
            line_valid_sync_reg2 <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                pixel_data_valid_reg <= (output_is_valid)? last_ram_valids_reg[read_ram_index]:4'd0;
                pixel_data_valid_reg2 <= pixel_data_valid_reg;
                pixel_data_valid_o <= pixel_data_valid_reg2;
                line_valid_sync_reg <= output_is_valid;
                line_valid_sync_reg2 <= line_valid_sync_reg;
                line_valid_sync_o <= line_valid_sync_reg2;
            end
        end
    end

    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            line_address_rd <= 0;
            overload_counter <= 0;
            read_counter <= 0;
            line_valid_reg <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                line_valid_reg <= line_valid_i;
                //* read counter logic
                if(current_state!=next_state)
                    read_counter <= 0;
                else if((current_state == WAIT_3C1) || (current_state == WAIT_3C2) || ((output_is_valid) && line_address_rd>=line_address_wr_last))
                    read_counter <= read_counter+1;

                //* overload counter logic
                if(current_state == WAIT_LINE_NEGEDGE)
                    overload_counter <= 0;
                else if(current_state==OUTPUT_VALID2 && next_state==WAIT_3C2)
                    overload_counter <= overload_counter+1;
                    
                //* line address read logic
                if((current_state != next_state && ((next_state==WAIT_3C1)||(next_state==WAIT_3C2)))) // reset line address read when going into wait 3 cycles state
                    line_address_rd <= 0;
                else if((current_state==WAIT_3C1 || output_is_valid || current_state==WAIT_3C2) && (line_address_rd<=line_address_wr_last))
                    line_address_rd <= line_address_rd+1;
            end
        end
    end

    assign frame_done_pulse_o = frame_done_pulse_pending && !line_valid_sync_o;
    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i)
            frame_done_pulse_pending <= 0;
        else begin
            if(frame_done_pulse_o)
                frame_done_pulse_pending <= 0;
            else if(current_state==OUTPUT_VALID2 && next_state==WAIT_3C2)
                frame_done_pulse_pending <= 1;
        end
    end
    always @(posedge clk_i or negedge reset_n_i) begin	 //address should increment at "falling" edge of "ram_clk". It is inverted from clk_i
        if(!reset_n_i) begin
            line_address_wr <= 1;
            line_address_wr_last <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                if ((!line_valid_i && line_valid_reg) || line_done_pulse_i ) begin
                    line_address_wr <= 1;
                    line_address_wr_last <= line_address_wr; 
                end
                else
                    if (pixel_data_valid_i)
                        line_address_wr <= line_address_wr + 1'b1;
            end
        end
    end

    always @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            write_ram_select <= 4'b0001;	//on first line ram[0] will be selected 
            line_counter <= 1;				//on first line line_counter --> 1 --> odd 
            read_ram_index <= 2'd0;		//on first line read from ram 2 (1 + 1 at rising edge of line_valid_i)
            read_ram_index_plus_1 <= 2'd1;
            read_ram_index_minus_1 <= 2'd3;
            
        end
        else begin
            if((line_valid_negedge || line_done_pulse_i) && !stream_stall_i) begin
                write_ram_select <= {write_ram_select[2:0], write_ram_select[3]};
                line_counter <= !line_counter;
            end

            if(current_state==IDLE) begin
                read_ram_index <= 2'd0;		//on first line read from ram 2 (1 + 1 at rising edge of line_valid_i)
                read_ram_index_plus_1 <= 2'd1;
                read_ram_index_minus_1 <= 2'd3;
            end
            else if((output_is_valid) && (current_state!=next_state) && !stream_stall_i) begin // current line out is done
                read_ram_index 	<= read_ram_index  + 1'b1;
                read_ram_index_plus_1  <= read_ram_index_plus_1 	+ 1'b1;
                read_ram_index_minus_1  <= read_ram_index_minus_1 	+ 1'b1;
            end
        end
    end

    always @(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_valids[i]                   <= 0;
                last_ram_valids[i] 		                <= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_4ppc_raw10[i]               <= 0;
                last_ram_outputs_4ppc_raw10[i] 		    <= 0;
                last_ram_outputs_stage2_4ppc_raw10[i] 	<= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_2ppc_raw10[i]               <= 0;
                last_ram_outputs_2ppc_raw10[i] 		    <= 0;
                last_ram_outputs_stage2_2ppc_raw10[i] 	<= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_1ppc_raw10[i]               <= 0;
                last_ram_outputs_1ppc_raw10[i] 		    <= 0;
                last_ram_outputs_stage2_1ppc_raw10[i] 	<= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_4ppc_raw8[i]                <= 0;
                last_ram_outputs_4ppc_raw8[i] 		    <= 0;
                last_ram_outputs_stage2_4ppc_raw8[i] 	<= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_2ppc_raw8[i]                <= 0;
                last_ram_outputs_2ppc_raw8[i] 		    <= 0;
                last_ram_outputs_stage2_2ppc_raw8[i] 	<= 0;
            end

            for ( i = 0; i < 4; i=i+1) begin
                ram_out_reg_1ppc_raw8[i]                <= 0;
                last_ram_outputs_1ppc_raw8[i] 		    <= 0;
                last_ram_outputs_stage2_1ppc_raw8[i] 	<= 0;
            end
        end
        else begin
            if(!stream_stall_i) begin
                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_valids[i]       <= ram_out[i][DATA_WIDTH +:VALID_WIDTH];
                    last_ram_valids[i] 		    <= ram_out_reg_valids[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_4ppc_raw10[i]              <= ram_out[i][(DATA_WIDTH-1):0];
                    last_ram_outputs_4ppc_raw10[i] 		<= ram_out_reg_4ppc_raw10[i];
                    last_ram_outputs_stage2_4ppc_raw10[i] 	<= last_ram_outputs_4ppc_raw10[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_2ppc_raw10[i]              <= ram_out[i][19:0];
                    last_ram_outputs_2ppc_raw10[i] 		<= ram_out_reg_2ppc_raw10[i];
                    last_ram_outputs_stage2_2ppc_raw10[i] 	<= last_ram_outputs_2ppc_raw10[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_1ppc_raw10[i]              <= ram_out[i][9:0];
                    last_ram_outputs_1ppc_raw10[i] 		<= ram_out_reg_1ppc_raw10[i];
                    last_ram_outputs_stage2_1ppc_raw10[i] 	<= last_ram_outputs_1ppc_raw10[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_4ppc_raw8[i]              <= ram_out[i][31:0];
                    last_ram_outputs_4ppc_raw8[i] 		<= ram_out_reg_4ppc_raw8[i];
                    last_ram_outputs_stage2_4ppc_raw8[i] 	<= last_ram_outputs_4ppc_raw8[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_2ppc_raw8[i]              <= ram_out[i][15:0];
                    last_ram_outputs_2ppc_raw8[i] 		<= ram_out_reg_2ppc_raw8[i];
                    last_ram_outputs_stage2_2ppc_raw8[i] 	<= last_ram_outputs_2ppc_raw8[i];
                end

                for ( i = 0; i < 4; i=i+1) begin
                    ram_out_reg_1ppc_raw8[i]              <= ram_out[i][7:0];
                    last_ram_outputs_1ppc_raw8[i] 		<= ram_out_reg_1ppc_raw8[i];
                    last_ram_outputs_stage2_1ppc_raw8[i] 	<= last_ram_outputs_1ppc_raw8[i];
                end
            end
        end
    end

    always@(*) begin
        if (line_counter) begin
            for (i=0; i < 4; i=i+1) begin
                R1[i] = R1_odd[i];
                R2[i] = R2_odd[i];
                R3[i] = R3_odd[i];
                R4[i] = R4_odd[i];
                
                G1[i] = G1_odd[i];
                G2[i] = G2_odd[i];
                G3[i] = G3_odd[i];
                G4[i] = G4_odd[i];
                
                B1[i] = B1_odd[i];
                B2[i] = B2_odd[i];
                B3[i] = B3_odd[i];	
                B4[i] = B4_odd[i];
            end
        end
        else begin	//even rows
            for (i=0; i < 4; i=i+1) begin
                R1[i] = R1_even[i];
                R2[i] = R2_even[i];
                R3[i] = R3_even[i];
                R4[i] = R4_even[i];
                
                G1[i] = G1_even[i];
                G2[i] = G2_even[i];
                G3[i] = G3_even[i];
                G4[i] = G4_even[i];
                
                B1[i] = B1_even[i];
                B2[i] = B2_even[i];
                B3[i] = B3_even[i];
                B4[i] = B4_even[i];
            end
        end
    end

    always @(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            not_used2b <= 0;
            odd_signal <= 1;
            pixel_data_o <= 0;
            for (i=0; i < 4 ; i=i+1)
                last_ram_valids_reg[i] <= 0;
        end
        else begin
            // put zeros in unused pixels
            if(!stream_stall_i) begin
                pixel_data_o <= 0;
                if(pixel_data_valid_o[0])
                    odd_signal <= !odd_signal;
                else if(!pixel_data_valid_o[0])
                    odd_signal <= 1;

                for (i=0; i < 4 ; i=i+1)
                begin
                    last_ram_valids_reg[i] <= last_ram_valids[i];
                    if(pixel_per_clk_i != 1) begin
                        if(pixel_per_clk_i>i) begin
                            {not_used2b,pixel_data_o[((i*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH*2)) +:PIXEL_WIDTH]} <= {(({2'd0, R1[i]} + R2[i]) + R3[i]) + R4[i]} >> 2; //R
                            {not_used2b,pixel_data_o[((i*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH  )) +:PIXEL_WIDTH]} <= {(({2'd0, G1[i]} + G2[i]) + G3[i]) + G4[i]} >> 2; //G
                            {not_used2b,pixel_data_o[ (i*(PIXEL_WIDTH * 3)) 	   			   +:PIXEL_WIDTH]} <= {(({2'd0, B1[i]} + B2[i]) + B3[i]) + B4[i]} >> 2; //B
                        end
                    end
                    else begin
                        if(!odd_signal) begin
                            {not_used2b,pixel_data_o[((0*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH*2)) +:PIXEL_WIDTH]} <= {(({2'd0, R1[0]} + R2[0]) + R3[0]) + R4[0]} >> 2; //R
                            {not_used2b,pixel_data_o[((0*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH  )) +:PIXEL_WIDTH]} <= {(({2'd0, G1[0]} + G2[0]) + G3[0]) + G4[0]} >> 2; //G
                            {not_used2b,pixel_data_o[ (0*(PIXEL_WIDTH * 3)) 	   			   +:PIXEL_WIDTH]} <= {(({2'd0, B1[0]} + B2[0]) + B3[0]) + B4[0]} >> 2; //B
                        end
                        else begin
                            {not_used2b,pixel_data_o[((0*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH*2)) +:PIXEL_WIDTH]} <= {(({2'd0, R1[1]} + R2[1]) + R3[1]) + R4[1]} >> 2; //R
                            {not_used2b,pixel_data_o[((0*(PIXEL_WIDTH * 3)) + (PIXEL_WIDTH  )) +:PIXEL_WIDTH]} <= {(({2'd0, G1[1]} + G2[1]) + G3[1]) + G4[1]} >> 2; //G
                            {not_used2b,pixel_data_o[ (0*(PIXEL_WIDTH * 3)) 	   			   +:PIXEL_WIDTH]} <= {(({2'd0, B1[1]} + B2[1]) + B3[1]) + B4[1]} >> 2; //B
                        end
                    end
                end
            end
        end
    end
    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i)begin
            input_width <= 0;
            pixel_width <= 0;
        end
        else begin
            case({pixel_per_clk_i, data_type_i})
            {3'd4,`RAW10}: input_width <= 40;
            {3'd2,`RAW10}: input_width <= 20;
            {3'd1,`RAW10}: input_width <= 10;
            {3'd4,`RAW8}:  input_width <= 32;
            {3'd2,`RAW8}:  input_width <= 16;
            {3'd1,`RAW8}:  input_width <= 8;
            endcase
            pixel_width <= data_type_i==`RAW10? 10: data_type_i==`RAW8?  8:10;
        end
    end
    //assign input_width = data_type_i==`RAW10? ((pixel_per_clk_i==4)? 40:(pixel_per_clk_i==2)? 20:(pixel_per_clk_i==1)? 10:40): data_type_i==`RAW8?  ((pixel_per_clk_i==4)? 32:(pixel_per_clk_i==2)? 16:(pixel_per_clk_i==1)? 8:32):40;
    //always_comb begin
    //    input_width = 40;
    //    case({pixel_per_clk_i, data_type_i})
    //        {3'd4,`RAW10}: input_width = 40;
    //        {3'd2,`RAW10}: input_width = 20;
    //        {3'd1,`RAW10}: input_width = 10;
    //        {3'd4,`RAW8}:  input_width = 32;
    //        {3'd2,`RAW8}:  input_width = 16;
    //        {3'd1,`RAW8}:  input_width = 8;
    //    endcase
    //end
    //assign pixel_width = data_type_i==`RAW10? 10: data_type_i==`RAW8?  8:10;

    always@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            for(i=0;i<4;i++) begin
                ram_pipe_4ppc_raw10[i] <= 0;
                ram_pipe_2ppc_raw10[i] <= 0;
                ram_pipe_1ppc_raw10[i] <= 0;
                ram_pipe_4ppc_raw8[i] <=  0;
                ram_pipe_2ppc_raw8[i] <=  0;
                ram_pipe_1ppc_raw8[i] <=  0;
            end
        end
        else begin
            if(!stream_stall_i) begin
                for(i=0;i<4;i++) begin
                    ram_pipe_4ppc_raw10[i] <= {ram_out_reg_4ppc_raw10[i], last_ram_outputs_4ppc_raw10[i], last_ram_outputs_stage2_4ppc_raw10[i]};
                    ram_pipe_2ppc_raw10[i] <= {ram_out_reg_2ppc_raw10[i], last_ram_outputs_2ppc_raw10[i], last_ram_outputs_stage2_2ppc_raw10[i]};
                    ram_pipe_1ppc_raw10[i] <= {ram_out_reg_1ppc_raw10[i], last_ram_outputs_1ppc_raw10[i], last_ram_outputs_stage2_1ppc_raw10[i]};
                    ram_pipe_4ppc_raw8[i] <= {ram_out_reg_4ppc_raw8[i], last_ram_outputs_4ppc_raw8[i], last_ram_outputs_stage2_4ppc_raw8[i]};
                    ram_pipe_2ppc_raw8[i] <= {ram_out_reg_2ppc_raw8[i], last_ram_outputs_2ppc_raw8[i], last_ram_outputs_stage2_2ppc_raw8[i]};
                    ram_pipe_1ppc_raw8[i] <= {ram_out_reg_1ppc_raw8[i], last_ram_outputs_1ppc_raw8[i], last_ram_outputs_stage2_1ppc_raw8[i]};
                end
            end
        end
    end
    
    /*always@(*) begin
        for(i=0;i<4;i++) begin
            //ram_pipe_4ppc_raw10[i] = {ram_out_reg_4ppc_raw10[i], last_ram_outputs_4ppc_raw10[i], last_ram_outputs_stage2_4ppc_raw10[i]};
            //ram_pipe_2ppc_raw10[i] = {ram_out_reg_2ppc_raw10[i], last_ram_outputs_2ppc_raw10[i], last_ram_outputs_stage2_2ppc_raw10[i]};
            //ram_pipe_1ppc_raw10[i] = {ram_out_reg_1ppc_raw10[i], last_ram_outputs_1ppc_raw10[i], last_ram_outputs_stage2_1ppc_raw10[i]};
            //
            //ram_pipe_4ppc_raw8[i] = {ram_out_reg_4ppc_raw8[i], last_ram_outputs_4ppc_raw8[i], last_ram_outputs_stage2_4ppc_raw8[i]};
            //ram_pipe_2ppc_raw8[i] = {ram_out_reg_2ppc_raw8[i], last_ram_outputs_2ppc_raw8[i], last_ram_outputs_stage2_2ppc_raw8[i]};
            //ram_pipe_1ppc_raw8[i] = {ram_out_reg_1ppc_raw8[i], last_ram_outputs_1ppc_raw8[i], last_ram_outputs_stage2_1ppc_raw8[i]};

            ram_pipe[i] = ram_pipe_4ppc_raw10[i];
            case({pixel_per_clk_i, data_type_i})
            {3'd4,`RAW10}: ram_pipe[i] = ram_pipe_4ppc_raw10[i];
            {3'd2,`RAW10}: ram_pipe[i] = {60'd0, ram_pipe_2ppc_raw10[i]};
            {3'd1,`RAW10}: ram_pipe[i] = {90'd0, ram_pipe_1ppc_raw10[i]};
            {3'd4,`RAW8}:  ram_pipe[i] = {24'd0, ram_pipe_4ppc_raw8[i]};
            {3'd2,`RAW8}:  ram_pipe[i] = {72'd0, ram_pipe_2ppc_raw8[i]};
            {3'd1,`RAW8}:  ram_pipe[i] = {96'd0, ram_pipe_1ppc_raw8[i]};
            endcase
        end
    end*/

    always@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            for(i=0;i<4;i++)
                ram_pipe[i] <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                for(i=0;i<4;i++) begin
                    case({pixel_per_clk_i, data_type_i})
                    {3'd4,`RAW10}: ram_pipe[i] <= ram_pipe_4ppc_raw10[i];
                    {3'd2,`RAW10}: ram_pipe[i] <= {60'd0, ram_pipe_2ppc_raw10[i]};
                    {3'd1,`RAW10}: ram_pipe[i] <= {90'd0, ram_pipe_1ppc_raw10[i]};
                    {3'd4,`RAW8}:  ram_pipe[i] <= {24'd0, ram_pipe_4ppc_raw8[i]};
                    {3'd2,`RAW8}:  ram_pipe[i] <= {72'd0, ram_pipe_2ppc_raw8[i]};
                    {3'd1,`RAW8}:  ram_pipe[i] <= {96'd0, ram_pipe_1ppc_raw8[i]};
                    endcase
                end
            end
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

    always@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            for(i=0;i<4;i++) begin
                R1_odd[i] <= 0;
                R2_odd[i] <= 0;
                R3_odd[i] <= 0;
                R4_odd[i] <= 0;
                G1_odd[i] <= 0;
                G2_odd[i] <= 0;
                G3_odd[i] <= 0;
                G4_odd[i] <= 0;
                B1_odd[i] <= 0;
                B2_odd[i] <= 0;
                B3_odd[i] <= 0;
                B4_odd[i] <= 0;
                R1_even[i] <= 0;
                R2_even[i] <= 0;
                R3_even[i] <= 0;
                R4_even[i] <= 0;
                G1_even[i] <= 0;
                G2_even[i] <= 0;
                G3_even[i] <= 0;
                G4_even[i] <= 0;
                B1_even[i] <= 0;
                B2_even[i] <= 0;
                B3_even[i] <= 0;
                B4_even[i] <= 0;
            end
        end
        else begin
            if(!stream_stall_i) begin
                case(bayer_filter_type_i)
                `RGGB: begin

                    for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels RGGB, even line pixels BGGR

                        R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "x");
                        R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "x");
                        R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "x");
                        R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "x");
                        
                        G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");

                        B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "y");
                        B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "y");
                        B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "y");
                        B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "y");

                        R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");


                        G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "xy");
                        G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "xy");
                        G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "xy");
                        G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "xy");
                        
                        
                        B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "uv");
                        B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "uv");
                        B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "uv");
                        B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "uv");

                    end

                    for (i=0; i < 3; i=i+2) begin		// 4 even line pixels RGGB, odd line pixels BGGR

                        R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "uv");
                        R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "uv");
                        R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "uv");
                        R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "uv");
                        
                        G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "xy"); 
                        G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "xy"); 
                        G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "xy"); 
                        G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "xy"); 

                        B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");

                        R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "y");
                        R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "y");
                        R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "y");
                        R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "y");


                        G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");
                        
                        
                        B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "x");
                        B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "x");
                        B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "x");
                        B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "x");

                    end
                end

                `BGGR: begin
                    for (i=0; i < 4; i=i+2) begin		// 4 odd line pixels RGGB, even line pixels BGGR

                        R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "y");
                        R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "y");
                        R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "y");
                        R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "y");
                        
                        G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");

                        B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "x");
                        B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "x");
                        B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "x");
                        B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "x");

                        R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "uv");
                        R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "uv");
                        R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "uv");
                        R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "uv");


                        G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "xy");
                        G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "xy");
                        G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "xy");
                        G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "xy");
                        
                        
                        B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");

                    end

                    for (i=0; i < 4; i=i+2) begin		// 4 even line pixels RGGB, odd line pixels BGGR

                        R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");
                        
                        G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "xy"); 
                        G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "xy"); 
                        G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "xy"); 
                        G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "xy"); 

                        B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "uv");
                        B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "uv");
                        B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "uv");
                        B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "uv");

                        R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "x");
                        R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "x");
                        R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "x");
                        R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "x");


                        G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");
                        
                        
                        B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "y");
                        B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "y");
                        B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "y");
                        B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "y");

                    end
                end
                `GBRG: begin // GBRG or GRBG
                    for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels GBRG, even line GRBG

                        R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "uv");
                        R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "uv");
                        R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "uv");
                        R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "uv");
                        
                        G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "xy"); 
                        G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "xy"); 
                        G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "xy"); 
                        G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "xy"); 

                        B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");

                        R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "y");  
                        R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "y");  
                        R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "y");  
                        R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "y");  


                        G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");
                        
                        
                        B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "x");
                        B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "x");
                        B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "x");
                        B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "x");

                    end

                    for (i=0; i < 3; i=i+2) begin		// 4 even line pixels GBRG, odd line GRBG

                        R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "x");
                        R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "x");
                        R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "x");
                        R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "x");
                        
                        G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "."); 
                        G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "."); 
                        G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "."); 
                        G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "."); 

                        B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "y");
                        B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "y");
                        B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "y");
                        B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "y");

                        R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");


                        G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "xy");
                        G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "xy");
                        G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "xy");
                        G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "xy");
                        
                        
                        B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "uv");
                        B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "uv");
                        B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "uv");
                        B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "uv");

                    end
                end
                `GRBG: begin // GRBG
                    for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels GBRG, even line GRBG

                        R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, ".");
                        R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, ".");
                        R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, ".");
                        R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, ".");
                        
                        G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "xy"); 
                        G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "xy"); 
                        G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "xy"); 
                        G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "xy"); 

                        B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "uv");
                        B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "uv");
                        B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "uv");
                        B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "uv");

                        R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "x");  
                        R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "x");  
                        R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "x");  
                        R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "x");  


                        G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");
                        
                        
                        B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "y");
                        B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "y");
                        B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "y");
                        B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "y");

                    end

                    for (i=0; i < 3; i=i+2) begin		// 4 even line pixels GBRG, odd line GRBG

                        R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "y");
                        R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "y");
                        R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "y");
                        R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "y");
                        
                        G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "."); 
                        G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "."); 
                        G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "."); 
                        G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "."); 

                        B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 1, "x");
                        B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 2, "x");
                        B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 3, "x");
                        B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i+1, 4, "x");

                        R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "uv");
                        R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "uv");
                        R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "uv");
                        R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "uv");


                        G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, "xy");
                        G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, "xy");
                        G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, "xy");
                        G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, "xy");
                        
                        
                        B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 1, ".");
                        B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 2, ".");
                        B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 3, ".");
                        B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1, read_ram_index_plus_1, read_ram_index, i, 4, ".");

                    end// 4 odd line pixels GBRG, even line GRBG
                end
                endcase
            end
        end
    end
    //`ifndef SYNTHESIS
    //    // Define the counter
        integer outcounter;
        always @(posedge clk_i, negedge reset_n_i) begin
            if(!reset_n_i)
                outcounter <= 0;
            else begin
                if(line_valid_sync_o && !line_valid_sync_reg)
                    outcounter <= 0;
                else if(pixel_data_valid_o && !stream_stall_i)
                    outcounter <= outcounter + 1;
            end
        end
    //`endif
endmodule