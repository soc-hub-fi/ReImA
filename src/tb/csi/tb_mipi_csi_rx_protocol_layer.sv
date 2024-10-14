`timescale 1ns/1ns

module tb_mipi_csi_rx_protocol_layer();

logic                   reset_n_i;
logic                   clk_i;
logic           [2:0]   active_lanes_i;         // Active lanes coming from conifg register can be 1 2 or 4 lanes active
logic                   data_valid_i    [4];
logic           [7:0]   data_i          [4];    // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
logic                   err_crc_o;
logic           [7:0]   data_id;
logic           [15:0]  word_count; 
logic [7:0]             ecc;
logic [15:0]            crc;    
integer i;     
mipi_csi_rx_protocol_layer mipi_csi_rx_protocol_layer_i(
                            .reset_n_i(reset_n_i),
                            .clk_i(clk_i),
                            .active_lanes_i(active_lanes_i),    // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                            .data_valid_i(data_valid_i),
                            .data_i(data_i),                    // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                                // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
                            .err_crc_o(err_crc_o)
);

task send_data;
    input [7:0] data [4];    // mipi data 8 bits wide 4 data lanes
    input data_valid [4];
    begin
        for(i=0; i<4; i++) begin
            data_i[i] = data[i];
            data_valid_i[i] = data_valid[i];
            //if(data[i]==0)
            //    data_valid_i[i]=0;
            //else
            //    data_valid_i[i]=1;
        end
        clk_i=1;
        #10;
        clk_i=0;
        #10;
    end
endtask

task cycle;
    begin
        data_valid_i[0] = 0;
        data_valid_i[1] = 0;
        data_valid_i[2] = 0;
        data_valid_i[3] = 0;
        clk_i=1;
        #10;
        clk_i=0;
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
    clk_i=0;
    reset_n_i = 1;
    #10;
endtask

initial begin
    data_id = 8'd1;
    word_count = 16'd5;
    ecc = 8'h3e; // calculated from an annoying online tool http://www.mathaddict.net/hamming.htm
    crc = 16'h1f47;
    reset();
    //******************4 lanes active with correct CRC and ECC
    active_lanes_i = 3'd4;
    //          [0]  [1]  [2]  [3]
    send_data('{ecc, word_count[15:8], word_count[7:0], data_id}, '{1, 1, 1, 1});
    send_data('{8'h15,8'h15,8'h15,8'h15}, '{1, 1, 1, 1});
    send_data('{8'd0,crc[15:8],crc[7:0],8'h15}, '{0, 1, 1, 1});
    cycle();
    cycle();

    //******************4 lanes active with incorrect CRC and ECC 1 bit change
    word_count = 16'd5;
    ecc = 8'h3e;
    crc = 16'h1f47;
    active_lanes_i = 3'd4;
    send_data('{ecc, word_count[15:8], word_count[7:0], data_id}, '{1, 1, 1, 1});
    send_data('{8'h15,8'h15,8'h15,8'h14}, '{1, 1, 1, 1}); // incorrect data
    send_data('{8'd0,crc[15:8],crc[7:0],8'h15}, '{0, 1, 1, 1});
    cycle();
    cycle();

    //******************2 lanes active with correct CRC and ECC
    word_count = 16'd5;
    ecc = 8'h3e;
    crc = 16'h1f47;
    active_lanes_i = 3'd2;
    send_data('{8'd0, 8'd0, word_count[7:0], data_id}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, ecc, word_count[15:8]}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, 8'h15, 8'h15}, '{0, 0, 1, 1}); // incorrect data
    send_data('{8'd0, 8'd0, 8'h15, 8'h15}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, crc[7:0], 8'h15}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'h0, 8'h0, crc[15:8]}, '{0, 0, 0, 1});
    cycle();
    cycle();

    //******************2 lanes active with incorrect CRC and ECC 1 bit change
    word_count = 16'd4; // change 1 bit in the word count instead of 5
    ecc = 8'h3e;
    crc = 16'h1f47;
    active_lanes_i = 3'd2;
    send_data('{8'd0, 8'd0, word_count[7:0], data_id}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, ecc, word_count[15:8]}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, 8'h15, 8'h14}, '{0, 0, 1, 1}); // incorrect data
    send_data('{8'd0, 8'd0, 8'h15, 8'h15}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'd0, crc[7:0], 8'h15}, '{0, 0, 1, 1});
    send_data('{8'd0, 8'h0, 8'h0, crc[15:8]}, '{0, 0, 0, 1});
    cycle();
    cycle();

    //******************1 lane active with correct CRC and ECC
    word_count = 16'd5;
    ecc = 8'h3e;
    crc = 16'h1f47;
    active_lanes_i = 3'd1;
    send_data('{8'd0, 8'd0, 8'd0, data_id}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, word_count[7:0]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, word_count[15:8]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, ecc}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, crc[7:0]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'h0, 8'h0, crc[15:8]}, '{0, 0, 0, 1});
    cycle();
    cycle();

    //******************1 lane active with incorrect CRC and ECC
    word_count = 16'd4;
    ecc = 8'h3e;
    crc = 16'h1f47;
    active_lanes_i = 3'd1;
    send_data('{8'd0, 8'd0, 8'd0, data_id}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, word_count[7:0]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, word_count[15:8]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, ecc}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h14}, '{0, 0, 0, 1}); // incorrect data
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'h0, 8'h15}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'd0, 8'd0, crc[7:0]}, '{0, 0, 0, 1});
    send_data('{8'd0, 8'h0, 8'h0, crc[15:8]}, '{0, 0, 0, 1});
    cycle();
    cycle();
    
    //!What if the word count is wrong and it cann't be detected!?

    $finish;
end

endmodule