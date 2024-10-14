module rx_deserializer(
        input logic bit_clk_i,
        input logic bit_data_lane0_i,
        input logic bit_data_lane1_i,
        input logic bit_data_lane2_i,
        input logic bit_data_lane3_i,

        output logic       byte_clk_o,
        output logic [7:0] byte_data_lane0_o,
        output logic byte_valid_lane0_o,
        output logic [7:0] byte_data_lane1_o,
        output logic byte_valid_lane1_o,
        output logic [7:0] byte_data_lane2_o,
        output logic byte_valid_lane2_o,
        output logic [7:0] byte_data_lane3_o,
        output logic byte_valid_lane3_o
);
    `ifdef ASIC
        //assign byte_clk_o  = 0;
        assign byte_data_lane0_o = 0;
        assign byte_valid_lane0_o = 0;
        assign byte_data_lane1_o = 0;
        assign byte_valid_lane1_o = 0;
        assign byte_data_lane2_o = 0;
        assign byte_valid_lane2_o = 0;
        assign byte_data_lane3_o = 0;
        assign byte_valid_lane3_o = 0;
        tico_ctff_fast_async_en i_byte_clk_ff(
            .clk(bit_clk_i),
            .rst_n(1'b0),
            .enable(1'b0),
            .data_in(1'b0),
            .data_out(byte_clk_o)
        );
    `endif


endmodule