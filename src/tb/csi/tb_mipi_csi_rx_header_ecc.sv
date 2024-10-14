`timescale 10ns/10ns
module tb_mipi_csi_rx_header_ecc();

// inputs
logic [31:0] packet_header_i; // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>
    
// outputs
logic [15:0] packet_length_o; // Wcount msb and lsb after correction
logic [1:0] vc_id_o; // virtual channel ID
logic [5:0] data_type_o; // Video data type such as RGB; RAW..etc
    //error sig
logic no_error_o;
logic corrected_error_o;
logic error_o;

mipi_csi_rx_header_ecc mipi_csi_rx_header_ecc_i (
    // inputs
    .packet_header_i, // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>
    
    // outputs
    .packet_length_o, // Wcount msb and lsb after correction
    .vc_id_o, // virtual channel ID
    .data_type_o, // Video data type such as RGB, RAW..etc
        //error sig
    .no_error_o,
    .corrected_error_o,
    .error_o
);


initial begin
    // No error
    packet_header_i = 32'h37_F0_01_3F;
    #10;
    // Single bit error
    packet_header_i = 32'h27_F0_01_3F;
    #10;
    // 2 bit errors
    packet_header_i = 32'h07_F0_01_3F;
    #10;
    // More than 2 bit error can'y be detected
    packet_header_i = 32'h00_F0_01_3F;
    #10;
    $finish;
end
endmodule