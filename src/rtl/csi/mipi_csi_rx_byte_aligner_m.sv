/* 
    File: mipi_csi_rx_header_ecc.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality: 
    -   The module observes the lane for the SYNC_BYTE after which valid data is being received
    -   The module deasserts valid when input valid goes
    -   The module should begin to look for the SYNC_BYTE again after the EOT sequence is detected
    -   Should be moved to D-PHY RX module
    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/ 
module mipi_csi_rx_byte_aligner_m #(parameter MIPI_GEAR = 16)
                                (
                                input clk_i,
                                input reset_n_i,
                                input byte_valid_i,                 // valid byte doesn't mean valid payload data!!!
                                input [(MIPI_GEAR-1):0]byte_i,
                                output logic [(MIPI_GEAR-1):0]byte_o,
                                output logic byte_valid_o
                                );
    localparam SYNC_BYTE = 8'hB8;
    logic [2*MIPI_GEAR-1:0] scan_word;
    logic [MIPI_GEAR-1:0]first_byte;
    logic [MIPI_GEAR-1:0]second_byte;
    logic [$clog2(MIPI_GEAR)-1:0] offset_reg; // won't work with mipi_gear other than 16?
    logic synchronized_reg;
    logic [$clog2(MIPI_GEAR)-1:0] offset;
    logic synchronized;
    logic byte_valid_stage1_reg;
    logic byte_valid_stage2_reg;
    integer i;
    assign scan_word = {first_byte, second_byte};

    always_ff@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin
            first_byte <= 0;
            second_byte <= 0;
            offset_reg <= 0;
            synchronized_reg <= 0;
            byte_o <= 0;
            byte_valid_o <= 0;
            byte_valid_stage1_reg <= 0;
            byte_valid_stage2_reg <= 0;
        end
        else begin
            first_byte <= (byte_valid_i) ? byte_i : {MIPI_GEAR{1'b0}};
            second_byte <= first_byte;
            byte_valid_stage1_reg <= byte_valid_i;
            byte_valid_stage2_reg <= byte_valid_stage1_reg;

            if(synchronized) begin
                offset_reg <= offset;
                synchronized_reg <= 1;
            end

            if(synchronized_reg) begin
                byte_o <= scan_word[offset_reg +: MIPI_GEAR];
                byte_valid_o <= 1;
                if(!byte_valid_stage2_reg) begin // Should look for SYNC_BYTE again after EOT
                    first_byte <= 0;
                    second_byte <= 0;
                    offset_reg <= 0;
                    synchronized_reg <= 0;
                    byte_o <= 0;
                    byte_valid_o <= 0;
                end
            end
        end
    end

    always_comb begin
        offset = 0;
        synchronized = 0;
        for(i=MIPI_GEAR-1; i>=0; i--) begin
            if(scan_word[i+:8]==SYNC_BYTE && !synchronized_reg) begin   // Don't synchronize again if already synchronized
                                                                        //! What if there are multiple sync bytes in a stream?
                                                                        //* That is why you need to do it from MIPI_GEAR to 0 to make the last sync
                                                                        //* active which would be the first sync byte
                offset = i[$clog2(MIPI_GEAR)-1:0];
                synchronized = 1;
            end
        end
    end


endmodule