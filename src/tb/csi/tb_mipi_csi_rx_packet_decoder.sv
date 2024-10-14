`timescale 1ns/1ns

module tb_mipi_csi_rx_packet_decoder();
                                    // inputs
logic                   reset_n_i;
logic                   clk_i;
logic                   data_valid_i    [4];
logic           [7:0]   data_i          [4];    // mipi data 8 bits wide 4 data lanes
logic           [2:0]   active_lanes_i;         // active lanes coming from conifg register can be 1 2 or 4 lanes active
logic           [15:0]  payload_length_i;       // data length in bits = 8*payload_length_i

// outputs
logic    [0:31]  packet_header_o;        // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>
logic    [7:0]   payload_data_o  [4];    // mipi data 8 bits wide 4 data lanes
logic            payload_valid_o [4];
logic    [0:15]  received_crc_o;
logic    [1:0]   crc_mux_sel_o;
logic            crc_capture_o;
logic            crc_received_valid_o;
integer i;
logic test1 = 0;
logic test2 = 1;
mipi_csi_rx_packet_decoder mipi_csi_rx_packet_decoder_i (
                                    // inputs
                                    .reset_n_i,
                                    .clk_i,
                                    .data_valid_i,
                                    .data_i,    // mipi data 8 bits wide 4 data lanes
                                    .active_lanes_i,         // active lanes coming from conifg register can be 1 2 or 4 lanes active
                                    .payload_length_i,       // data length in bits = 8*payload_length_i


                                    .packet_header_o,        // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>
                                    .payload_data_o,    // mipi data 8 bits wide 4 data lanes
                                    .payload_valid_o,
                                    .received_crc_o,
                                    .crc_mux_sel_o,
                                    .crc_received_valid_o,
                                    .crc_capture_o
);

task send_data;
    input [7:0] data [4];    // mipi data 8 bits wide 4 data lanes
    begin
        for(i=0; i<4; i++) begin
            data_i[i] = data[i];
            if(data[i]==0)
                data_valid_i[i]=0;
            else
                data_valid_i[i]=1;
        end
        clk_i=0;
        #10;
        clk_i=1;
        #10;
    end
endtask

task cycle;
    begin
        data_valid_i[0] = 0;
        data_valid_i[1] = 0;
        data_valid_i[2] = 0;
        data_valid_i[3] = 0;
        clk_i=0;
        #10;
        clk_i=1;
        #10;
    end
endtask

task reset;
    clk_i=0;
    reset_n_i = 1;
    #10;
    reset_n_i = 0;
    clk_i=1;
    #10;
    reset_n_i = 1;
endtask

initial begin
    active_lanes_i = 3'd4;
    reset();
    if(test1) begin
    //*********************** 4 active lines
        // 4 valids at the end
        payload_length_i = 16'd6;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd6,8'd6,8'd6,8'd6});
        send_data('{8'd15,8'd15,8'd15,8'd15});
        send_data('{8'd20,8'd20,8'd15,8'd15});
        cycle();
        cycle();
        // 3 valids at the end
        payload_length_i = 16'd5;
        send_data('{8'd6,8'd6,8'd6,8'd6});
        send_data('{8'd15,8'd15,8'd15,8'd15});
        send_data('{8'd0,8'd20,8'd20,8'd15});
        cycle();
        cycle();
        // 2 valids at the end
        payload_length_i = 16'd4;
        send_data('{8'd6,8'd6,8'd6,8'd6});
        send_data('{8'd15,8'd15,8'd15,8'd15});
        send_data('{8'd0,8'd0,8'd20,8'd20});
        cycle();
        cycle();
        // 1 valid at the end
        payload_length_i = 16'd3;
        send_data('{8'd6,8'd6,8'd6,8'd6});
        send_data('{8'd20,8'd15,8'd15,8'd15});
        send_data('{8'd0,8'd0,8'd0,8'd20});
        cycle();
        cycle();
        //*********************** 2 active lines
        active_lanes_i = 3'd2;
        // 2 valids at the end
        payload_length_i = 16'd2;
        send_data('{8'd0,8'd0,8'd6,8'd6});
        send_data('{8'd0,8'd0,8'd6,8'd6});
        send_data('{8'd0,8'd0,8'd15,8'd15});
        send_data('{8'd0,8'd0,8'd20,8'd20});
        cycle();
        cycle();
        // 1 valid at the end
        payload_length_i = 16'd3;
        send_data('{8'd0,8'd0,8'd6,8'd6});
        send_data('{8'd0,8'd0,8'd6,8'd6});
        send_data('{8'd0,8'd0,8'd15,8'd15});
        send_data('{8'd0,8'd0,8'd20,8'd15});
        send_data('{8'd0,8'd0,8'd0,8'd20});
        cycle();
        cycle();
        //*********************** 1 active line
        active_lanes_i = 3'd1;
        // 2 valids at the end
        payload_length_i = 16'd2;
        send_data('{8'd0,8'd0,8'd0,8'd6});
        send_data('{8'd0,8'd0,8'd0,8'd6});
        send_data('{8'd0,8'd0,8'd0,8'd6});
        send_data('{8'd0,8'd0,8'd0,8'd6});
        send_data('{8'd0,8'd0,8'd0,8'd15});
        send_data('{8'd0,8'd0,8'd0,8'd15});
        send_data('{8'd0,8'd0,8'd0,8'd20});
        send_data('{8'd0,8'd0,8'd0,8'd20});
        cycle();
        cycle();
    end
    else if(test2) begin
        //*********************** 4 active lines
        // 4 valids at the end
        payload_length_i = 16'd6;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd4,8'd3,8'd2,8'd1});
        send_data('{8'd8,8'd7,8'd6,8'd5});
        send_data('{8'd12,8'd11,8'd10,8'd9});
        cycle();
        cycle();
        // 3 valids at the end
        payload_length_i = 16'd5;
        send_data('{8'd4,8'd3,8'd2,8'd1});
        send_data('{8'd8,8'd7,8'd6,8'd5});
        send_data('{8'd0,8'd11,8'd10,8'd9});
        cycle();
        cycle();
        // 2 valids at the end
        payload_length_i = 16'd4;
        send_data('{8'd4,8'd3,8'd2,8'd1});
        send_data('{8'd8,8'd7,8'd6,8'd5});
        send_data('{8'd0,8'd0,8'd10,8'd9});
        cycle();
        cycle();
        // 1 valid at the end
        payload_length_i = 16'd3;
        send_data('{8'd4,8'd3,8'd2,8'd1});
        send_data('{8'd8,8'd7,8'd6,8'd5});
        send_data('{8'd0,8'd0,8'd0,8'd9});
        cycle();
        cycle();
        //*********************** 2 active lines
        active_lanes_i = 3'd2;
        // 2 valids at the end
        payload_length_i = 16'd2;
        send_data('{8'd0,8'd0,8'd2,8'd1});
        send_data('{8'd0,8'd0,8'd4,8'd3});
        send_data('{8'd0,8'd0,8'd6,8'd5});
        send_data('{8'd0,8'd0,8'd8,8'd7});
        cycle();
        cycle();
        // 1 valid at the end
        payload_length_i = 16'd3;
        send_data('{8'd0,8'd0,8'd2,8'd1});
        send_data('{8'd0,8'd0,8'd4,8'd3});
        send_data('{8'd0,8'd0,8'd6,8'd5});
        send_data('{8'd0,8'd0,8'd8,8'd7});
        send_data('{8'd0,8'd0,8'd0,8'd9});
        cycle();
        cycle();
        //*********************** 1 active line
        active_lanes_i = 3'd1;
        // 2 valids at the end
        payload_length_i = 16'd2;
        send_data('{8'd0,8'd0,8'd0,8'd1});
        send_data('{8'd0,8'd0,8'd0,8'd2});
        send_data('{8'd0,8'd0,8'd0,8'd3});
        send_data('{8'd0,8'd0,8'd0,8'd4});
        send_data('{8'd0,8'd0,8'd0,8'd5});
        send_data('{8'd0,8'd0,8'd0,8'd6});
        send_data('{8'd0,8'd0,8'd0,8'd7});
        send_data('{8'd0,8'd0,8'd0,8'd8});
        cycle();
        cycle();
    end
    $finish;
end
endmodule