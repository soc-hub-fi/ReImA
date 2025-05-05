module cu_crc16_shift(
        input clk_i,
        input reset_i,
        input bit_i,
        input [15:0] seed_i,
        output logic [15:0] crc_o
);

always@(posedge clk_i or posedge reset_i) begin
    if(reset_i)
        crc_o <= seed_i;
    else begin
        crc_o <= {crc_o[0], crc_o[15:1]};
        crc_o[15] <= bit_i ^ crc_o[0];
        crc_o[10] <= crc_o[11] ^ bit_i ^ crc_o[0];
        crc_o[3] <= crc_o[4] ^ bit_i ^ crc_o[0];
    end
end

endmodule