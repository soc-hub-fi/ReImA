`include "mipi_csi_data_types.svh"
`timescale 1ns/1ns
module tb_mipi_csi_rx_packet_stream_controller();
        //* inputs
    logic                                       reset_n_i;
    logic                                       clk_i;
    logic                                       err_crc_i;                      // Active high pulse signal that indecates an error in the received packet data
        // register interface
    logic           [1:0]                       vc_id_reg_i             [4];
    logic           [5:0]                       data_type_reg_i         [4];
        // packet header
    logic                                       packet_header_valid_i;          //! packet header should stay as long as the valid data is there!!!!
    logic           [15:0]                      packet_length_i;                // Wcount msb and lsb after correction or can be some timing parameter
    logic           [1:0]                       vc_id_i;                        // virtual channel ID
    logic           [5:0]                       data_type_i;                    // Video data type such as RGB; RAW..etc
        // error logic
    logic                                       err_sot_sync_hs_i;
    logic                                       err_ecc_double_i;
        // clear errors
    logic                                       clear_frame_data_i      [4];    // active high pulse to clear err_frame_data register
    logic                                       clear_frame_sync_i      [4];    // active high pulse to clear err_frame_sync register
    //* outputs
        // activate streaming layer
    logic    [3:0]                       activate_stream_o;              // activate stream to receiver either short packet information or payload data
        // synchronization signals
    logic                                line_valid_o            [4];
    logic    [15:0]                      line_num_o              [4];    // Increments by 1(Non-Interlaced) or by an arbitrary value(Interlaced) and goes back
    logic                                frame_valid_o           [4];
    logic    [15:0]                      frame_num_o             [4];    // Increments by 1 for every FS packet with the same VCID and goes back
        // error signals //* Write 1 to clear
    logic                                err_frame_sync_o        [4];    // FS not paired with FE
    logic                                err_frame_data_o        [4];    // Frame has corrupted data
        // short packet timing information
    logic    [15:0]                      gsc1_o                  [4];    // generic short packet
    logic    [15:0]                      gsc2_o                  [4];    // generic short packet
    logic    [15:0]                      gsc3_o                  [4];    // generic short packet
    logic    [15:0]                      gsc4_o                  [4];    // generic short packet
    logic    [15:0]                      gsc5_o                  [4];    // generic short packet
    logic    [15:0]                      gsc6_o                  [4];    // generic short packet
    logic    [15:0]                      gsc7_o                  [4];    // generic short packet
    logic    [15:0]                      gsc8_o                  [4];    // generic short packet
    string test_indicator;
    integer i;
    mipi_csi_rx_packet_stream_controller mipi_csi_rx_packet_stream_controller_i
    (
        //* inputs
        .reset_n_i,
        .clk_i,
        .err_crc_i,                      // Active high pulse signal that indecates an error in the received packet data
            // register interface
        .vc_id_reg_i,
        .data_type_reg_i,
            // packet header
        .packet_header_valid_i,          //! packet header should stay as long as the valid data is there!!!!
        .packet_length_i,                // Wcount msb and lsb after correction or can be some timing parameter
        .vc_id_i,                        // virtual channel ID
        .data_type_i,                    // Video data type such as RGB(). RAW..etc
            // error input
        .err_sot_sync_hs_i,
        .err_ecc_double_i,
            // clear errors
        .clear_frame_data_i,    // active high pulse to clear err_frame_data register
        .clear_frame_sync_i,    // active high pulse to clear err_frame_sync register
        //* outputs
            // activate streaming layer
        .activate_stream_o,              // activate stream to receiver either short packet information or payload data
            // synchronization signals
        .line_valid_o,
        .line_num_o,    // Increments by 1(Non-Interlaced) or by an arbitrary value(Interlaced) and goes back
        .frame_valid_o,
        .frame_num_o,    // Increments by 1 for every FS packet with the same VCID and goes back
            // error signals //* Write 1 to clear
        .err_frame_sync_o,    // FS not paired with FE
        .err_frame_data_o,    // Frame has corrupted data
            // short packet timing information
        .gsc1_o,    // generic short packet
        .gsc2_o,    // generic short packet
        .gsc3_o,    // generic short packet
        .gsc4_o,    // generic short packet
        .gsc5_o,    // generic short packet
        .gsc6_o,    // generic short packet
        .gsc7_o,    // generic short packet
        .gsc8_o     // generic short packet
    );

    task cycle;
    begin
        clk_i=0;
        #10;
        clk_i=1;
        #10;
        packet_header_valid_i = 0;
    end
    endtask

    task reset;
    begin
        reset_n_i = 0;
        clk_i=0;
        #10;
        clk_i=1;
        #10;
        reset_n_i = 1;
    end
    endtask

    initial begin
        reset_n_i = 1;
        clk_i = 0;
        err_crc_i = 0;
        packet_header_valid_i = 0;
        packet_length_i = 0;
        vc_id_i = 0;
        data_type_i = 0;
        err_sot_sync_hs_i = 0;
        err_ecc_double_i = 0;
        for(i=0; i<4; i++) begin
            vc_id_reg_i[i] = 0;
            data_type_reg_i[i] = 0;
            clear_frame_data_i[i] = 0;
            clear_frame_sync_i[i] = 0;
        end
        cycle();
        reset();
        // activate streaming layer tests
        test_indicator = "activate streaming layer tests";
        vc_id_reg_i     [0] = 0;
        data_type_reg_i [0] = `YUV420_8;
        vc_id_reg_i     [1] = 1;
        data_type_reg_i [1] = `RGB444;
        vc_id_reg_i     [2] = 2;
        data_type_reg_i [2] = `RAW6;
        vc_id_reg_i     [3] = 3;
        data_type_reg_i [3] = `RAW8;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `YUV420_8;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `RGB444;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `RAW6;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `RAW8;
        cycle();
        cycle();

        // synchronization signals tests
        test_indicator = "synchronization signals tests FRAME";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FSC;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FSC;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FSC;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FEC;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FEC;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FEC;
        packet_length_i = 4;
        cycle();
        cycle();
        test_indicator = "synchronization signals tests LINE";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `LSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `LSC;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `LSC;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `LSC;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `LEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `LEC;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `LEC;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `LEC;
        packet_length_i = 4;
        cycle();
        cycle();
        // error signals //* Write 1 to clear tests
        test_indicator = "frame error signals tests vc0";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        err_crc_i = 1;
        cycle();
        err_crc_i = 0;
        cycle();
        clear_frame_sync_i[0] = 1;
        cycle();
        clear_frame_sync_i[0] = 0;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        clear_frame_sync_i[0] = 1;
        clear_frame_data_i[0] = 1;
        cycle();
        clear_frame_sync_i[0] = 0;
        clear_frame_data_i[0] = 0;
        cycle();
        cycle();
        test_indicator = "frame error signals tests vc1";
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FSC;
        packet_length_i = 1;
        err_crc_i = 1;
        cycle();
        err_crc_i = 0;
        cycle();
        clear_frame_sync_i[1] = 1;
        cycle();
        clear_frame_sync_i[1] = 0;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        clear_frame_sync_i[1] = 1;
        clear_frame_data_i[1] = 1;
        cycle();
        clear_frame_sync_i[1] = 0;
        clear_frame_data_i[1] = 0;
        cycle();
        test_indicator = "frame error signals tests vc2";
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FSC;
        packet_length_i = 1;
        err_crc_i = 1;
        cycle();
        err_crc_i = 0;
        cycle();
        clear_frame_sync_i[2] = 1;
        cycle();
        clear_frame_sync_i[2] = 0;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        clear_frame_sync_i[2] = 1;
        clear_frame_data_i[2] = 1;
        cycle();
        clear_frame_sync_i[2] = 0;
        clear_frame_data_i[2] = 0;
        cycle();
        test_indicator = "frame error signals tests vc3";
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FSC;
        packet_length_i = 1;
        err_crc_i = 1;
        cycle();
        err_crc_i = 0;
        cycle();
        clear_frame_sync_i[3] = 1;
        cycle();
        clear_frame_sync_i[3] = 0;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        clear_frame_sync_i[3] = 1;
        clear_frame_data_i[3] = 1;
        cycle();
        clear_frame_sync_i[3] = 0;
        clear_frame_data_i[3] = 0;
        cycle();
        // short packet timing information tests
        test_indicator = "short packet timing information tests vc0";
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i = `GSPC1;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC2;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC3;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC4;
        packet_length_i = 5;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC5;
        packet_length_i = 6;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC6;
        packet_length_i = 7;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC7;
        packet_length_i = 8;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC8;
        packet_length_i = 9;
        cycle();
        cycle();
        test_indicator = "short packet timing information tests vc1";
        packet_header_valid_i = 1;
        vc_id_i      = 1;
        data_type_i = `GSPC1;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC2;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC3;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC4;
        packet_length_i = 5;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC5;
        packet_length_i = 6;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC6;
        packet_length_i = 7;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC7;
        packet_length_i = 8;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC8;
        packet_length_i = 9;
        cycle();
        cycle();
        test_indicator = "short packet timing information tests vc2";
        packet_header_valid_i = 1;
        vc_id_i      = 2;
        data_type_i = `GSPC1;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC2;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC3;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC4;
        packet_length_i = 5;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC5;
        packet_length_i = 6;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC6;
        packet_length_i = 7;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC7;
        packet_length_i = 8;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC8;
        packet_length_i = 9;
        cycle();
        cycle();
        test_indicator = "short packet timing information tests vc3";
        packet_header_valid_i = 1;
        vc_id_i      = 3;
        data_type_i = `GSPC1;
        packet_length_i = 2;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC2;
        packet_length_i = 3;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC3;
        packet_length_i = 4;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC4;
        packet_length_i = 5;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC5;
        packet_length_i = 6;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC6;
        packet_length_i = 7;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC7;
        packet_length_i = 8;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC8;
        packet_length_i = 9;
        cycle();
        cycle();

        //* multi vc replication
        test_indicator = "(MULTI) activate streaming layer tests";
        vc_id_reg_i     [0] = 0;
        data_type_reg_i [0] = `RAW8;
        vc_id_reg_i     [1] = 0;
        data_type_reg_i [1] = `RAW8;
        vc_id_reg_i     [2] = 0;
        data_type_reg_i [2] = `RAW8;
        vc_id_reg_i     [3] = 0;
        data_type_reg_i [3] = `RAW8;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `RAW8;
        cycle();
        cycle();
        test_indicator = "(MULTI) synchronization signals tests FRAME";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        test_indicator = "(MULTI) synchronization signals tests LINE";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `LSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `LEC;
        packet_length_i = 1;
        cycle();
        cycle();
        test_indicator = "(MULTI) frame error signals tests vc0";
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FSC;
        packet_length_i = 1;
        err_crc_i = 1;
        cycle();
        err_crc_i = 0;
        cycle();
        clear_frame_sync_i[0] = 1;
        clear_frame_sync_i[1] = 1;
        clear_frame_sync_i[2] = 1;
        clear_frame_sync_i[3] = 1;
        cycle();
        clear_frame_sync_i[0] = 0;
        clear_frame_sync_i[1] = 0;
        clear_frame_sync_i[2] = 0;
        clear_frame_sync_i[3] = 0;
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i  = `FEC;
        packet_length_i = 1;
        cycle();
        cycle();
        clear_frame_sync_i[0] = 1;
        clear_frame_data_i[0] = 1;
        clear_frame_sync_i[1] = 1;
        clear_frame_data_i[1] = 1;
        clear_frame_sync_i[2] = 1;
        clear_frame_data_i[2] = 1;
        clear_frame_sync_i[3] = 1;
        clear_frame_data_i[3] = 1;
        cycle();
        clear_frame_sync_i[0] = 0;
        clear_frame_data_i[0] = 0;
        clear_frame_sync_i[1] = 0;
        clear_frame_data_i[1] = 0;
        clear_frame_sync_i[2] = 0;
        clear_frame_data_i[2] = 0;
        clear_frame_sync_i[3] = 0;
        clear_frame_data_i[3] = 0;
        cycle();
        cycle();
        test_indicator = "(MULTI) short packet timing information tests vc0";
        packet_header_valid_i = 1;
        vc_id_i      = 0;
        data_type_i = `GSPC1;
        packet_length_i = 10;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC2;
        packet_length_i = 11;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC3;
        packet_length_i = 12;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC4;
        packet_length_i = 13;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC5;
        packet_length_i = 14;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC6;
        packet_length_i = 15;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC7;
        packet_length_i = 16;
        cycle();
        cycle();
        packet_header_valid_i = 1;
        data_type_i = `GSPC8;
        packet_length_i = 17;
        cycle();
        cycle();

        $finish;
    end
    
endmodule