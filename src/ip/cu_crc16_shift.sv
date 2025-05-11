// -----------------------------------------------------------------------------
// Module: cu_crc16_shift
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// References: MIPI CSI RX specs v1.01
// Description:
//   Serial CRC generator based on the polynomial x^16 + x^12 + x^5 + 1.
//   Implements a shift-register-based CRC computation.
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
module cu_crc16_shift (
    input  logic        clk_i,     // Clock input
    input  logic        reset_i,   // Reset input (active high)
    input  logic        bit_i,     // Input bit for CRC computation
    input  logic [15:0] seed_i,    // Initial CRC seed value
    output logic [15:0] crc_o      // Computed CRC output
);

  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      crc_o <= seed_i;
    end else begin
      crc_o <= {crc_o[0], crc_o[15:1]};
      crc_o[15] <= bit_i ^ crc_o[0];
      crc_o[10] <= crc_o[11] ^ bit_i ^ crc_o[0];
      crc_o[3]  <= crc_o[4] ^ bit_i ^ crc_o[0];
    end
  end

endmodule