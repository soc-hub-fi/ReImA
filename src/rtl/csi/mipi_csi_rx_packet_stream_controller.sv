/* 
    File: mipi_csi_rx_packet_stream_controller.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality:
    
    -   If short packet is received send synchronization information to all streaming layers with the same VCID received
    -   If long packet is received send payload data to all streaming layers with the same VCID and Datatype received
    -   Detect if there was an error in the sequence of short packets sent for example if 2 FSC are sent without FEC inbetween
    -   Short packet data types are between 0x00 and 0x0F
    -   Long packet data types are between 0x10 and 0x3F
    -   Error signals functionality
            err_sot_hs,        Probably 1 bit error tolerance for the sot sequence, sent to app. layer, confidence in data is reduced, each lane should have that signal
            err_sot_sync_hs,   SOT sequence is corrupted that proper synchronization is not possible, sent to app. layer, whole transmission untill first D-PHY stop state is ignored, each lane should have that signal
            err_ecc_double,    2 bit error in ECC, sent to app. layer, whole transmission untill first stop state should be ignored, global for all VCID as it can't be decoded
            err_ecc_corrected, Should be sent to app. layer confidence in data integrity is reduced, global
            err_crc,           Should go to protocol decoding level to indicate payload data might be corrupted, it says might because CRC might be the corrupted one
            err_id,            Should go to app. layer, packet data type is unidentified and can't be unpacked, deasserted when FE comes on the same VCID
            err_frame_sync_o,    Should be passed to app. layer. Asserted when FS not paired with FE and when err_sot_sync_hs or err_ecc_double are asserted, each VC should have this signal
            err_frame_data_o,    Should be passed to app. layer, asserted on CRC error when the first FE comes , each VC should have this signal
    -   All error signals can be accessed by register
    -   //! Needs to be updaed gsc needs to be saved in a fifo and should be read from 1 by one by accessing a register

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/

`include "mipi_csi_data_types.svh"
module mipi_csi_rx_packet_stream_controller
                                (
                                //* inputs
                                input                                       reset_n_i,
                                input                                       clk_i,
                                input                                       err_crc_i,                      // Active high pulse signal that indecates an error in the received packet data
                                    // register interface
                                input           [1:0]                       vc_id_reg_i             [4],
                                input           [5:0]                       data_type_reg_i         [4],
                                    // packet header
                                input                                       packet_header_valid_i,          //! packet header should stay as long as the valid data is there!!!!
                                input           [15:0]                      packet_length_i,                // Wcount msb and lsb after correction or can be some timing parameter
                                input           [1:0]                       vc_id_i,                        // virtual channel ID
                                input           [5:0]                       data_type_i,                    // Video data type such as RGB, RAW..etc
                                    // error input
                                input                                       err_sot_sync_hs_i,
                                input                                       err_ecc_double_i,
                                    // clear errors
                                input           [3:0]                       clear_frame_data_i,    // active high pulse to clear err_frame_data register
                                input           [3:0]                       clear_frame_sync_i,    // active high pulse to clear err_frame_sync register
                                //* outputs
                                    // activate streaming layer
                                output logic    [3:0]                       activate_stream_o,              // activate stream to receiver either short packet information or payload data
                                    // synchronization signals
                                output logic                                line_valid_o            [4],    // line_valid_o [i] has access to all vc frame valids and one of them is seleced based on vc_id_reg[i]
                                output logic    [15:0]                      line_num_o              [4],    // Increments by 1(Non-Interlaced) or by an arbitrary value(Interlaced) and goes back
                                output logic                                frame_valid_o           [4],    // frame_valid_o [i] has access to all vc frame valids and one of them is seleced based on vc_id_reg[i]
                                output logic    [15:0]                      frame_num_o             [4],    // Increments by 1 for every FS packet with the same VCID and goes back
                                    // error signals //* Write 1 to clear
                                output logic                                err_frame_sync_o        [4],    // FS not paired with FE
                                output logic                                err_frame_data_o        [4],    // Frame has corrupted data
                                    // short packet timing information
                                output logic    [15:0]                      gsc1_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc2_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc3_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc4_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc5_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc6_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc7_o                  [4],    // generic short packet
                                output logic    [15:0]                      gsc8_o                  [4]     // generic short packet

);
    logic packet_header_valid_r;
    logic FS [4], FE [4];
    logic        line_valid_r  [4];
    logic [15:0] line_num_r    [4];
    logic        frame_valid_r [4];
    logic [15:0] frame_num_r   [4];
    logic err_frame_data     [4];
    logic payload_error_r[4];
    genvar i;

    typedef enum logic [2:0] {IDLE, CORR_FS, CORR_FE, INCORR_FS, INCORR_FE } state_type;
    state_type state[4], nextstate[4];

    // combinational better but care the path might be critical then payload won't need to be delayed
    // This will not allow embedded or null data to pass
    for(i=0; i<4; i++) begin
        always_ff@(posedge clk_i or negedge reset_n_i) begin
            if(!reset_n_i) begin
                activate_stream_o[i] <= 0;
            end
            else begin
                if(packet_header_valid_i && vc_id_i==vc_id_reg_i[i] && (data_type_i==data_type_reg_i[i] || data_type_i==`EMB)) // if long packet and VCID and Datatype matchs
                    activate_stream_o[i] <= 1;
                else // OW
                    activate_stream_o[i] <= 0;
            end
        end
    end

    // in case it is a long packet do we need to send the word count to the streaming layer?????????????
        //* Send the word count maybe we can use it in something
    // in case it is a short packet send frame number and line number and timing information if there is any.
    for(i=0; i<4; i++) begin // 4 different synchronization registers for the 4 possible virtual channels
        always_ff@(posedge clk_i or negedge reset_n_i) begin
            if(!reset_n_i) begin
                line_valid_r[i] <= 0;
                line_num_r[i] <= 0;
                frame_valid_r[i] <= 0;
                frame_num_r[i] <= 0;
                gsc1_o[i] <= 0;
                gsc2_o[i] <= 0;
                gsc3_o[i] <= 0;
                gsc4_o[i] <= 0;
                gsc5_o[i] <= 0;
                gsc6_o[i] <= 0;
                gsc7_o[i] <= 0;
                gsc8_o[i] <= 0;
            end
            else begin
                if(packet_header_valid_i && vc_id_i==vc_id_reg_i[i]) begin // when frame/line num is 0 it is inoperative so ignore !nope
                    case(data_type_i)
                    `FSC: begin
                        frame_valid_r[i] <= 1;   // FSC
                        frame_num_r[i] <= packet_length_i;
                    end
                    `FEC: frame_valid_r[i] <= 0; // FEC
                    `LSC: begin
                        line_valid_r[i] <= 1;    // LSC
                        line_num_r[i] <= packet_length_i;
                    end
                    `LEC: line_valid_r[i] <= 0;  // LEC
                    endcase
                end
                if(packet_header_valid_i && vc_id_i==vc_id_reg_i[i]) begin // generic short packet timing information
                    case(data_type_i)
                    `GSPC1: gsc1_o[i] <= packet_length_i;
                    `GSPC2: gsc2_o[i] <= packet_length_i;
                    `GSPC3: gsc3_o[i] <= packet_length_i;
                    `GSPC4: gsc4_o[i] <= packet_length_i;
                    `GSPC5: gsc5_o[i] <= packet_length_i;
                    `GSPC6: gsc6_o[i] <= packet_length_i;
                    `GSPC7: gsc7_o[i] <= packet_length_i;
                    `GSPC8: gsc8_o[i] <= packet_length_i;
                    endcase
                end
            end
        end
    end

    
    //*FSM for frame error detection
    for(i=0; i<4; i++) begin // 4 FSMs for each virtual channel
        assign FS[i] = (packet_header_valid_i & !packet_header_valid_r) & (data_type_i==`FSC) & (vc_id_i==vc_id_reg_i[i]); // FSC
        assign FE[i] = (packet_header_valid_i & !packet_header_valid_r) & (data_type_i==`FEC) & (vc_id_i==vc_id_reg_i[i]); // FEC
        
        always_ff@(posedge clk_i or negedge reset_n_i) begin
            if(!reset_n_i)
                state[i] <= IDLE;
            else
                state[i] <= nextstate[i];
        end
        
        always@(*) begin
            nextstate[i] = IDLE;
            case(state[i])
            IDLE: begin
                if(FE[i])
                    nextstate[i] = INCORR_FE;
                else if(FS[i])
                    nextstate[i] = CORR_FS;
                else
                    nextstate[i] = state[i];
            end
            CORR_FS: begin
                if(FS[i])
                    nextstate[i] = INCORR_FS;
                else if(FE[i])
                    nextstate[i] = CORR_FE;
                else
                    nextstate[i] = state[i];
                end
            CORR_FE: begin
                if(FE[i])
                    nextstate[i] = INCORR_FE;
                else if(FS[i])
                    nextstate[i] = CORR_FS;
                else
                    nextstate[i] = state[i];
                end
            INCORR_FS: begin
                if(FE[i])
                    nextstate[i] = CORR_FE;
                else
                    nextstate[i] = CORR_FS;
                end
            INCORR_FE: begin
                if(FS[i])
                    nextstate[i] = CORR_FS;
                else
                    nextstate[i] = CORR_FE;
                end
            endcase
        end
        
    end

    for(i=0; i<4; i++) begin
        always_ff@(posedge clk_i, negedge reset_n_i) begin
            if(!reset_n_i) begin
                payload_error_r[i] <= 0;
                err_frame_data_o[i] <= 0;
                err_frame_sync_o[i] <= 0;
            end
            else begin

                if(vc_id_reg_i[i]==vc_id_i) begin
                    if(err_crc_i)
                        payload_error_r[i] <= 1;
                    else if(err_frame_data_o[0] | err_frame_data_o[1] | err_frame_data_o[2] | err_frame_data_o[3])
                        payload_error_r[i] <= 0;
                end

                //* set confition takes priority over reset condition
                // frame data error set reset condition
                if(payload_error_r[i] && FE[i])
                    err_frame_data_o[i] <= 1;
                else if(clear_frame_data_i[i])
                    err_frame_data_o[i] <= 0;

                // frame sync error set reset condition
                // error start of transmission and error in ecc activate all the virtual channel frame erros becase we don't know which virtual channel is in error
                // probably so we dont use virtual channel guard
                if(state[i]==INCORR_FS | state[i]==INCORR_FE | err_sot_sync_hs_i | err_ecc_double_i)
                    err_frame_sync_o[i] <= 1;
                else if(clear_frame_sync_i[i])
                    err_frame_sync_o[i] <= 0;
            end
        end
    end

    // packet header valid reg
    always_ff@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i)
            packet_header_valid_r <= 0;
        else begin
            packet_header_valid_r <= packet_header_valid_i;
        end
    end

    // MUX for selecting which VC signals go to which streaming layer using the information in the register 
    for(i=0 ;i<4; i++) begin
        always@(*) begin
            line_valid_o[i]     = line_valid_r  [vc_id_reg_i[i]];
            line_num_o[i]       = line_num_r    [vc_id_reg_i[i]];
            frame_valid_o[i]    = frame_valid_r [vc_id_reg_i[i]];
            frame_num_o[i]      = frame_num_r   [vc_id_reg_i[i]];
        end
    end

endmodule