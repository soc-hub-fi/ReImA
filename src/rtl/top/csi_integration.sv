/*
    File: top_csi.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality: 
    -   The module is a top level integration for CSI blocks
    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
//`define DEPACKER_ASSERTION
//`include "uvm_pkg.sv"
`include "mipi_csi_data_types.svh"
module csi_integration (
                            // clock and reset interface
                            input                       reset_n_i,                      // Active low reset
                            input                       rx_byte_clk_hs_i,               //! byte clock from d-phy THIS CLOCK IS NON CONTINOUS
                            // configuration registers interface
                            input           [1:0]       vc_id_reg_i             [4],    // Picks a virtual channel to be processed for each ISP pipeline
                            input           [5:0]       data_type_reg_i         [4],    // Picks a datatype to be processed for each ISP pipeline
                            input           [2:0]       active_lanes_reg_i,             // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                            input           [3:0]       clear_frame_data_i,             // active high pulse to clear err_frame_data register 
                            input           [3:0]       clear_frame_sync_i,             // active high pulse to clear err_frame_sync register

                            // error signals interface
                            //input                       err_sot_hs_i,                   //!unconnected!!!! Probably 1 bit error tolerance for the sot sequence, sent to app. layer, confidence in data is reduced, each lane should have that signal
                            input                       err_sot_sync_hs_i,              // SOT sequence is corrupted that proper synchronization is not possible, sent to app. layer, 
                                                                                        // whole transmission untill first D-PHY stop state is ignored, each lane should have that signal
                            output logic                err_crc_o,                      // Active high pulse signal that indecates an error in the received packet data
                            output logic                err_frame_sync_o        [4],    // FS not paired with FE
                            output logic                err_frame_data_o        [4],    // Frame has corrupted data

                            // stream information interface
                            output logic    [3:0]       activate_stream_o,              // activate stream to receiver either short packet information or payload data
                            output logic                header_no_error_o,              // no 1 or 2 bit errors can be asserted if higher bit errors are there
                            output logic                header_corrected_error_o,       // corrected 1 bit error
                            output logic                header_error_o,                 // 2 bit error detected
                            output logic                line_valid_o            [4],    // line receiption active signal
                            output logic    [15:0]      line_num_o              [4],    // Increments by 1(Non-Interlaced) or by an arbitrary value(Interlaced) and goes back
                            output logic                frame_valid_o           [4],    // frame receiption active signal
                            output logic    [15:0]      frame_num_o             [4],    // Increments by 1 for every FS packet with the same VCID and goes back

                            // data interface
                            input                       rx_valid_hs_i           [4],    // valid signal for highspeed data transmission from d-phy
                            input           [7:0]       rx_data_hs_i            [4],    // highspeed data transmission from d-phy
                            output logic                line_valid_sync_fake_o,
                            output logic    [3:0]       byte_data_valid_o,              // Pixel data valid signal for each byte in the pixel data
                            output logic    [47:0]      byte_data_o                     // Pixel data composed of 5 bytes max num of bytes needed for RAW10
                    );

    parameter MIPI_GEAR = 8;
    parameter MIPI_LANES = 4;

    // byte aligne signals
    logic [(MIPI_GEAR-1):0]                 byte_o                  [MIPI_LANES];
    logic                                   byte_valid_o            [MIPI_LANES];

    // lane aligner signals
    logic [(MIPI_GEAR * MIPI_LANES-1):0]    bytes;
    logic [(MIPI_LANES-1):0]                bytes_valid;
    logic [((MIPI_GEAR * MIPI_LANES)-1):0]  lane_bytes;
    logic [(MIPI_LANES-1):0]                lane_valid;

    // packet decoder signals
    logic                                   sync_code;
    logic [15:0]                            packet_length_dc;
    logic                                   pd_data_valid           [4];
    logic [7:0]                             pd_data                 [4];
    logic [31:0]                            packet_header;
    logic                                   packet_header_valid;
    logic [7:0]                             payload_data            [4]; 
    logic                                   payload_valid           [4];
    logic [15:0]                            received_crc;      
    logic [1:0]                             crc_mux_sel;       
    logic                                   crc_received_valid;
    logic                                   crc_capture;       

    // ECC signals
    logic                                   header_valid;
    logic [15:0]                            packet_length;
    logic [1:0]                             vc_id;
    logic [5:0]                             data_type;
    logic [35:0]                            src_data;
    logic fifo_input_valid;
    genvar i;

    logic [7:0] rx_data_hs_sync_r [4];
    logic rx_valid_sync_r [4];
    assign rx_valid_sync_r = rx_valid_hs_i;
    assign rx_data_hs_sync_r = rx_data_hs_i;
//*---------------------------------------------------------------------------------------------------------------------------
//*                                         PROTOCOL LAYER                                                             
//*---------------------------------------------------------------------------------------------------------------------------

//------------------------------------------ instantiate packet decoder block ------------------------------------------//
    assign {>>{pd_data_valid}} = lane_valid;
    assign {>>{pd_data}} = lane_bytes;
    assign sync_code = (data_type == `LSC) | (data_type == `LEC) | (data_type == `FSC) | (data_type == `FEC);
    assign packet_length_dc = sync_code? 0:packet_length;
    mipi_csi_rx_packet_decoder
         mipi_csi_rx_packet_decoder_i   (
                                                // clocks and reset interface
                                                .reset_n_i              (   reset_n_i               ),
                                                .clk_i                  (   rx_byte_clk_hs_i        ),
                                                
                                                // register interface
                                                .active_lanes_i         (   active_lanes_reg_i      ),          // Active lanes coming from conifg register can be 1 2 or 4 lanes active

                                                // ECC interface
                                                .payload_length_i       (   packet_length_dc        ),          // Data length in bits = 8*payload_length_i coming from ECC after correction
                                                .packet_header_o        (   packet_header           ),          // Packet header format <DataID 8bit> <WCount 8bit lsb> <WCount 8bit msb> <ECC 8bit>
                                                .packet_header_valid_o  (   packet_header_valid     ),
                                                // CRC interface
                                                .received_crc_o         (   received_crc            ),          // Packet Footer
                                                .crc_mux_sel_o          (   crc_mux_sel             ),          // Selects last input to the CRC mux
                                                .crc_received_valid_o   (   crc_received_valid      ),          // Active high valid signal for the received CRC code
                                                .crc_capture_o          (   crc_capture             ),          // Active high capture signal to capture calculated CRC in CRC block

                                                // data interface
                                                .data_valid_i           (   rx_valid_sync_r         ),
                                                .data_i                 (   rx_data_hs_sync_r       ),          // Mipi data 8 bits wide 4 data lanes. In 4 lane mode, data[0] is LSByte, data[3] is MSByte. 
                                                                                                                // In 2 lane mode, data[2] is LSByte, data[3] is MSByte. In 1 lane mode only data[3] is connected.
                                                .payload_data_o         (   payload_data            ),          // Mipi data 8 bits wide 4 data lanes
                                                .payload_valid_o        (   payload_valid           )
                                                
                                            );

//------------------------------------------ instantiate header ecc block ------------------------------------------//

    mipi_csi_rx_header_ecc 
        mipi_csi_rx_header_ecc_i        (
                                                // packet decoder interface
                                                .packet_header_valid_i  (   packet_header_valid         ),
                                                .packet_header_i        (   packet_header               ),          // Packet header format <DataID 8bit> <WCount 8bit msb> <WCount 8bit lsb> <ECC 8bit>

                                                // corrected header
                                                .header_valid_o         (   header_valid                ),          //! untested signal
                                                .packet_length_o        (   packet_length               ),          // Wcount msb and lsb after correction
                                                .vc_id_o                (   vc_id                       ),          // virtual channel ID
                                                .data_type_o            (   data_type                   ),          // Video data type such as RGB, RAW..etc

                                                // error interface
                                                .no_error_o             (   header_no_error_o           ),          // no 1 or 2 bit errors can be asserted if higher bit errors are there
                                                .corrected_error_o      (   header_corrected_error_o    ),          // corrected 1 bit error
                                                .error_o                (   header_error_o              )           // 2 bit error detected
                                            );
    `ifndef FPGA
        /*ECCCheck: assert property(@(posedge rx_byte_clk_hs_i) disable iff (!reset_n_i )
        (   (header_no_error_o==1) && (header_corrected_error_o==0) && (header_error_o==0)))
        else $error ("ECC/error isn't correct");*/
    `endif

//------------------------------------------ instantiate crc block ------------------------------------------//

    crc16_top
        crc16_top_i                     (
                                                // clocks and reset interface
                                                .reset_n_i              (   reset_n_i               ),
                                                .clk_i                  (   rx_byte_clk_hs_i        ),

                                                // packet decoder interface
                                                .init_i                 (   !payload_valid[3]       ),          // Active high, initializes the CRC to FFFF before every packet
                                                .data_i                 (   payload_data            ),
                                                .last_selection_i       (   crc_mux_sel             ),          // Selection for the mux 0 should pick crc_p[3] and 3 should pick crc_p[0]
                                                .received_crc_i         (   received_crc            ),          // CRC received from transmitter
                                                .crc_received_valid_i   (   crc_received_valid      ),
                                                .crc_capture_i          (   crc_capture             ),          // Active high signal to capture the calculated crc for comparison

                                                // error interface
                                                .err_crc_o              (   err_crc_o               )           // Active high pulse signal that indecates an error in the received packet data
                                            );
    //`ifndef FPGA
    //    CRCCheck: assert property(@(posedge rx_byte_clk_hs_i) disable iff (!reset_n_i )
    //    (   (err_crc_o==0)))
    //    else $error ("CRC/error isn't correct");
    //`endif
