// -----------------------------------------------------------------------------
// File: cu_stream_controller.sv
// Project: Part of MIPI Camera Serial Interface Implementation
// References: According to MIPI CSI RX specs v1.01

// Functionality:

//  If short packet is received send synchronization information to all streaming layers with the same VCID received
//  If long packet is received send payload data to all streaming layers with the same VCID and Datatype received
//  Detect if there was an error in the sequence of short packets sent for example if 2 FSC are sent without FEC inbetween
//  Short packet data types are between 0x00 and 0x0F
//  Long packet data types are between 0x10 and 0x3F
//  Error signals functionality
//      err_sot_sync_hs,   SOT sequence is corrupted that proper synchronization is not possible, sent to app. layer, whole transmission untill first D-PHY stop state is ignored, each lane should have that signal
//      err_ecc_double,    2 bit error in ECC, sent to app. layer, whole transmission untill first stop state should be ignored, global for all VCID as it can't be decoded
//      err_crc,           Should go to protocol decoding level to indicate payload data might be corrupted, it says might because CRC might be the corrupted one
//      err_frame_sync_o,    Should be passed to app. layer. Asserted when FS not paired with FE and when err_sot_sync_hs or err_ecc_double are asserted, each VC should have this signal
//      err_frame_data_o,    Should be passed to app. layer, asserted on CRC error when the first FE comes , each VC should have this signal
//  All error signals can be accessed by register
//  TODO Needs to be updaed gsc needs to be saved in a fifo and should be read from 1 by one by accessing a register
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------

