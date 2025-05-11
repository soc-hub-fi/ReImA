// -----------------------------------------------------------------------------
// Module: cu_crc16_parallel
// Project: Reconfigurable Image Acqusition and Processing Subsystem for MPSoCs (ReImA)
// Description:
//   Parallel CRC generator based on the polynomial x^16 + x^12 + x^5 + 1.
//   Generated using the parallel CRC generator tool: https://bues.ch/cms/hacking/crcgen
//   Theory reference: http://outputlogic.com/?p=158
//
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// -----------------------------------------------------------------------------
module cu_crc16_parallel (
    input  logic [15:0] crc_i,  // Previous CRC stage output
    input  logic [7:0]  data_i, // Input data
    output logic [15:0] crc_o   // Computed CRC output
);

  assign crc_o[0] = crc_i[0] ^ crc_i[4] ^ crc_i[8] ^ data_i[0] ^ data_i[4];
  assign crc_o[1] = crc_i[1] ^ crc_i[5] ^ crc_i[9] ^ data_i[1] ^ data_i[5];
  assign crc_o[2] = crc_i[2] ^ crc_i[6] ^ crc_i[10] ^ data_i[2] ^ data_i[6];
  assign crc_o[3] = crc_i[0] ^ crc_i[3] ^ crc_i[7] ^ crc_i[11] ^ data_i[0] ^ data_i[3] ^ data_i[7];
  assign crc_o[4] = crc_i[1] ^ crc_i[12] ^ data_i[1];
  assign crc_o[5] = crc_i[2] ^ crc_i[13] ^ data_i[2];
  assign crc_o[6] = crc_i[3] ^ crc_i[14] ^ data_i[3];
  assign crc_o[7] = crc_i[0] ^ crc_i[4] ^ crc_i[15] ^ data_i[0] ^ data_i[4];
  assign crc_o[8] = crc_i[0] ^ crc_i[1] ^ crc_i[5] ^ data_i[0] ^ data_i[1] ^ data_i[5];
  assign crc_o[9] = crc_i[1] ^ crc_i[2] ^ crc_i[6] ^ data_i[1] ^ data_i[2] ^ data_i[6];
  assign crc_o[10] = crc_i[2] ^ crc_i[3] ^ crc_i[7] ^ data_i[2] ^ data_i[3] ^ data_i[7];
  assign crc_o[11] = crc_i[3] ^ data_i[3];
  assign crc_o[12] = crc_i[0] ^ crc_i[4] ^ data_i[0] ^ data_i[4];
  assign crc_o[13] = crc_i[1] ^ crc_i[5] ^ data_i[1] ^ data_i[5];
  assign crc_o[14] = crc_i[2] ^ crc_i[6] ^ data_i[2] ^ data_i[6];
  assign crc_o[15] = crc_i[3] ^ crc_i[7] ^ data_i[3] ^ data_i[7];

endmodule