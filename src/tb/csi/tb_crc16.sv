`timescale 1ns/1ns

module tb_crc16();

logic reset_i;
logic clk_i;
logic [1:0] last_selection_i;
logic [7:0] byte_i [4];
logic [15:0] crc_parallel;

logic bit_i;
logic [15:0] seed_i;
logic [15:0] crc_serial;

integer i,j;

crc16_top crc16_top_i(
        .reset_i(reset_i),
        .clk_i(clk_i),
        .last_selection_i(last_selection_i),
        .byte_i(byte_i),
        .crc_o(crc_parallel)
);

crc16_shift crc16_shift_i(.clk_i,
.reset_i(reset_i),
.bit_i(bit_i),
.seed_i(seed_i),
.crc_o(crc_serial)
);

task send_data;
    input [191:0] data;
    begin
        //for(i=0; i<$size(data); i=i+32) begin
        //    byte_i[0] = data[i +: 8];
        //    byte_i[1] = data[i+8 +: 8];
        //    byte_i[2] = data[i+16 +: 8];
        //    byte_i[3] = data[i+24 +: 8];
        //    clk_i = 0;
        //    #10;
        //    clk_i = 1;
        //    #10;
        //end
        for(i=$size(data)-1; signed'(i)>0; i=i-32) begin
            byte_i[0] = data[i-7 +: 8];
            byte_i[1] = data[i-15 +: 8];
            byte_i[2] = data[i-23 +: 8];
            byte_i[3] = data[i-31 +: 8];
            clk_i = 0;
            #10;
            clk_i = 1;
            #10;
        end
        $display("crc_parallel = %h", crc_parallel);
    end
endtask

task send_bit;
    input [191:0] data;
    begin
        //for(i=0; i<$size(data); i=i+8) begin
        //    j=i+8;
        //    while (j>i) begin
        //        bit_i = data[j-1];
        //        clk_i = 0;
        //        #10;
        //        clk_i = 1;
        //        #10;
        //        j--;
        //    end
        //    //for(j=i+8; j>i-8; --j) begin
        //    //    bit_i = data[j-1];
        //    //    clk_i = 0;
        //    //    #10;
        //    //    clk_i = 1;
        //    //    #10;
        //    //end
        //end
        for(i=$size(data)-1; i>0; i=i-8) begin
            j=i-7;
            while (j<=i) begin
                bit_i = data[j];
                clk_i = 0;
                #10;
                clk_i = 1;
                #10;
                j++;
            end
            //for(j=i+8; j>i-8; --j) begin
            //    bit_i = data[j-1];
            //    clk_i = 0;
            //    #10;
            //    clk_i = 1;
            //    #10;
            //end
        end
        $display("crc_serial = %h", crc_serial);
    end
endtask

initial begin
   reset_i = 0;
   clk_i = 0;
   seed_i = 16'hffff;
   last_selection_i = 2'd3;
   #10
   reset_i = 1;
   #10
   reset_i = 0;
   send_data(192'hFF_00_00_02_B9_DC_F3_72_BB_D4_B8_5A_C8_75_C2_7C_81_F8_05_DF_FF_00_00_01);
   #10
   reset_i = 1;
   #10
   reset_i = 0;
   send_bit(192'hFF_00_00_02_B9_DC_F3_72_BB_D4_B8_5A_C8_75_C2_7C_81_F8_05_DF_FF_00_00_01);
   $finish;
end

endmodule