//------------------------------------------ instantiate stream controller block ------------------------------------------//
    //TODO: After prototyping Update the gsc to a fifo that is read 1by1 by accessing the register
    mipi_csi_rx_packet_stream_controller
    mipi_csi_rx_packet_stream_controller_i  (
                                                //* inputs
                                                .reset_n_i              (   reset_n_i               ),
                                                .clk_i                  (   rx_byte_clk_hs_i        ),
                                                .err_crc_i              (   err_crc_o               ),          // Active high pulse signal that indecates an error in the received packet data
                                                    // register interface
                                                .vc_id_reg_i            (   vc_id_reg_i             ),
                                                .data_type_reg_i        (   data_type_reg_i         ),
                                                    // packet header
                                                .packet_header_valid_i  (   header_valid            ),          //? packet header should stay as long as the valid data is there!!!!
                                                .packet_length_i        (   packet_length           ),          // Wcount msb and lsb after correction or can be some timing parameter
                                                .vc_id_i                (   vc_id                   ),          // virtual channel ID
                                                .data_type_i            (   data_type               ),          // Video data type such as RGB(). RAW..etc
                                                    // error input
                                                .err_sot_sync_hs_i      (   err_sot_sync_hs_i       ),
                                                .err_ecc_double_i       (   header_error_o          ),
                                                    // clear errors
                                                .clear_frame_data_i     (   clear_frame_data_i      ),          // active high pulse to clear err_frame_data register
                                                .clear_frame_sync_i     (   clear_frame_sync_i      ),          // active high pulse to clear err_frame_sync register
                                                //* outputs
                                                    // activate streaming layer
                                                .activate_stream_o      (   activate_stream_o       ),          // activate stream to receiver either short packet information or payload data
                                                    // synchronization signals
                                                .line_valid_o           (   line_valid_o            ),
                                                .line_num_o             (   line_num_o              ),          // Increments by 1(Non-Interlaced) or by an arbitrary value(Interlaced) and goes back
                                                .frame_valid_o          (   frame_valid_o           ),
                                                .frame_num_o            (   frame_num_o             ),          // Increments by 1 for every FS packet with the same VCID and goes back
                                                    // error signals //* Write 1 to clear
                                                .err_frame_sync_o       (   err_frame_sync_o        ),          // FS not paired with FE
                                                .err_frame_data_o       (   err_frame_data_o        ),          // Frame has corrupted data
                                                    // short packet timing information
                                                .gsc1_o                 (                           ),          // generic short packet
                                                .gsc2_o                 (                           ),          // generic short packet
                                                .gsc3_o                 (                           ),          // generic short packet
                                                .gsc4_o                 (                           ),          // generic short packet
                                                .gsc5_o                 (                           ),          // generic short packet
                                                .gsc6_o                 (                           ),          // generic short packet
                                                .gsc7_o                 (                           ),          // generic short packet
                                                .gsc8_o                 (                           )           // generic short packet
                                        );

