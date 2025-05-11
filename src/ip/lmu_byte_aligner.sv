//---------------------------------------------------------------------------------
// lmu_byte_aligner
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// References: According to MIPI CSI RX specs v1.01
// Functionality: 
//   The module observes the lane for the SyncByte after which valid data is being received
//   The module deasserts valid when input valid goes
//   The module should begin to look for the SyncByte again after the EOT sequence is detected
//   Should be moved to D-PHY RX module
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//--------------------------------------------------------------------------------
module lmu_byte_aligner #(
  parameter int MIPIGear = 16
) (
  input  logic                     clk_i,
  input  logic                     reset_n_i,
  input  logic                     byte_valid_i, // Valid byte doesn't mean valid payload data
  input  logic [MIPIGear-1:0]     byte_i,
  output logic [MIPIGear-1:0]     byte_o,
  output logic                     byte_valid_o
);
  localparam logic [7:0] SyncByte = 8'hB8;

  logic [2*MIPIGear-1:0] scan_word;
  logic [MIPIGear-1:0] first_byte;
  logic [MIPIGear-1:0] second_byte;
  logic synchronized_reg;
  logic synchronized;
  logic byte_valid_q;
  logic byte_valid_q2;
  int i;
  logic [$clog2(MIPIGear)-1:0] offset_d;
  logic [$clog2(MIPIGear)-1:0] offset_q;

  assign scan_word = {first_byte, second_byte};

  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      first_byte       <= '0;
      second_byte      <= '0;
      offset_q         <= '0;
      synchronized_reg <= 1'b0;
      byte_o           <= '0;
      byte_valid_o     <= 1'b0;
      byte_valid_q     <= 1'b0;
      byte_valid_q2    <= 1'b0;
    end else begin
      first_byte   <= (byte_valid_i) ? byte_i : '0;
      second_byte  <= first_byte;
      byte_valid_q <= byte_valid_i;
      byte_valid_q2 <= byte_valid_q;

      if (synchronized) begin
        offset_q         <= offset_d;
        synchronized_reg <= 1'b1;
      end

      if (synchronized_reg) begin
        byte_o       <= scan_word[offset_q +: MIPIGear];
        byte_valid_o <= 1'b1;
        if (!byte_valid_q2) begin
          // Reset state to look for SyncByte again after EOT
          first_byte       <= '0;
          second_byte      <= '0;
          offset_q         <= '0;
          synchronized_reg <= 1'b0;
          byte_o           <= '0;
          byte_valid_o     <= 1'b0;
        end
      end
    end
  end

  always_comb begin
    offset_d      = '0;
    synchronized  = 1'b0;
    for (i = MIPIGear - 1; i >= 0; i--) begin
      if ((scan_word[i +: 8] == SyncByte) && !synchronized_reg) begin
        // Avoid re-synchronization if already synchronized
        // Start from MIPIGear to 0 to prioritize the last sync byte
        offset_d     = i[$clog2(MIPIGear)-1:0];
        synchronized = 1'b1;
      end
    end
  end

endmodule