`define YUV422_8    6'h1E
`define RGB888      6'h24
`define RGB565      6'h22
`define RAW8        6'h2A
`define RAW10       6'h2B

module tb_flow_control();
    logic YUV422_8_TEST = 1;
    logic RGB888_TEST = 1;
    logic RGB565_TEST = 1;
    logic RAW8_TEST=1;
    logic RAW10_TEST=1;

    integer i;
    logic               byte_clk_i;
    logic               reset_n_i;
    logic       [5:0]   data_type_i;                // Video data type such as RGB; RAW..etc
    logic       [47:0]  byte_data_i;               // Pixel data composed of 5 bytes max num of bytes needed for RAW10
    logic       [3:0]   byte_data_valid_i;         // Pixel data valid signal for each byte in the pixel data
    logic               pixel_clk_i;
    logic   [2:0]       pixel_per_clk_i;
    logic   [95:0]      pixel_data_o;
    logic   [3:0]       pixel_data_strobe_o;
    logic pixel_stream_stall_i;
    logic [2:0] ppc_list [3] = '{1,2,4};

    flow_control flow_control_i(
                        .reset_n_i(reset_n_i),
                        .byte_clk_i(byte_clk_i),
                        .pixel_clk_i(pixel_clk_i),
                        .pixel_per_clk_i(pixel_per_clk_i),
                        .pixel_stream_stall_i(pixel_stream_stall_i),
                        .data_type_i(data_type_i),               // Video data type such as RGB, RAW..etc
                        .byte_data_i(byte_data_i),               // Max width is 2 RGB888 pixels 2*24 = 28
                        .byte_data_valid_i(byte_data_valid_i),         // Pixel data valid signal for each pixel in the pixel data
                    
                        .pixel_data_o(pixel_data_o),              // Maximum Width(RGB888) = (8+8+8) * 4 = 96
                        .pixel_data_valid_o(pixel_data_strobe_o)
        );

task cycle10_pixel;
    pixel_clk_i = 1;
    #1
    pixel_clk_i = 0;
    #1
    pixel_clk_i = 1;
    #1
    pixel_clk_i = 0;
    #1
    pixel_clk_i = 1;
    #1
    pixel_clk_i = 0;
    #1
    pixel_clk_i = 1;
    #1
    pixel_clk_i = 0;
    #1
    pixel_clk_i = 1;
    #1;
    pixel_clk_i = 0;
    #1;
endtask

task send_data;
    input [2:0] num_of_pixels;    // insert the number of random value pixels needed 1,2, 3 or 4
    begin
        randomize(byte_data_i);
        for(int i=0; i<num_of_pixels; i++)
            byte_data_valid_i[i] <= 1;
        byte_clk_i=1;
        cycle10_pixel;
        byte_clk_i=0;
        cycle10_pixel;
    end
endtask

task cycle;
    begin
        byte_data_valid_i<= 0;
        byte_clk_i=1;
        cycle10_pixel;
        byte_clk_i=0;
        cycle10_pixel;
    end
endtask


task reset;
    byte_clk_i=0;
    reset_n_i = 1;
    cycle10_pixel;
    reset_n_i = 0;
    byte_clk_i=1;
    cycle10_pixel;
    byte_clk_i=0;
    reset_n_i = 1;
    cycle10_pixel;
endtask

initial begin
    pixel_stream_stall_i=0;
    data_type_i = 0;
    byte_data_i =0;
    byte_data_valid_i=0;
    pixel_per_clk_i=0;
    pixel_stream_stall_i=0;
    reset();
    for(int i=0; i<3; i++) begin
        pixel_per_clk_i = ppc_list[i];
        // initialization
        byte_data_i <= 0;
        byte_data_valid_i <= 0;
        if(YUV422_8_TEST) begin
            data_type_i = `YUV422_8;
            for(int i=0; i<5; i++) begin
                send_data($urandom_range(0,2)); // maximum 2 pixels in a cycle from 4 lanes
            end
        end
        if(RGB888_TEST) begin
            data_type_i = `RGB888;
            for(int i=0; i<5; i++) begin
                send_data($urandom_range(0,2)); // maximum 2 pixels in a cycle
            end
        end
        if(RGB565_TEST) begin
            data_type_i = `RGB565;
            for(int i=0; i<5; i++) begin
                send_data($urandom_range(0,2));
            end
        end
        if(RAW8_TEST) begin
            data_type_i = `RAW8;
            for(int i=0; i<5; i++) begin
                send_data($urandom_range(0,4));
            end
        end
        if(RAW10_TEST) begin
            data_type_i = `RAW10;
            for(int i=0; i<5; i++) begin
                send_data(4);
            end
        end
        cycle();
        cycle();
        cycle();
        cycle();
    end

    $finish;
end

//! Is there a checking mechanism to check for the correctness of data?

endmodule