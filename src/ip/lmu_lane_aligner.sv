/* 
    File: lmu_lane_aligner.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality:
    Input should look like this
    //*Lane 0-----data_i[0]-----  <ECC>               <data3> ..
    //*Lane 1-----data_i[1]-----  <WCount MSByte>     <data2> ..
    //*Lane 2-----data_i[2]-----  <WCount LSByte>     <data1> ..
    //*Lane 3-----data_i[3]-----  <DataID>            <data0> ..
    
    -   alignes the bytes of each lane on the same clock edge along with the valids

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/

module lmu_lane_aligner	#(parameter MIPI_GEAR=16, parameter MIPI_LANES=4)(	
                                    input                                               reset_n_i,
                                    input                                               clk_i,
                                    input           [(MIPI_LANES-1):0]                  bytes_valid_i,
                                    input           [((MIPI_GEAR * MIPI_LANES)-1):0]    lane_bytes_i,
                                    output logic    [((MIPI_GEAR * MIPI_LANES)-1):0]    lane_bytes_o,
                                    output logic    [(MIPI_LANES-1):0]                  lane_valid_o
                                );

    localparam [3:0]ALIGN_DEPTH = 4'h7; //how many byte misalignment is allowed, whole package length must be also longer than this
                                        //TODO: Why did he calculate it like that how would it differ?

    logic [(MIPI_GEAR * MIPI_LANES)-1:0] data_lane_fifo [ALIGN_DEPTH-1:0];
    logic [(MIPI_LANES)-1:0] valid_lane_fifo [ALIGN_DEPTH-1:0];

    logic [3:0] last_lane_bytes_index [MIPI_LANES-1:0];
    logic valid_out_reg;
    integer i, x;
    // insert data into fifo
    always@(posedge clk_i, negedge reset_n_i) begin //! corner cases: 1) What if it overflows? 2) What if they are already aligned?
        if(!reset_n_i) begin
            for(i=0; i<MIPI_LANES; i++) begin
                last_lane_bytes_index[i] <= 0;
                data_lane_fifo[i] <= 0;
                valid_lane_fifo[i] <= 0;
            end
        end
        else begin
            if( !((|bytes_valid_i) || lane_valid_o)) begin
                for(i=0; i<MIPI_LANES; i++)
                    last_lane_bytes_index[i] <= 0;
            end
            for(i=0; i<MIPI_LANES; i++) begin
                if(bytes_valid_i[i]) begin

                    data_lane_fifo[0][i*MIPI_GEAR +: MIPI_GEAR] <= lane_bytes_i[i*MIPI_GEAR +: MIPI_GEAR];
                    valid_lane_fifo[0][i] <= bytes_valid_i[i];

                    last_lane_bytes_index[i] <= (valid_out_reg)? last_lane_bytes_index[i] : last_lane_bytes_index[i] + 4'd1; // first byte is 1 so subtract 1 from this when used

                    for(x=0; x<ALIGN_DEPTH-1; x++) begin
                        data_lane_fifo[x+1] <= data_lane_fifo[x];
                        valid_lane_fifo[x+1] <= valid_lane_fifo[x];
                    end
                end
            end
        end
    end
    //! once all lanes are valid, stay valid untill none are valid to not forget about the last bytes coming in
    //* Should be done using a register not compinationally. to let the data be written into the fifo.
    /*if all of them are valid
        go high
    if all of them are not valid
        go low
        if some of them are valid
        look at the previous state and determine
        Would that be good or slow? should be fine*/
    always@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            valid_out_reg <= 0;
        else begin
            if(&bytes_valid_i)
                valid_out_reg <= 1;
            else if(!(|bytes_valid_i))
                valid_out_reg <= 0;
        end
    end
        
    // extract data from fifo
    always@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i) begin
            lane_valid_o <= 0;
            lane_bytes_o <= 0;
        end
        else begin
            
            if(valid_out_reg) begin
                for(i=0; i<MIPI_LANES; i++) begin
                    lane_bytes_o[i*MIPI_GEAR +: MIPI_GEAR] <= data_lane_fifo[last_lane_bytes_index[i]-1][i*MIPI_GEAR +: MIPI_GEAR];
                    lane_valid_o[i] <= valid_lane_fifo[last_lane_bytes_index[i]-1][i];
                end
            end
            else begin
                lane_valid_o <= 0;
                lane_bytes_o <= 0;
            end
            
        end
    end
endmodule