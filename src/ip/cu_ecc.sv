/* 
    File: cu_ecc.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality: 
    -   Error Correction Code for packet header.
    -   Corrects 1 bit error and detects 2 bit errors, signals errors for application layer if found.
    -   Combinational block, data inserted should be 0 or valid data, should be handled by the previous stage in your design.
    //*TODO: If the syndrome is one of the elements of the Identity matrix then the parity has 1 bit error and pass the data as is
    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/ 
module cu_ecc (
                                // inputs
                                input                   packet_header_valid_i,
                                input           [31:0]  packet_header_i,    // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>

                                // outputs
                                output logic            header_valid_o,     // header valid signal untested
                                output logic    [15:0]  packet_length_o,    // Wcount msb and lsb after correction
                                output logic    [1:0]   vc_id_o,            // virtual channel ID
                                output logic    [5:0]   data_type_o,        // Video data type such as RGB, RAW..etc
                                    //error sig
                                output logic            no_error_o,         // no 1 or 2 bit errors can be asserted if higher bit errors are there
                                output logic            corrected_error_o,  // corrected 1 bit error
                                output logic            error_o             // 2 bit error detected
);

    logic [7:0] syndrome;
    logic [23:0] correct_bit; // indicates which bit will be corrected one hot
    logic [7:0] calculated_ecc; 
    logic [23:0] header_corrected; 
    logic [23:0] D; // stripped and reformatted packet header

                // <WCount MSB>        <WCount LSB>            <DataID>
    assign D = {packet_header_i[15:8], packet_header_i[23:16], packet_header_i[31:24]}; // reformat the header according to specs

    always_comb begin
        calculated_ecc[0] = D[0]^D[1]^D[2]^D[4]^D[5]^D[7]^D[10]^D[11]^D[13]^D[16]^D[20]^D[21]^D[22]^D[23];
        calculated_ecc[1] = D[0]^D[1]^D[3]^D[4]^D[6]^D[8]^D[10]^D[12]^D[14]^D[17]^D[20]^D[21]^D[22]^D[23];
        calculated_ecc[2] = D[0]^D[2]^D[3]^D[5]^D[6]^D[9]^D[11]^D[12]^D[15]^D[18]^D[20]^D[21]^D[22];
        calculated_ecc[3] = D[1]^D[2]^D[3]^D[7]^D[8]^D[9]^D[13]^D[14]^D[15]^D[19]^D[20]^D[21]^D[23];
        calculated_ecc[4] = D[4]^D[5]^D[6]^D[7]^D[8]^D[9]^D[16]^D[17]^D[18]^D[19]^D[20]^D[22]^D[23];
        calculated_ecc[5] = D[10]^D[11]^D[12]^D[13]^D[14]^D[15]^D[16]^D[17]^D[18]^D[19]^D[21]^D[22]^D[23];
        calculated_ecc[6] = 1'b0;
        calculated_ecc[7] = 1'b0;
    end
    
    assign syndrome = packet_header_i[7:0] ^ calculated_ecc; 

    //TODO error logic also (add here)
    always_comb begin
        correct_bit = 24'b0000_0000_0000_0000_0000_0000;
        no_error_o = 0;
        corrected_error_o = 1; // A workaround just to make the RTL look good
        error_o = 0;
        case(syndrome)
            8'h00: begin
                correct_bit = 24'b0000_0000_0000_0000_0000_0000; //no errors
                no_error_o = 1;
                corrected_error_o = 0;
            end
            8'h07: correct_bit = 24'b0000_0000_0000_0000_0000_0001;
            8'h0B: correct_bit = 24'b0000_0000_0000_0000_0000_0010;
            8'h0D: correct_bit = 24'b0000_0000_0000_0000_0000_0100;
            8'h0E: correct_bit = 24'b0000_0000_0000_0000_0000_1000;
            8'h13: correct_bit = 24'b0000_0000_0000_0000_0001_0000;
            8'h15: correct_bit = 24'b0000_0000_0000_0000_0010_0000;
            8'h16: correct_bit = 24'b0000_0000_0000_0000_0100_0000;
            8'h19: correct_bit = 24'b0000_0000_0000_0000_1000_0000;
            8'h1A: correct_bit = 24'b0000_0000_0000_0001_0000_0000;
            8'h1C: correct_bit = 24'b0000_0000_0000_0010_0000_0000;
            8'h23: correct_bit = 24'b0000_0000_0000_0100_0000_0000;
            8'h25: correct_bit = 24'b0000_0000_0000_1000_0000_0000;
            8'h26: correct_bit = 24'b0000_0000_0001_0000_0000_0000;
            8'h29: correct_bit = 24'b0000_0000_0010_0000_0000_0000;
            8'h2A: correct_bit = 24'b0000_0000_0100_0000_0000_0000;
            8'h2C: correct_bit = 24'b0000_0000_1000_0000_0000_0000;
            8'h31: correct_bit = 24'b0000_0001_0000_0000_0000_0000;
            8'h32: correct_bit = 24'b0000_0010_0000_0000_0000_0000;
            8'h34: correct_bit = 24'b0000_0100_0000_0000_0000_0000;
            8'h38: correct_bit = 24'b0000_1000_0000_0000_0000_0000;
            8'h1F: correct_bit = 24'b0001_0000_0000_0000_0000_0000;
            8'h2F: correct_bit = 24'b0010_0000_0000_0000_0000_0000;
            8'h37: correct_bit = 24'b0100_0000_0000_0000_0000_0000;
            8'h3B: correct_bit = 24'b1000_0000_0000_0000_0000_0000;
            default: begin
                correct_bit = 24'b0000_0000_0000_0000_0000_0000;
                error_o = 1;
                corrected_error_o = 0;
            end
        endcase
    end
    
    assign header_corrected = D ^ correct_bit;
    assign header_valid_o = packet_header_valid_i; //! untested 
    assign {packet_length_o, vc_id_o, data_type_o} = header_corrected;
    
endmodule