`include "mipi_csi_data_types.svh"

module cu_stream_controller (
  // Inputs
  input logic         reset_n_i,
  input logic         clk_i,
  input logic         err_crc_i, // Active high pulse signal indicating an error in the received packet data

  // Register interface
  input logic [1:0]   vc_id_reg_i[4],
  input logic [5:0]   data_type_reg_i[4],

  // Packet header
  input logic         packet_header_valid_i,
  input logic [15:0]  packet_length_i,
  input logic [1:0]   vc_id_i,
  input logic [5:0]   data_type_i,

  // Error inputs
  input logic         err_sot_sync_hs_i,
  input logic         err_ecc_double_i,

  // Clear errors
  input logic [3:0]   clear_frame_data_i,
  input logic [3:0]   clear_frame_sync_i,

  // Outputs
  output logic [3:0]  activate_stream_o,
  output logic        line_valid_o[4],
  output logic [15:0] line_num_o[4],
  output logic        frame_valid_o[4],
  output logic [15:0] frame_num_o[4],
  output logic        err_frame_sync_o[4],
  output logic        err_frame_data_o[4],
  output logic [15:0] gsc1_o[4],
  output logic [15:0] gsc2_o[4],
  output logic [15:0] gsc3_o[4],
  output logic [15:0] gsc4_o[4],
  output logic [15:0] gsc5_o[4],
  output logic [15:0] gsc6_o[4],
  output logic [15:0] gsc7_o[4],
  output logic [15:0] gsc8_o[4]
);

  // Internal signals
  logic         packet_header_valid_r;
  logic         FS[4], FE[4];
  logic         line_valid_r[4];
  logic [15:0]  line_num_r[4];
  logic         frame_valid_r[4];
  logic [15:0]  frame_num_r[4];
  logic         err_frame_data[4];
  logic         payload_error_r[4];
  genvar        i;

  typedef enum logic [2:0] {
    IDLE,
    CORR_FS,
    CORR_FE,
    INCORR_FS,
    INCORR_FE
  } state_type;

  state_type state[4], nextstate[4];

  // Activate streaming layer
  generate
    for (i = 0; i < 4; i++) begin : gen_activate_stream
      always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
          activate_stream_o[i] <= 1'b0;
        end else begin
          if (packet_header_valid_i &&
            (vc_id_i == vc_id_reg_i[i]) &&
            ((data_type_i == data_type_reg_i[i]) || (data_type_i == `EMB))) begin
            activate_stream_o[i] <= 1'b1;
          end else begin
            activate_stream_o[i] <= 1'b0;
          end
        end
      end
    end
  endgenerate

  // Synchronization registers
  generate
    for (i = 0; i < 4; i++) begin : gen_sync_registers
      always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
          line_valid_r[i] <= 1'b0;
          line_num_r[i] <= 16'b0;
          frame_valid_r[i] <= 1'b0;
          frame_num_r[i] <= 16'b0;
          gsc1_o[i] <= 16'b0;
          gsc2_o[i] <= 16'b0;
          gsc3_o[i] <= 16'b0;
          gsc4_o[i] <= 16'b0;
          gsc5_o[i] <= 16'b0;
          gsc6_o[i] <= 16'b0;
          gsc7_o[i] <= 16'b0;
          gsc8_o[i] <= 16'b0;
        end else begin
          if (packet_header_valid_i && (vc_id_i == vc_id_reg_i[i])) begin
            case (data_type_i)
              `FSC: begin
                frame_valid_r[i] <= 1'b1;
                frame_num_r[i] <= packet_length_i;
              end
              `FEC: frame_valid_r[i] <= 1'b0;
              `LSC: begin
                line_valid_r[i] <= 1'b1;
                line_num_r[i] <= packet_length_i;
              end
              `LEC: line_valid_r[i] <= 1'b0;
            endcase

            case (data_type_i)
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
  endgenerate

  // FSM for frame error detection
  generate
    for (i = 0; i < 4; i++) begin : gen_fsm
      assign FS[i] = (packet_header_valid_i && !packet_header_valid_r) &&
               (data_type_i == `FSC) && (vc_id_i == vc_id_reg_i[i]);
      assign FE[i] = (packet_header_valid_i && !packet_header_valid_r) &&
               (data_type_i == `FEC) && (vc_id_i == vc_id_reg_i[i]);

      always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
          state[i] <= IDLE;
        end else begin
          state[i] <= nextstate[i];
        end
      end

      always_comb begin
        nextstate[i] = IDLE;
        case (state[i])
          IDLE: begin
            if (FE[i]) nextstate[i] = INCORR_FE;
            else if (FS[i]) nextstate[i] = CORR_FS;
          end
          CORR_FS: begin
            if (FS[i]) nextstate[i] = INCORR_FS;
            else if (FE[i]) nextstate[i] = CORR_FE;
          end
          CORR_FE: begin
            if (FE[i]) nextstate[i] = INCORR_FE;
            else if (FS[i]) nextstate[i] = CORR_FS;
          end
          INCORR_FS: begin
            if (FE[i]) nextstate[i] = CORR_FE;
          end
          INCORR_FE: begin
            if (FS[i]) nextstate[i] = CORR_FS;
          end
        endcase
      end
    end
  endgenerate

  // Error handling
  generate
    for (i = 0; i < 4; i++) begin : gen_error_handling
      always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
          payload_error_r[i] <= 1'b0;
          err_frame_data_o[i] <= 1'b0;
          err_frame_sync_o[i] <= 1'b0;
        end else begin
          if (vc_id_reg_i[i] == vc_id_i) begin
            if (err_crc_i) payload_error_r[i] <= 1'b1;
            else if (|err_frame_data_o) payload_error_r[i] <= 1'b0;
          end

          if (payload_error_r[i] && FE[i]) err_frame_data_o[i] <= 1'b1;
          else if (clear_frame_data_i[i]) err_frame_data_o[i] <= 1'b0;

          if ((state[i] == INCORR_FS) || (state[i] == INCORR_FE) ||
            err_sot_sync_hs_i || err_ecc_double_i) begin
            err_frame_sync_o[i] <= 1'b1;
          end else if (clear_frame_sync_i[i]) begin
            err_frame_sync_o[i] <= 1'b0;
          end
        end
      end
    end
  endgenerate

  // Packet header valid register
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      packet_header_valid_r <= 1'b0;
    end else begin
      packet_header_valid_r <= packet_header_valid_i;
    end
  end

  // MUX for selecting VC signals
  generate
    for (i = 0; i < 4; i++) begin : gen_mux
      always_comb begin
        line_valid_o[i] = line_valid_r[vc_id_reg_i[i]];
        line_num_o[i] = line_num_r[vc_id_reg_i[i]];
        frame_valid_o[i] = frame_valid_r[vc_id_reg_i[i]];
        frame_num_o[i] = frame_num_r[vc_id_reg_i[i]];
      end
    end
  endgenerate

endmodule