// -----------------------------------------------------------------------------
// Module: cu_crc16_top
// Description:
//   This module consists of 4 parallel CRC generators based on the polynomial
//   x^16 + x^12 + x^5 + 1. It uses a multiplexer to select the last CRC output
//   and a register to store the CRC value for the next input set.
//   Designed to stream data without lowering throughput.
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
module cu_crc16_top (
    input  logic        reset_n_i,             // Active low reset
    input  logic        clk_i,                 // Clock input
    input  logic        init_i,                // Initializes CRC to FFFF before every packet
    input  logic [7:0]  data_i        [4],     // Input data for CRC computation
    input  logic [1:0]  last_selection_i,      // Mux selection (0 picks crc_p[3], 3 picks crc_p[0])
    input  logic [15:0] received_crc_i,        // CRC received from transmitter
    input  logic        crc_received_valid_i,  // Indicates valid received CRC
    input  logic        crc_capture_i,         // Captures calculated CRC for comparison
    output logic        err_crc_o              // Indicates CRC error in received packet data
);

  // Internal signals
  logic [15:0] crc_p [4];       // Parallel CRC outputs
  logic [15:0] crc_r;           // Current CRC value
  logic [15:0] crc_calc;        // Calculated CRC value
  logic        crc_received_valid_r;
  logic [15:0] received_crc_r;

  // Instantiate parallel CRC generators
  cu_crc16_parallel cu_crc16_parallel_i3 (
      .crc_i(crc_r),
      .data_i(data_i[3]),
      .crc_o(crc_p[3])
  );

  cu_crc16_parallel cu_crc16_parallel_i2 (
      .crc_i(crc_p[3]),
      .data_i(data_i[2]),
      .crc_o(crc_p[2])
  );

  cu_crc16_parallel cu_crc16_parallel_i1 (
      .crc_i(crc_p[2]),
      .data_i(data_i[1]),
      .crc_o(crc_p[1])
  );

  cu_crc16_parallel cu_crc16_parallel_i0 (
      .crc_i(crc_p[1]),
      .data_i(data_i[0]),
      .crc_o(crc_p[0])
  );

  // Sequential logic for CRC computation
  always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      crc_r <= 16'hffff;
      crc_calc <= 16'hffff;
      crc_received_valid_r <= 1'b0;
      received_crc_r <= 16'h0;
    end else begin
      crc_received_valid_r <= crc_received_valid_i;
      received_crc_r <= received_crc_i;

      if (init_i) begin
        crc_r <= 16'hffff;
      end else begin
        crc_r <= crc_p[3 - last_selection_i]; // Select CRC output based on mux
      end

      if (crc_capture_i) begin
        crc_calc <= crc_p[3 - last_selection_i];
      end
    end
  end

  // CRC error detection
  assign err_crc_o = (crc_received_valid_r && (received_crc_r != crc_calc)) ? 1'b1 : 1'b0;

endmodule