module mem_pixel_array_wrapper(
    input                   reset_n_i,
    input                   pixel_clk_i,
    
    input           [7:0]   buffer_addr_i     [2],
    input                   buffer_wen_i      [2],
    input           [3:0]   buffer_ben_i      [2],
    input           [31:0]  buffer_wr_data_i  [2],
    output logic    [31:0]  buffer_rd_data_o  [2]
    );
    //TODO add tech memories
        `ifdef ASIC
                assign buffer_rd_data_o[0] = 0;
                assign buffer_rd_data_o[1] = 0;
        `elsif FPGA
                xil_single_port #(
                                        .NB_COL(4),
                                        .COL_WIDTH(32),
                                        .RAM_DEPTH(256) // 256
                                )
                buffer0  (
                                        .clka   (pixel_clk_i                    ),
                                        .rsta   (!reset_n_i                     ),
                                        .ena    (1'b1                           ),
                                        .addra  (buffer_addr_i          [0]     ),
                                        .dina   (buffer_wr_data_i       [0]     ),
                                        .wea    (!buffer_ben_i          [0]     ),
                                        .douta  (buffer_rd_data_o       [0]     ),
                                        .regcea (0                              )
                                );

                xil_single_port #(
                                        .NB_COL(4),
                                        .COL_WIDTH(32),
                                        .RAM_DEPTH(256) // 256
                                )
                buffer1  (
                                        .clka   (pixel_clk_i                    ),
                                        .rsta   (!reset_n_i                     ),
                                        .ena    (1'b1                           ),
                                        .addra  (buffer_addr_i          [1]     ),
                                        .dina   (buffer_wr_data_i       [1]     ),
                                        .wea    (!buffer_ben_i          [1]     ),
                                        .douta  (buffer_rd_data_o       [1]     ),
                                        .regcea (0                              )
                                );
        `else
                generic_memory #(
                                        .ADDR_WIDTH(8), // 256
                                        .DATA_WIDTH(32)
                                )
                buffer0  (
                                        .CLK    (pixel_clk_i),
                                        .INITN  (reset_n_i),
                                        .CEN    (1'b0),
                                        .A      (buffer_addr_i[0]),
                                        .WEN    (buffer_wen_i[0]),
                                        .D      (buffer_wr_data_i[0]),
                                        .BEN    (buffer_ben_i[0]),
                                        .Q      (buffer_rd_data_o[0])
                                );

                generic_memory #(
                                        .ADDR_WIDTH(8), // 256
                                        .DATA_WIDTH(32)
                                )
                buffer1  (
                                        .CLK    (pixel_clk_i),
                                        .INITN  (reset_n_i),
                                        .CEN    (1'b0),
                                        .A      (buffer_addr_i[1]),
                                        .WEN    (buffer_wen_i[1]),
                                        .D      (buffer_wr_data_i[1]),
                                        .BEN    (buffer_ben_i[1]),
                                        .Q      (buffer_rd_data_o[1])
                                );
        `endif
        endmodule