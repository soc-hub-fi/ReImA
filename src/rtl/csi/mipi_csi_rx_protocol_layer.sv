module mipi_csi_rx_protocol_layer(
                            input                   reset_n_i,
                            input                   clk_i,
                            input           [2:0]   active_lanes_i,         // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                            input                   data_valid_i    [4],
                            input           [7:0]   data_i          [4],    // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                                            // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
                            output                  err_crc_o


);

logic   [31:0]  packet_header;
logic    [7:0]   payload_data  [4];    // Mipi data 8 bits wide 4 data lanes
logic            payload_valid [4];
logic    [15:0]  received_crc;         // Packet Footer
logic    [1:0]   crc_mux_sel;          // Selects last input to the CRC mux
logic            crc_received_valid;   // Active high valid signal for the received CRC code
logic            crc_capture;           // Active high capture signal to capture calculated CRC in CRC block

logic    [15:0]  packet_length;    // Wcount msb and lsb after correction
logic    [1:0]   vc_id;            // virtual channel ID
logic    [5:0]   data_type;        // Video data type such as RGB, RAW..etc
logic            crc_no_error;         // no 1 or 2 bit errors can be asserted if higher bit errors are there
logic            crc_corrected_error;  // corrected 1 bit error
logic            crc_error;             // 2 bit error detected

mipi_csi_rx_packet_decoder mipi_csi_rx_packet_decoder_i(
                                    // inputs
                                    .reset_n_i              (reset_n_i),
                                    .clk_i                  (clk_i),
                                    .data_valid_i           (data_valid_i),
                                    .data_i                 (data_i),                // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                                                     // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
                                    .active_lanes_i         (active_lanes_i),        // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                                    .payload_length_i       (packet_length),         // Data length in bits = 8*payload_length_i coming from ECC after correction

                                    // outputs
                                    .packet_header_o        (packet_header),         // Packet header format <DataID 8bit> <WCount 8bit lsb> <WCount 8bit msb> <ECC 8bit>
                                    .payload_data_o         (payload_data),          // Mipi data 8 bits wide 4 data lanes
                                    .payload_valid_o        (payload_valid),
                                    .received_crc_o         (received_crc),          // Packet Footer
                                    .crc_mux_sel_o          (crc_mux_sel),           // Selects last input to the CRC mux
                                    .crc_received_valid_o   (crc_received_valid),    // Active high valid signal for the received CRC code
                                    .crc_capture_o          (crc_capture)            // Active high capture signal to capture calculated CRC in CRC block
);

mipi_csi_rx_header_ecc mipi_csi_rx_header_ecc_i(
                                // inputs
                                .packet_header_i    (packet_header),           // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>

                                // outputs
                                .packet_length_o    (packet_length),           // Wcount msb and lsb after correction
                                .vc_id_o            (vc_id),                   // virtual channel ID
                                .data_type_o        (data_type),               // Video data type such as RGB, RAW..etc
                                    //error sig
                                .no_error_o         (header_no_error),         // no 1 or 2 bit errors can be asserted if higher bit errors are there
                                .corrected_error_o  (header_corrected_error),  // corrected 1 bit error
                                .error_o            (header_error)             // 2 bit error detected
);

crc16_top crc16_top_i(
                                .reset_n_i              (reset_n_i),
                                .clk_i                  (clk_i),
                                .init_i                 (!payload_valid[3]),          // Active high, initializes the CRC to FFFF before every packet
                                .data_i                 (payload_data),
                                .last_selection_i       (crc_mux_sel),                // Selection for the mux 0 should pick crc_p[3] and 3 should pick crc_p[0]
                                .received_crc_i         (received_crc),               // CRC received from transmitter
                                .crc_received_valid_i   (crc_received_valid),
                                .crc_capture_i          (crc_capture),                // Active high signal to capture the calculated crc for comparison 
                                .err_crc_o              (err_crc_o)                   // Active high pulse signal that indecates an error in the received packet data
);

endmodule