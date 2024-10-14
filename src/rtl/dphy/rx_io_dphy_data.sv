module rx_io_dphy_data(
    inout logic data_n_i,
    inout logic data_p_i,
    output logic data_o
);

    `ifdef ASIC
        assign data_o = 0;
    `endif

endmodule