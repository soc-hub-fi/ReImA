/* 
    File: cu_packet_decoder.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality:
    Input should look like this
    //*Lane 0-----data_i[0]-----  <ECC>               <data3> ..
    //*Lane 1-----data_i[1]-----  <WCount MSByte>     <data2> ..
    //*Lane 2-----data_i[2]-----  <WCount LSByte>     <data1> ..
    //*Lane 3-----data_i[3]-----  <DataID>            <data0> ..
    
    -   Packet decoder. The packet looks like this <packet_header> <payload_data> <packet_footer>
    -   The number of active lanes must be 1, 2 or 4 lanes.
    -   Packet header contains information about the payload data it is forwarded to ECC.
    -   Pyaload data and packet footer are forwarded to CRC for error check
    //*TODO: Generate error WC corruption when payload is less than length in packet header
    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
`define SYNTH
//TODO: Document Algorithmic steps
module cu_packet_decoder(
                                    // inputs
                                    input                   reset_n_i,
                                    input                   clk_i,
                                    input                   data_valid_i    [4],
                                    input           [7:0]   data_i          [4],    // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                                                    // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
                                    input           [2:0]   active_lanes_i,         // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                                    input           [15:0]  payload_length_i,       // Data length in bits = 8*payload_length_i coming from ECC after correction

                                    // outputs
                                    output logic    [31:0]  packet_header_o,        // Packet header format <DataID 8bit> <WCount 8bit lsb> <WCount 8bit msb> <ECC 8bit>
                                    output logic            packet_header_valid_o,
                                    output logic    [7:0]   payload_data_o  [4],    // Mipi data 8 bits wide 4 data lanes
                                    output logic            payload_valid_o [4],
                                    output logic    [15:0]  received_crc_o,         // Packet Footer
                                    output logic    [1:0]   crc_mux_sel_o,          // Selects last input to the CRC mux
                                    output logic            crc_received_valid_o,   // Active high valid signal for the received CRC code
                                    output logic            crc_capture_o           // Active high capture signal to capture calculated CRC in CRC block
);

logic [2:0] header_fill_counter_r;
logic [31:0] packet_header_r;
logic [15:0] payload_range_counter;
logic [63:0] crc_pipe_r;
logic header_fill_done;
logic [15:0] received_crc;
logic payload_range_done, payload_range_done_r;
logic transmission_active;
logic [2:0] num_of_valids, num_of_valids_r;
logic [2:0] crc_mux_sel;
logic [15:0] overflow;
logic [5:0] discard;
logic [3:0] overflow_bits;
logic chop;
integer i;

//*packet header decoding logic
assign transmission_active = data_valid_i[0] | data_valid_i[1] | data_valid_i[2] | data_valid_i[3];

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        packet_header_r <= 0;
        header_fill_counter_r <= 0;
    end
    else begin
        for(i=0; i<4; i++) begin
            if(data_valid_i[i] && !header_fill_done) begin
                header_fill_counter_r <= header_fill_counter_r + 1; // counts untill the packet_header_r is filled with the header
                packet_header_r[(i*8-8*header_fill_counter_r*active_lanes_i) +: 8] <= data_i[i]; // header_fill_counter_r*active_lanes_i gives the new offset each cycle
               
                `ifndef SYNTH 
                    $display("time=%0t i=%d, header_fill_counter_r=%d, active_lanes_i=%d, total=%d", $time, i,header_fill_counter_r,active_lanes_i, (i*8-8*header_fill_counter_r*active_lanes_i));
                `endif
            end
        end //! careful active_lanes_i must be valid
        // When all lanes go low reset and wait for header again NOPE
        if(!transmission_active) begin
            header_fill_counter_r <= 0;
            packet_header_r <= 0;
        end
    end
end

// packet header out should be assigned to its reg when valid only
assign header_fill_done = (header_fill_counter_r == unsigned'(3'd4>>active_lanes_i[2:1])); // The number of cycles needed to fill the header is (4 / active_lanes)
assign packet_header_o = (header_fill_done)? packet_header_r:0; // ECC logic is combinational to non valid data shouldn't be passed
assign packet_header_valid_o = header_fill_done;
assign overflow_bits = (4'b0011<<overflow);
assign discard = {overflow_bits[3:2],4'b0000} >> num_of_valids;
//* data and packet footer decoding logic
// payload and crc decoding logic What is the latnecy?
// When header filling is done start outputing payload data in the same throughput
// payload range counter
assign num_of_valids = data_valid_i[0] + data_valid_i[1] + data_valid_i[2] + data_valid_i[3];
assign overflow = ((payload_range_counter + num_of_valids)>payload_length_i)? payload_range_counter + num_of_valids - payload_length_i:0;
always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i) begin
        payload_range_counter <= 0;
        crc_pipe_r <= 0;
        num_of_valids_r <= 0;
        payload_range_done_r <= 1; // because the crc_capture_o would be raised after reset otherwise
        for(i=0; i<4; i++) begin
            payload_data_o[i] <= 0;
            payload_valid_o[i] <= 0;
        end
    end
    else begin
        num_of_valids_r <= num_of_valids;
        payload_range_done_r <= payload_range_done;

        if(payload_range_counter >= payload_length_i+2)
            payload_range_counter <= 0;
        else if(header_fill_done)
            payload_range_counter <= payload_range_counter + num_of_valids; // Ya but it can go over the payload range
            
        for(i=0; i<4; i++) begin
            if(data_valid_i[i] && header_fill_done && !payload_range_done) begin
                payload_data_o[i] <= data_i[i];
                payload_valid_o[i] <= !discard[i] & data_valid_i[i] & !chop;
            end
            else begin
                payload_data_o[i] <= 0;
                payload_valid_o[i] <= 0;
            end
        end
        
        // crc pipeline logic is used to pick up the CRC
        if(transmission_active)
            crc_pipe_r <= crc_pipe_r << (active_lanes_i * 8); // shifted by the amount of data available each cycle

        for(i=0; i<4; i++) begin
            if(data_valid_i[i])
                crc_pipe_r[(i*8-(4-active_lanes_i)*8) +: 8] <= data_i[i]; // pipeline range allocated for the data is a function of the number of active lanes
        end
    end
end

always@(posedge clk_i or negedge reset_n_i) begin
    if(!reset_n_i)
        chop <= 0;
    else begin
        if(!transmission_active)
            chop <= 0;
        else if(crc_capture_o)
            chop <= 1;
    end
end

// crc is received lsbyte first then msbyte second so we have to reflect
assign received_crc = crc_pipe_r[(active_lanes_i - num_of_valids_r)*8 +: 16]; // num_of_valids_r contains the last number of valids in a data stream. So it can be predicted where the last data inserted in the pipeling would be with the number of active lanes.
assign received_crc_o = {received_crc[7:0], received_crc[15:8]};
assign payload_range_done = (payload_range_counter >= payload_length_i);
assign crc_capture_o = !payload_range_done_r & payload_range_done;
assign crc_received_valid_o = (payload_range_counter == payload_length_i+2'd2); // This is obvious
assign crc_mux_sel = crc_received_valid_o? (num_of_valids_r-3'd3): (payload_range_counter==(payload_length_i+1'd1))? (num_of_valids_r-3'd2):(active_lanes_i-3'd1);
assign crc_mux_sel_o = crc_mux_sel[1:0];
// now selecting the last crc mux index is a little confusing. It is a function of the last number of valid data inputs. 
// For example of the number of active lanes are 4 and the last number of valids = 4, then payload range is at its maximum value, The 2 byte last data value is the CRC value and the index selected should be 4-3 = 1. Now extend this to other types of endings you get the above formula. 

endmodule