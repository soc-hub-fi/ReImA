module rx_io_dphy_clock(
    inout logic clock_n_i,
    inout logic clock_p_i,
    output logic clock_o
);

    `ifdef ASIC
        assign clock_o = 0;
    `endif

endmodule