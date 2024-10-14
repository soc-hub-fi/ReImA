module output_checker(
    input reset_n_i,
    input clk_i,
    input line_valid_i,
    input frame_valid_i,
    input yuv_valid_i,
    input [63:0] yuv_data_i,
    output reg error
);
reg line_valid_reg;
reg frame_valid_reg;
reg [63:0] estimated_value;
localparam FST_LINE=0, MID_LINE=1, LAST_LINE=2;
reg [1:0] state;
reg [11:0] line_counter;
reg [7:0] cycle_counter;
reg [2:0] wait_counter;
// neglect the first two lines
always@(negedge reset_n_i, posedge clk_i) begin
    if(!reset_n_i) begin
        state <= FST_LINE;
    end
    else begin
        case (state)
        FST_LINE: begin
            if(line_counter == 'd1)
                state <= MID_LINE;
        end
        MID_LINE: begin
            if(line_counter == 'd511)
                state <= LAST_LINE;
        end
        LAST_LINE: begin
            if(line_counter == 'd0)
                state <= FST_LINE;
        end
        endcase
    end
end

always@(*) begin
    case(state)
    FST_LINE: begin
        if(cycle_counter == 0)
            estimated_value = 64'h266b26bf1375269f;
        else
            estimated_value = 64'h266b26bf266b26bf;
    end
    MID_LINE: begin
        if(cycle_counter == 0)
            estimated_value = 64'h4d554dff266b4dbf;
        else
            estimated_value = 64'h4d554dff4d554dff;
    end
    LAST_LINE: begin
        if(cycle_counter == 0)
            estimated_value = 64'h4a56954b256b9566;
        else
            estimated_value = 64'h4a56954b4a56954b;
    end
    default: estimated_value = 64'h0;
    endcase
end

always@(negedge reset_n_i, posedge clk_i) begin
    if(!reset_n_i) begin
        line_counter <= 0;
        cycle_counter <= 0;
        line_valid_reg <= 0;
        wait_counter <= 0;
        frame_valid_reg <= 0;
    end
    else begin

        line_valid_reg <= line_valid_i;
        frame_valid_reg <= frame_valid_i;

        if(line_valid_i && !line_valid_reg && (wait_counter<3))
            wait_counter <= wait_counter + 1;
            
        if(line_valid_i && !line_valid_reg && (wait_counter==3))
            cycle_counter <= 0;
        else if(yuv_valid_i)
            cycle_counter <= cycle_counter + 1;

        if(frame_valid_i && !frame_valid_reg)
            line_counter <= 0;
        else if(line_valid_i && !line_valid_reg && (wait_counter==3))
            line_counter <= line_counter + 1;
    end
end

always@(negedge reset_n_i, negedge clk_i) begin
    if(!reset_n_i)
        error <= 0;
    else begin
        if(yuv_valid_i && (yuv_data_i!=estimated_value))
            error <= 1;
    end
end

endmodule