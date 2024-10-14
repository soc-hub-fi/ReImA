`define YUV422_8    6'h1E
`define RGB888      6'h24
`define RGB565      6'h22
`define RAW8        6'h2A
`define RAW10       6'h2B

module tb_mipi_csi_rx_depacker();
logic YUV422_8_TEST = 1;
logic RGB888_TEST = 0;
logic RGB565_TEST = 0;
logic RAW8_TEST=0;
logic RAW10_TEST=0;
integer i;
logic               clk_i;
logic               reset_n_i;
logic       [2:0]   active_lanes_i;             // Active lanes coming from conifg register can be 1 2 or 4 lanes active
logic       [5:0]   data_type_i;                // Video data type such as RGB; RAW..etc
logic       [7:0]   payload_data_i      [4];    // Mipi data 8 bits wide 4 data lanes
logic               payload_valid_i     [4];
logic       [47:0]  pixel_data_o;               // Pixel data composed of 5 bytes max num of bytes needed for RAW10
logic       [3:0]  pixel_data_valid_o;         // Pixel data valid signal for each byte in the pixel data

mipi_csi_rx_depacker mipi_csi_rx_depacker_i(
                            .clk_i(clk_i),
                            .reset_n_i(reset_n_i),
                            .active_lanes_i(active_lanes_i),             // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                            .data_type_i(data_type_i),                // Video data type such as RGB, RAW..etc
                            .payload_data_i(payload_data_i),    // Mipi data 8 bits wide 4 data lanes
                            .payload_valid_i(payload_valid_i),
                            .pixel_data_o(pixel_data_o),               // Pixel data composed of 5 bytes max num of bytes needed for RAW10
                            .pixel_data_valid_o(pixel_data_valid_o)         // Pixel data valid signal for each byte in the pixel data
);

task send_data;
    input [7:0] data [4];    // mipi data 8 bits wide 4 data lanes
    input data_valid [4];
    begin
        for(i=0; i<4; i++) begin
            payload_data_i[i] <= data[i];
            payload_valid_i[i] <= data_valid[i];
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
        payload_valid_i[0] <= 0;
        payload_valid_i[1] <= 0;
        payload_valid_i[2] <= 0;
        payload_valid_i[3] <= 0;
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
    // initialization
    payload_data_i[0]=0;
    payload_data_i[1]=0;
    payload_data_i[2]=0;
    payload_data_i[3]=0;
    payload_valid_i[0] = 0;
    payload_valid_i[1] = 0;
    payload_valid_i[2] = 0;
    payload_valid_i[3] = 0;
    if(YUV422_8_TEST) begin
        data_type_i = `YUV422_8;
        active_lanes_i = 3'd4;
        reset();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        cycle();
        active_lanes_i = 3'd2;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd4,8'd3}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd4,8'd3}, '{0, 0, 1, 1});
        cycle();
        active_lanes_i = 3'd1;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd2}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd3}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd4}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd2}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd3}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd4}, '{0, 0, 0, 1});
        cycle();
    end
    if(RGB888_TEST) begin
        data_type_i = `RGB888;
        active_lanes_i = 3'd4;
        reset();
        //R -> 1, G -> 2, B -> 3
        //          [0]  [1]  [2]  [3]
        send_data('{8'd3,8'd1,8'd2,8'd3}, '{1, 1, 1, 1});
        send_data('{8'd2,8'd3,8'd1,8'd2}, '{1, 1, 1, 1});
        send_data('{8'd1,8'd2,8'd3,8'd1}, '{1, 1, 1, 1});
        cycle();
        send_data('{8'd3,8'd1,8'd2,8'd3}, '{1, 1, 1, 1});
        send_data('{8'd2,8'd3,8'd1,8'd2}, '{1, 1, 1, 1});
        send_data('{8'd1,8'd2,8'd3,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd1,8'd2,8'd3}, '{0, 1, 1, 1});
        cycle();
        send_data('{8'd3,8'd1,8'd2,8'd3}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd2}, '{0, 0, 1, 1});
        cycle();
        send_data('{8'd3,8'd1,8'd2,8'd3}, '{1, 1, 1, 1});
        send_data('{8'd2,8'd3,8'd1,8'd2}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        cycle();
        active_lanes_i = 3'd2;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd2,8'd3}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        cycle();
        send_data('{8'd0,8'd0,8'd2,8'd3}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd3,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd2}, '{0, 0, 1, 1});
        cycle();
        send_data('{8'd0,8'd0,8'd2,8'd3}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd3,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd2}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd3}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd3,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd2}, '{0, 0, 1, 1});
        cycle();
        active_lanes_i = 3'd1;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd3}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd2}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd3}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd2}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        cycle();
    end
    if(RGB565_TEST) begin
        data_type_i = `RGB565;
        active_lanes_i = 3'd4;
        reset();
        //R -> 1, G -> 2, B -> 3
        //          [0]  [1]  [2]  [3]
        send_data('{8'b1001_0100,8'b1110_0011,8'b1001_0100,8'b1110_0011}, '{1, 1, 1, 1});
        cycle();
        send_data('{8'b1001_0100,8'b1110_0011,8'b1001_0100,8'b1110_0011}, '{1, 1, 1, 1});
        send_data('{8'b0,8'b0,8'b1001_0100,8'b1110_0011}, '{0, 0, 1, 1});
        cycle();
        send_data('{8'b1001_0100,8'b1110_0011,8'b1001_0100,8'b1110_0011}, '{1, 1, 1, 1});
        send_data('{8'b1001_0100,8'b1110_0011,8'b1001_0100,8'b1110_0011}, '{1, 1, 1, 1});
        cycle();
        active_lanes_i = 3'd2;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'b1001_0100,8'b1110_0011}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'b1001_0100,8'b1110_0011}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'b1001_0100,8'b1110_0011}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'b1001_0100,8'b1110_0011}, '{0, 0, 1, 1});
        cycle();
        
        active_lanes_i = 3'd1;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'b1110_0011}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1001_0100}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1110_0011}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1001_0100}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1110_0011}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1001_0100}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1110_0011}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'b1001_0100}, '{0, 0, 0, 1});
        cycle();
    end
    if(RAW8_TEST) begin
        data_type_i = `RAW8;
        active_lanes_i = 3'd4;
        reset();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd3,8'd2,8'd1}, '{0, 1, 1, 1});
        cycle();
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        cycle();
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd4,8'd3,8'd2,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        cycle();
        active_lanes_i = 3'd2;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd2,8'd1}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        cycle();
        active_lanes_i = 3'd1;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd2}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd3}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd4}, '{0, 0, 0, 1});
        cycle();
    end
    if(RAW10_TEST) begin
        data_type_i = `RAW10;
        active_lanes_i = 3'd4;
        reset();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd1,8'd0,8'd0,8'd0}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{0, 0, 0, 1});
        cycle();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd1,8'd0,8'd0,8'd0}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd57,8'd1}, '{0, 0, 1, 1});
        cycle();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd1,8'd0,8'd0,8'd0}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd57,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd57,8'd1,8'd0}, '{0, 1, 1, 1});
        cycle();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd1,8'd0,8'd0,8'd0}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd0,8'd57,8'd1}, '{1, 1, 1, 1});
        send_data('{8'd0,8'd57,8'd1,8'd0}, '{1, 1, 1, 1});
        send_data('{8'd57,8'd1,8'd0,8'd0}, '{1, 1, 1, 1});
        cycle();
        active_lanes_i = 3'd2;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd0}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{0, 0, 0, 1});
        cycle();
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd1,8'd0}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 1, 1});
        send_data('{8'd0,8'd0,8'd57,8'd1}, '{0, 0, 1, 1});
        cycle();
        active_lanes_i = 3'd1;
        //          [0]  [1]  [2]  [3]
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd0}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd1}, '{0, 0, 0, 1});
        send_data('{8'd0,8'd0,8'd0,8'd57}, '{0, 0, 0, 1});
        cycle();
    end

    $finish;
end

//! Is there a checking mechanism to check for the correctness of data?


endmodule