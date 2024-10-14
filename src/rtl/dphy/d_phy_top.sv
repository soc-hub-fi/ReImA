module d_phy_top(
    input reset_n_i,
    input clk_i,
    // physical interface from pads
    inout  wire            clk_lane_n,
    inout  wire            clk_lane_p,
    inout  wire            data_lane_0_n,
    inout  wire            data_lane_0_p,
    inout  wire            data_lane_1_n,
    inout  wire            data_lane_1_p,
    inout  wire            data_lane_2_n,
    inout  wire            data_lane_2_p,
    inout  wire            data_lane_3_n,
    inout  wire            data_lane_3_p,
    //PPI
    output logic            rx_byte_clk_hs,
    output logic            rx_valid_hs_0,
    output logic   [7:0]    rx_data_hs_0,
    output logic            rx_valid_hs_1,
    output logic   [7:0]    rx_data_hs_1,
    output logic            rx_valid_hs_2,
    output logic   [7:0]    rx_data_hs_2,
    output logic            rx_valid_hs_3,
    output logic   [7:0]    rx_data_hs_3
);
    logic clock_lane;
    logic data_lane_0;
    logic data_lane_1;
    logic data_lane_2;
    logic data_lane_3;

    rx_io_dphy_data i_rx_io_dphy_data_l0(
                    .data_n_i(data_lane_0_n),
                    .data_p_i(data_lane_0_p),
                    .data_o(data_lane_0)
    );

    rx_io_dphy_data i_rx_io_dphy_data_l1(
                    .data_n_i(data_lane_1_n),
                    .data_p_i(data_lane_1_p),
                    .data_o(data_lane_1)
                    );
    rx_io_dphy_data i_rx_io_dphy_data_l2(
                    .data_n_i(data_lane_2_n),
                    .data_p_i(data_lane_2_p),
                    .data_o(data_lane_2)
                    );
    rx_io_dphy_data i_rx_io_dphy_data_l3(
                    .data_n_i(data_lane_3_n),
                    .data_p_i(data_lane_3_p),
                    .data_o(data_lane_3)
                    );
    rx_io_dphy_clock i_rx_io_dphy_clock(
                    .clock_n_i(clk_lane_n),
                    .clock_p_i(clk_lane_p),
                    .clock_o(clock_lane)
                    );
    
    rx_deserializer i_rx_deserializer(
                    .bit_clk_i(clock_lane),
                    .bit_data_lane0_i(data_lane_0),
                    .bit_data_lane1_i(data_lane_1),
                    .bit_data_lane2_i(data_lane_2),
                    .bit_data_lane3_i(data_lane_3),

                    .byte_clk_o(rx_byte_clk_hs),
                    .byte_data_lane0_o(rx_data_hs_0),
                    .byte_valid_lane0_o(rx_valid_hs_0),
                    .byte_data_lane1_o(rx_data_hs_1),
                    .byte_valid_lane1_o(rx_valid_hs_1),
                    .byte_data_lane2_o(rx_data_hs_2),
                    .byte_valid_lane2_o(rx_valid_hs_2),
                    .byte_data_lane3_o(rx_data_hs_3), 
                    .byte_valid_lane3_o(rx_valid_hs_3)     
    );
endmodule