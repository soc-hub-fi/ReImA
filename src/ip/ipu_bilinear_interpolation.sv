`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
`include "mipi_csi_data_types.svh"
`include "rgb_locate.svh"
module ipu_bilinear_interpolation #(parameter DATA_WIDTH = 40,
                        parameter VALID_WIDTH = 4
                        )(
                        input                   clk_i,
                        input                   reset_n_i,
                        input           [5:0]   data_type_i,                                    // RAW8 or RAW10
                        input           [2:0]   pixel_per_clk_i,                                // single, dual or quad
                        input           [1:0]   bayer_filter_type_i,                            // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
                        input           [2:0] [(DATA_WIDTH+VALID_WIDTH-1):0] pixel_line_i,
                        input                   line_done_pulse_i,
                        input                   line_counter_i,
                        input                   pipe_stall_i,
                        input           [1:0]   read_ram_index_i, 	                            //which line RAM is being focused to read for even lines,  (not which address is being read from line RAM) Must be 2 bits only
                        input           [1:0]   read_ram_index_plus_1_i,
                        input           [1:0]   read_ram_index_minus_1_i,
                        output logic            line_done_pulse_o,
                        output logic    [3:0]   pixel_data_valid_o,                         // Each bit of these correspond to one RGB component of the pixel_data_o
                        output logic    [119:0] pixel_data_o                                    // Maximum number of RGB components = 3*PPC_max*PIXELWIDTH_max = 3*4*10 = 120
);

localparam PIXEL_WIDTH = 10;
localparam PIXEL_WIDTH10 = 10;
localparam PIXEL_WIDTH8 = 8;
logic [VALID_WIDTH-1:0] ram_out_reg_valids[2:0];
logic [VALID_WIDTH-1:0] last_ram_valids[2:0];
logic [VALID_WIDTH-1:0] last_ram_valids_reg[2:0];
logic [((4*10)-1):0]ram_out_reg_4ppc_raw10[2:0];
logic [((4*10)-1):0]last_ram_outputs_4ppc_raw10[2:0];
logic [((4*10)-1):0]last_ram_outputs_stage2_4ppc_raw10[2:0];
logic [((2*10)-1):0]ram_out_reg_2ppc_raw10[2:0];
logic [((2*10)-1):0]last_ram_outputs_2ppc_raw10[2:0];
logic [((2*10)-1):0]last_ram_outputs_stage2_2ppc_raw10[2:0];
logic [((1*10)-1):0]ram_out_reg_1ppc_raw10[2:0];
logic [((1*10)-1):0]last_ram_outputs_1ppc_raw10[2:0];
logic [((1*10)-1):0]last_ram_outputs_stage2_1ppc_raw10[2:0];
logic [((4*8)-1):0]ram_out_reg_4ppc_raw8[2:0];
logic [((4*8)-1):0]last_ram_outputs_4ppc_raw8[2:0];
logic [((4*8)-1):0]last_ram_outputs_stage2_4ppc_raw8[2:0];
logic [((2*8)-1):0]ram_out_reg_2ppc_raw8[2:0];
logic [((2*8)-1):0]last_ram_outputs_2ppc_raw8[2:0];
logic [((2*8)-1):0]last_ram_outputs_stage2_2ppc_raw8[2:0];
logic [((1*8)-1):0]ram_out_reg_1ppc_raw8[2:0];
logic [((1*8)-1):0]last_ram_outputs_1ppc_raw8[2:0];
logic [((1*8)-1):0]last_ram_outputs_stage2_1ppc_raw8[2:0];

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
logic [((DATA_WIDTH*3)-1):0]ram_pipe[2:0];
logic [((4*10*3)-1):0]ram_pipe_4ppc_raw10[2:0];
logic [((2*10*3)-1):0]ram_pipe_2ppc_raw10[2:0];
logic [((1*10*3)-1):0]ram_pipe_1ppc_raw10[2:0];
logic [((4*8*3)-1):0]ram_pipe_4ppc_raw8[2:0];
logic [((2*8*3)-1):0]ram_pipe_2ppc_raw8[2:0];
logic [((1*8*3)-1):0]ram_pipe_1ppc_raw8[2:0];
logic [1:0] not_used2b;
integer input_width;
integer pixel_width;
logic odd_signal;
logic [3:0] pixel_data_valid_reg;
logic [3:0] pixel_data_valid_reg2;
logic line_done_pulse_delayed;
logic line_done_pulse_delayed2;
logic line_done_pulse_delayed3;
logic line_done_pulse_delayed4;
logic line_done_pulse_delayed5;
integer i;
always @(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        line_done_pulse_delayed <= 0;
        line_done_pulse_delayed2 <= 0;
        for ( i = 0; i < 3; i++) begin
            ram_out_reg_valids[i]                   <= 0;
            last_ram_valids[i] 		                <= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_4ppc_raw10[i]               <= 0;
            last_ram_outputs_4ppc_raw10[i] 		    <= 0;
            last_ram_outputs_stage2_4ppc_raw10[i] 	<= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_2ppc_raw10[i]               <= 0;
            last_ram_outputs_2ppc_raw10[i] 		    <= 0;
            last_ram_outputs_stage2_2ppc_raw10[i] 	<= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_1ppc_raw10[i]               <= 0;
            last_ram_outputs_1ppc_raw10[i] 		    <= 0;
            last_ram_outputs_stage2_1ppc_raw10[i] 	<= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_4ppc_raw8[i]                <= 0;
            last_ram_outputs_4ppc_raw8[i] 		    <= 0;
            last_ram_outputs_stage2_4ppc_raw8[i] 	<= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_2ppc_raw8[i]                <= 0;
            last_ram_outputs_2ppc_raw8[i] 		    <= 0;
            last_ram_outputs_stage2_2ppc_raw8[i] 	<= 0;
        end

        for ( i = 0; i < 3; i++) begin
            ram_out_reg_1ppc_raw8[i]                <= 0;
            last_ram_outputs_1ppc_raw8[i] 		    <= 0;
            last_ram_outputs_stage2_1ppc_raw8[i] 	<= 0;
        end
    end
    else begin
        if(!pipe_stall_i) begin // stall if line didnt end and valid =0
            line_done_pulse_delayed <= line_done_pulse_i;
            line_done_pulse_delayed2 <= line_done_pulse_delayed;
            for ( i = 0; i < 3; i++) begin
                ram_out_reg_valids[i]       <= pixel_line_i[i][DATA_WIDTH +:VALID_WIDTH];
                last_ram_valids[i] 		    <= ram_out_reg_valids[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_4ppc_raw10[i]              <= pixel_line_i[i][(DATA_WIDTH-1):0];
                last_ram_outputs_4ppc_raw10[i] 		<= ram_out_reg_4ppc_raw10[i];
                last_ram_outputs_stage2_4ppc_raw10[i] 	<= last_ram_outputs_4ppc_raw10[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_2ppc_raw10[i]              <= pixel_line_i[i][19:0];
                last_ram_outputs_2ppc_raw10[i] 		<= ram_out_reg_2ppc_raw10[i];
                last_ram_outputs_stage2_2ppc_raw10[i] 	<= last_ram_outputs_2ppc_raw10[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_1ppc_raw10[i]              <= pixel_line_i[i][9:0];
                last_ram_outputs_1ppc_raw10[i] 		<= ram_out_reg_1ppc_raw10[i];
                last_ram_outputs_stage2_1ppc_raw10[i] 	<= last_ram_outputs_1ppc_raw10[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_4ppc_raw8[i]              <= pixel_line_i[i][31:0];
                last_ram_outputs_4ppc_raw8[i] 		<= ram_out_reg_4ppc_raw8[i];
                last_ram_outputs_stage2_4ppc_raw8[i] 	<= last_ram_outputs_4ppc_raw8[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_2ppc_raw8[i]              <= pixel_line_i[i][15:0];
                last_ram_outputs_2ppc_raw8[i] 		<= ram_out_reg_2ppc_raw8[i];
                last_ram_outputs_stage2_2ppc_raw8[i] 	<= last_ram_outputs_2ppc_raw8[i];
            end

            for ( i = 0; i < 3; i++) begin
                ram_out_reg_1ppc_raw8[i]              <= pixel_line_i[i][7:0];
                last_ram_outputs_1ppc_raw8[i] 		<= ram_out_reg_1ppc_raw8[i];
                last_ram_outputs_stage2_1ppc_raw8[i] 	<= last_ram_outputs_1ppc_raw8[i];
            end
        end
    end
end

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        for(i=0; i<3; i++) begin
            ram_pipe_4ppc_raw10[i] <= 0;
            ram_pipe_2ppc_raw10[i] <= 0;
            ram_pipe_1ppc_raw10[i] <= 0;
            ram_pipe_4ppc_raw8[i] <=  0;
            ram_pipe_2ppc_raw8[i] <=  0;
            ram_pipe_1ppc_raw8[i] <=  0;
        end
    end
    else begin
        for(i=0; i<3; i++) begin
            ram_pipe_4ppc_raw10[i] <= {ram_out_reg_4ppc_raw10[i], last_ram_outputs_4ppc_raw10[i], last_ram_outputs_stage2_4ppc_raw10[i]};
            ram_pipe_2ppc_raw10[i] <= {ram_out_reg_2ppc_raw10[i], last_ram_outputs_2ppc_raw10[i], last_ram_outputs_stage2_2ppc_raw10[i]};
            ram_pipe_1ppc_raw10[i] <= {ram_out_reg_1ppc_raw10[i], last_ram_outputs_1ppc_raw10[i], last_ram_outputs_stage2_1ppc_raw10[i]};
            ram_pipe_4ppc_raw8[i] <= {ram_out_reg_4ppc_raw8[i], last_ram_outputs_4ppc_raw8[i], last_ram_outputs_stage2_4ppc_raw8[i]};
            ram_pipe_2ppc_raw8[i] <= {ram_out_reg_2ppc_raw8[i], last_ram_outputs_2ppc_raw8[i], last_ram_outputs_stage2_2ppc_raw8[i]};
            ram_pipe_1ppc_raw8[i] <= {ram_out_reg_1ppc_raw8[i], last_ram_outputs_1ppc_raw8[i], last_ram_outputs_stage2_1ppc_raw8[i]};
        end
    end
end

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        for(i=0; i<3; i++)
            ram_pipe[i] <= 0;
    end
    else begin
        for(i=0; i<3; i++) begin
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

always@(*) begin
    if (line_counter_i) begin
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
    end
    else begin
        // put zeros in unused pixels
        pixel_data_o <= 0;
        if(pixel_data_valid_o)
            odd_signal <= !odd_signal;
        else if(!pixel_data_valid_o)
            odd_signal <= 1;

        for (i=0; i < 4 ; i=i+1)
        begin
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

always@(posedge clk_i or negedge reset_n_i) begin
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

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        for (i=0; i < 3; i=i+1)
            last_ram_valids_reg[i] <= 0;

        pixel_data_valid_o <= 0;
        pixel_data_valid_reg <= 0;
        pixel_data_valid_reg2 <= 0;
        line_done_pulse_delayed3 <= 0;
        line_done_pulse_delayed4 <= 0;
        line_done_pulse_delayed5 <= 0;
        line_done_pulse_o <= 0;
    end
    else begin
        line_done_pulse_delayed3 <= line_done_pulse_delayed2;
        line_done_pulse_delayed4 <= line_done_pulse_delayed3;
        line_done_pulse_delayed5 <= line_done_pulse_delayed4;
        line_done_pulse_o <= line_done_pulse_delayed5;
        for (i=0; i < 3; i=i+1)
            last_ram_valids_reg[i] <= (pipe_stall_i==0)? last_ram_valids[i]:4'h0;

        pixel_data_valid_reg <= last_ram_valids_reg[read_ram_index_i];
        pixel_data_valid_reg2 <= pixel_data_valid_reg;
        pixel_data_valid_o <= pixel_data_valid_reg2;
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
            case(bayer_filter_type_i)
            `RGGB: begin

                for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels RGGB, even line pixels BGGR

                    R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "x");
                    R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "x");
                    R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "x");
                    R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "x");
                    
                    G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");

                    B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "y");
                    B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "y");
                    B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "y");
                    B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "y");

                    R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");


                    G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "xy");
                    G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "xy");
                    G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "xy");
                    G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "xy");
                    
                    
                    B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "uv");
                    B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "uv");
                    B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "uv");
                    B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "uv");

                end

                for (i=0; i < 3; i=i+2) begin		// 4 even line pixels RGGB, odd line pixels BGGR

                    R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "uv");
                    R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "uv");
                    R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "uv");
                    R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "uv");
                    
                    G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "xy"); 
                    G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "xy"); 
                    G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "xy"); 
                    G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "xy"); 

                    B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");

                    R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "y");
                    R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "y");
                    R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "y");
                    R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "y");


                    G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");
                    
                    
                    B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "x");
                    B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "x");
                    B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "x");
                    B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "x");

                end
            end

            `BGGR: begin
                for (i=0; i < 4; i=i+2) begin		// 4 odd line pixels RGGB, even line pixels BGGR

                    R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "y");
                    R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "y");
                    R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "y");
                    R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "y");
                    
                    G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");

                    B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "x");
                    B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "x");
                    B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "x");
                    B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "x");

                    R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "uv");
                    R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "uv");
                    R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "uv");
                    R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "uv");


                    G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "xy");
                    G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "xy");
                    G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "xy");
                    G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "xy");
                    
                    
                    B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");

                end

                for (i=0; i < 4; i=i+2) begin		// 4 even line pixels RGGB, odd line pixels BGGR

                    R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");
                    
                    G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "xy"); 
                    G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "xy"); 
                    G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "xy"); 
                    G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "xy"); 

                    B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "uv");
                    B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "uv");
                    B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "uv");
                    B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "uv");

                    R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "x");
                    R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "x");
                    R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "x");
                    R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "x");


                    G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");
                    
                    
                    B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "y");
                    B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "y");
                    B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "y");
                    B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "y");

                end
            end
            `GBRG: begin // GBRG or GRBG
                for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels GBRG, even line GRBG

                    R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "uv");
                    R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "uv");
                    R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "uv");
                    R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "uv");
                    
                    G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "xy"); 
                    G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "xy"); 
                    G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "xy"); 
                    G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "xy"); 

                    B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");

                    R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "y");  
                    R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "y");  
                    R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "y");  
                    R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "y");  


                    G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");
                    
                    
                    B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "x");
                    B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "x");
                    B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "x");
                    B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "x");

                end

                for (i=0; i < 3; i=i+2) begin		// 4 even line pixels GBRG, odd line GRBG

                    R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "x");
                    R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "x");
                    R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "x");
                    R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "x");
                    
                    G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "."); 
                    G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "."); 
                    G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "."); 
                    G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "."); 

                    B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "y");
                    B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "y");
                    B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "y");
                    B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "y");

                    R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");


                    G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "xy");
                    G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "xy");
                    G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "xy");
                    G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "xy");
                    
                    
                    B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "uv");
                    B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "uv");
                    B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "uv");
                    B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "uv");

                end
            end
            `GRBG: begin // GRBG
                for (i=0; i < 3; i=i+2) begin		// 4 odd line pixels GBRG, even line GRBG

                    R1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, ".");
                    R2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, ".");
                    R3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, ".");
                    R4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, ".");
                    
                    G1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "xy"); 
                    G2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "xy"); 
                    G3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "xy"); 
                    G4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "xy"); 

                    B1_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "uv");
                    B2_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "uv");
                    B3_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "uv");
                    B4_odd[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "uv");

                    R1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "x");  
                    R2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "x");  
                    R3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "x");  
                    R4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "x");  


                    G1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    G2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    G3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    G4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");
                    
                    
                    B1_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "y");
                    B2_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "y");
                    B3_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "y");
                    B4_odd[i]           <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "y");

                end

                for (i=0; i < 3; i=i+2) begin		// 4 even line pixels GBRG, odd line GRBG

                    R1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "y");
                    R2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "y");
                    R3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "y");
                    R4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "y");
                    
                    G1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "."); 
                    G2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "."); 
                    G3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "."); 
                    G4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "."); 

                    B1_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 1, "x");
                    B2_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 2, "x");
                    B3_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 3, "x");
                    B4_even[i+1] 		<= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i+1, 4, "x");

                    R1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "uv");
                    R2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "uv");
                    R3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "uv");
                    R4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "uv");


                    G1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, "xy");
                    G2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, "xy");
                    G3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, "xy");
                    G4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, "xy");
                    
                    
                    B1_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 1, ".");
                    B2_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 2, ".");
                    B3_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 3, ".");
                    B4_even[i]          <= `RGB_LOCATE(input_width, pixel_width, read_ram_index_minus_1_i, read_ram_index_plus_1_i, read_ram_index_i, i, 4, ".");

                end// 4 odd line pixels GBRG, even line GRBG
            end
            endcase
    end
end
endmodule