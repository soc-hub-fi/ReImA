`include "../../rtl/csi/mipi_csi_data_types.svh"
`define CALC_ECC(G)({1'b0,\
                    1'b0,\
                    G[10]^G[11]^G[12]^G[13]^G[14]^G[15]^G[16]^G[17]^G[18]^G[19]^G[21]^G[22]^G[23],\
                    G[4]^G[5]^G[6]^G[7]^G[8]^G[9]^G[16]^G[17]^G[18]^G[19]^G[20]^G[22]^G[23],\
                    G[1]^G[2]^G[3]^G[7]^G[8]^G[9]^G[13]^G[14]^G[15]^G[19]^G[20]^G[21]^G[23],\
                    G[0]^G[2]^G[3]^G[5]^G[6]^G[9]^G[11]^G[12]^G[15]^G[18]^G[20]^G[21]^G[22],\
                    G[0]^G[1]^G[3]^G[4]^G[6]^G[8]^G[10]^G[12]^G[14]^G[17]^G[20]^G[21]^G[22]^G[23],\
                    G[0]^G[1]^G[2]^G[4]^G[5]^G[7]^G[10]^G[11]^G[13]^G[16]^G[20]^G[21]^G[22]^G[23]}\
                    )

module pattern_generator(
                        input                           reset_n_i,
                        input                           clk_i,
                        input                           enable_i,
                        // PPI interface
                        output reg                      err_sot_hs_o,
                        output reg                      err_sot_sync_hs_o,

                        output wire                     rx_byte_clk_hs_o,
                        output reg                      rx_valid_hs0_o,
                        output reg                      rx_valid_hs1_o,
                        output reg                      rx_valid_hs2_o,
                        output reg                      rx_valid_hs3_o,
                        output reg [7:0]                rx_data_hs0_o,
                        output reg [7:0]                rx_data_hs1_o,
                        output reg [7:0]                rx_data_hs2_o,
                        output reg [7:0]                rx_data_hs3_o,
                        output reg                      done_o
                    );
    
    
    parameter SYNC_BYTE= 8'hB8;
    localparam SEND_SYNCH=0, SEND_FSC=1, SEND_LSC=2, SEND_PH=3, SEND_PD=4, SEND_PF=5, SEND_LEC=6, SEND_FEC=7, SLEEP5=8;
    //? send SYNCH -> send FSC -> lower valid and wait 5 cycles -> ((send SYNCH -> send LSC -> lower valid and wait 5 cycles -> send SYNCH -> send ph -> send line -> send pf -> lower valid and wait 5 cycles -> send SYNCH -> send LEC)) -> repeat the steps in prackets 512 times -> send SYNCH -> send FEC
    reg [4:0] state;
    assign rx_byte_clk_hs_o = clk_i;
    wire [1:0] vc_id_i;
    assign vc_id_i = 0;
    reg odd;
    reg sleep_forever;
    reg [7:0] data_counter;
    reg [3:0] synch_counter;
    reg [3:0] sleep_counter;
    reg [15:0] line_counter;
    reg [23:0] D;
    wire [7:0] calculated_ecc;
    always@(*) begin
        case(state)
            SEND_FSC: D = {16'b1, vc_id_i, `FSC};
            SEND_FEC: D = {16'b1, vc_id_i, `FEC};
            SEND_LSC: D = {line_counter, vc_id_i, `LSC};
            SEND_LEC: D = {line_counter, vc_id_i, `LEC};
            SEND_PH:  D = {8'h02, 8'h00, vc_id_i, `RAW8};
            default: D = {8'h02, 8'h00, vc_id_i, `RAW8};
        endcase
    end
    always@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i) begin
            err_sot_hs_o <= 0;
            err_sot_sync_hs_o <= 0;
            sleep_forever <= 0;
            data_counter <= 0;
            synch_counter <= 0;
            sleep_counter <= 0;
            line_counter <= 1;
            odd <= 0;
            done_o <= 0;
            state <= SLEEP5;
            rx_valid_hs0_o <= 0;
            rx_valid_hs1_o <= 0;
            rx_valid_hs2_o <= 0;
            rx_valid_hs3_o <= 0;
            rx_data_hs0_o <= 0;
            rx_data_hs1_o <= 0;
            rx_data_hs2_o <= 0;
            rx_data_hs3_o <= 0;
        end
        else begin
            if(enable_i) begin
                rx_valid_hs3_o <= 1;
                rx_valid_hs2_o <= 1;
                rx_valid_hs1_o <= 1;
                rx_valid_hs0_o <= 1;
                case(state)
                SEND_SYNCH: begin
                    rx_data_hs3_o <= SYNC_BYTE;
                    rx_data_hs2_o <= SYNC_BYTE;
                    rx_data_hs1_o <= SYNC_BYTE;
                    rx_data_hs0_o <= SYNC_BYTE;
                    synch_counter <= synch_counter + 1;
                    if(synch_counter == 0)
                        state <= SEND_FSC;
                    else if(synch_counter == 1)
                        state <= SEND_LSC;
                    else if(synch_counter == 2)
                        state <= SEND_PH;
                    else if(synch_counter == 3) begin
                        state <= SEND_LEC;
                        if(line_counter == 'd512)
                            synch_counter <= 4;
                        else
                            synch_counter <= 1;
                    end
                    else if(synch_counter == 4) // after sending all the lines
                        state <= SEND_FEC;
                end
                SEND_FSC: begin
                    rx_data_hs3_o <= {vc_id_i, `FSC};
                    rx_data_hs2_o <= 1;
                    rx_data_hs1_o <= 0;
                    rx_data_hs0_o <= `CALC_ECC(D);
                    sleep_counter <= 0;
                    state <= SLEEP5;
                end
                SEND_LSC: begin
                    rx_data_hs3_o <= {vc_id_i, `LSC};
                    rx_data_hs2_o <= line_counter[7:0];
                    rx_data_hs1_o <= line_counter[15:8];
                    rx_data_hs0_o <= `CALC_ECC(D);
                    sleep_counter <= 0;
                    state <= SLEEP5;
                end
                SEND_PH: begin
                    rx_data_hs3_o <= {vc_id_i, `RAW8};
                    rx_data_hs2_o <= 8'h00;
                    rx_data_hs1_o <= 8'h02;
                    rx_data_hs0_o <= `CALC_ECC(D);
                    state <= SEND_PD;
                end
                SEND_PD: begin
                    data_counter <= data_counter + 1;
                    if(odd) begin //RGRG
                        rx_data_hs3_o <= 8'h00;
                        rx_data_hs2_o <= 8'hFF;
                        rx_data_hs1_o <= 8'h00;
                        rx_data_hs0_o <= 8'hFF;
                    end
                    else begin
                        rx_data_hs3_o <= 0;
                        rx_data_hs2_o <= 0;
                        rx_data_hs1_o <= 0;
                        rx_data_hs0_o <= 0;
                    end
                    if(data_counter == 'd128) begin
                        state <= SEND_PF;
                        data_counter <= 0;
                        odd <= ~odd;
                    end
                    else
                        state <= SEND_PD;
                end
                SEND_PF: begin
                    if(odd) begin //RGRG
                        rx_valid_hs1_o <= 0;
                        rx_valid_hs0_o <= 0;
                        rx_data_hs3_o <= 0;
                        rx_data_hs2_o <= 0;
                        rx_data_hs1_o <= 0;
                        rx_data_hs0_o <= 0;
                    end
                    else begin
                        rx_valid_hs1_o <= 0;
                        rx_valid_hs0_o <= 0;
                        rx_data_hs3_o <= 0;
                        rx_data_hs2_o <= 0;
                        rx_data_hs1_o <= 0;
                        rx_data_hs0_o <= 0;
                    end
                    sleep_counter <= 0;
                    state <= SLEEP5;
                end
                SEND_LEC: begin
                    line_counter <= line_counter + 1;
                    rx_data_hs3_o <= {vc_id_i, `LEC};
                    rx_data_hs2_o <= line_counter[7:0];
                    rx_data_hs1_o <= line_counter[15:8];
                    rx_data_hs0_o <= `CALC_ECC(D);
                    state <= SLEEP5;
                end
                SEND_FEC: begin

                    rx_data_hs3_o <= {vc_id_i, `FEC};
                    rx_data_hs2_o <= 1;
                    rx_data_hs1_o <= 0;
                    rx_data_hs0_o <= `CALC_ECC(D);
                    state <= SLEEP5;
                    sleep_forever <= 1;
                    done_o <= 1;
                    
                end
                SLEEP5: begin
                    sleep_counter <= sleep_counter + 1;
                    rx_valid_hs3_o <= 0;
                    rx_valid_hs2_o <= 0;
                    rx_valid_hs1_o <= 0;
                    rx_valid_hs0_o <= 0;
                    if(!sleep_forever)
                        if(sleep_counter == 5)
                            state <= SEND_SYNCH;
                end
                endcase
            end
        end
    end
endmodule