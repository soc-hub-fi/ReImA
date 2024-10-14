/* 
    File: crc16_parallel.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality:
    -   This module is a parallel CRC generator based on the polynomial x^16+x^12+x^5+1
    -   This module is made using parallel CRC generator tool https://bues.ch/cms/hacking/crcgen
    -   Theory of where it comes from is here http://outputlogic.com/?p=158

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
module crc16_parallel (
    input           [15:0]  crcIn, // previous crc stage output
    input           [7:0]   data,
    output logic    [15:0]  crcOut
);
    assign crcOut[0] = crcIn[0] ^ crcIn[4] ^ crcIn[8] ^ data[0] ^ data[4];
    assign crcOut[1] = crcIn[1] ^ crcIn[5] ^ crcIn[9] ^ data[1] ^ data[5];
    assign crcOut[2] = crcIn[2] ^ crcIn[6] ^ crcIn[10] ^ data[2] ^ data[6];
    assign crcOut[3] = crcIn[0] ^ crcIn[3] ^ crcIn[7] ^ crcIn[11] ^ data[0] ^ data[3] ^ data[7];
    assign crcOut[4] = crcIn[1] ^ crcIn[12] ^ data[1];
    assign crcOut[5] = crcIn[2] ^ crcIn[13] ^ data[2];
    assign crcOut[6] = crcIn[3] ^ crcIn[14] ^ data[3];
    assign crcOut[7] = crcIn[0] ^ crcIn[4] ^ crcIn[15] ^ data[0] ^ data[4];
    assign crcOut[8] = crcIn[0] ^ crcIn[1] ^ crcIn[5] ^ data[0] ^ data[1] ^ data[5];
    assign crcOut[9] = crcIn[1] ^ crcIn[2] ^ crcIn[6] ^ data[1] ^ data[2] ^ data[6];
    assign crcOut[10] = crcIn[2] ^ crcIn[3] ^ crcIn[7] ^ data[2] ^ data[3] ^ data[7];
    assign crcOut[11] = crcIn[3] ^ data[3];
    assign crcOut[12] = crcIn[0] ^ crcIn[4] ^ data[0] ^ data[4];
    assign crcOut[13] = crcIn[1] ^ crcIn[5] ^ data[1] ^ data[5];
    assign crcOut[14] = crcIn[2] ^ crcIn[6] ^ data[2] ^ data[6];
    assign crcOut[15] = crcIn[3] ^ crcIn[7] ^ data[3] ^ data[7];
endmodule