//------------------------------------------ instantiate depacker block ------------------------------------------//

    mipi_csi_rx_depacker
                        mipi_csi_rx_depacker_i(
                                                .clk_i                  (   rx_byte_clk_hs_i        ),
                                                .reset_n_i              (   reset_n_i               ),
                                                .active_lanes_i         (   active_lanes_reg_i      ),          // Active lanes coming from conifg register can be 1 2 or 4 lanes active
                                                .data_type_i            (   data_type               ),          // Video data type such as RGB, RAW..etc
                                                .payload_data_i         (   payload_data            ),          // Mipi data 8 bits wide 4 data lanes
                                                .payload_valid_i        (   payload_valid           ),
                                                .line_valid_sync_fake_o (   line_valid_sync_fake_o  ),
                                                .byte_data_o            (   byte_data_o             ),          // Pixel data composed of 5 bytes max num of bytes needed for RAW10
                                                .byte_data_valid_o      (   byte_data_valid_o       )           // Pixel data valid signal for each byte in the pixel data
                                        );
    `ifdef DEPACKER_ASSERTION
        logic [4:0] shift;
        for(i=0;i<4;i++) begin
            DepackerCheckData: assert property(@(posedge rx_byte_clk_hs_i) disable iff (!reset_n_i )
            (   (payload_valid[i]) |-> ##1 ((byte_data_o[(24-(i*8))+:8]==$past(payload_data[i],,,@(posedge rx_byte_clk_hs_i))) && (byte_data_valid_o[(3-(i))]==$past(payload_valid[i],,,@(posedge rx_byte_clk_hs_i))))))
            else $error ("depacker/data_or_valid isn't correct");
        end
    `endif
endmodule