/* 
    File: cu_crc16_top.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality:
    
    -   This module is made of 4 parallel CRC generators which takes an 8 bit input for the polynomial a x^16+x^12+x^5+1
    -   It has a mux that selects which output is the last one taken out of these 4 parallel CRC generators
    -   A register is there to save the last CRC value for the next set of inputs to accumulate the CRC
    -   The architecture is made like this to stream the data without a lowering the throughput
    -   //! Still not sure how the error should look like, depends on what are you going to do with it later

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
module cu_crc16_top(
        input                   reset_n_i,
        input                   clk_i,
        input                   init_i,                     // Active high, initializes the CRC to FFFF before every packet
        input           [7:0]   data_i              [4],
        input           [1:0]   last_selection_i,           // selection for the mux 0 should pick crc_p[3] and 3 should pick crc_p[0]
        input           [15:0]  received_crc_i,             // crc received from transmitter
        input                   crc_received_valid_i,
        input                   crc_capture_i,              // Active high signal to capture the calculated crc for comparison 
        output logic            err_crc_o                   // Active high pulse signal that indecates an error in the received packet data
);
logic [15:0] crc_p [4];
logic [15:0] crc_r;
logic [15:0] crc_calc;
logic crc_received_valid_r;
logic [15:0] received_crc_r;

cu_crc16_parallel cu_crc16_parallel_i3(.crcIn(crc_r), .data(data_i[3]), .crcOut(crc_p[3]));
cu_crc16_parallel cu_crc16_parallel_i2(.crcIn(crc_p[3]), .data(data_i[2]), .crcOut(crc_p[2]));
cu_crc16_parallel cu_crc16_parallel_i1(.crcIn(crc_p[2]), .data(data_i[1]), .crcOut(crc_p[1]));
cu_crc16_parallel cu_crc16_parallel_i0(.crcIn(crc_p[1]), .data(data_i[0]), .crcOut(crc_p[0]));

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        crc_r <= 16'hffff;
        crc_calc <= 16'hffff;
        crc_received_valid_r <= 0;
        received_crc_r <= 0;
    end
    else begin
        crc_received_valid_r <= crc_received_valid_i;
        received_crc_r <= received_crc_i;
        if(init_i)
            crc_r <= 16'hffff;
        else
            crc_r <= crc_p[3-last_selection_i]; // to invert and make a selection of 0 pick 3 

        if(crc_capture_i)
            crc_calc <= crc_p[3-last_selection_i];
    end
end

assign err_crc_o = ((crc_received_valid_r) && (received_crc_r != crc_calc))? 1'b1: 1'b0;
endmodule