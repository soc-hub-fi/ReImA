//---------------------------------------------------------------------------------
// Module: lmu_lane_aligner.sv
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// References: According to MIPI CSI RX specs v1.01
// Functionality:
// Input should look like this
//  Lane 0-----data_i[0]-----  <ECC>               <data3> ..
//  Lane 1-----data_i[1]-----  <WCount MSByte>     <data2> ..
//  Lane 2-----data_i[2]-----  <WCount LSByte>     <data1> ..
//  Lane 3-----data_i[3]-----  <DataID>            <data0> ..
//    alignes the bytes of each lane on the same clock edge along with the valids
// Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
//--------------------------------------------------------------------------------
module lmu_lane_aligner #(
  parameter int MIPIGear = 16,
  parameter int MIPILanes = 4
) (
  input  logic                          reset_n_i,
  input  logic                          clk_i,
  input  logic [MIPILanes-1:0]         bytes_valid_i,
  input  logic [(MIPIGear * MIPILanes)-1:0] lane_bytes_i,
  output logic [(MIPIGear * MIPILanes)-1:0] lane_bytes_o,
  output logic [MIPILanes-1:0]         lane_valid_o
);

  // How many byte misalignment is allowed, whole package length must also be longer than this.
  // TODO: Investigate why this calculation was chosen and how it might differ in other scenarios.
  localparam logic [3:0] AlignDepth = 4'h7;

  logic [(MIPIGear * MIPILanes)-1:0]   data_lane_fifo [AlignDepth-1:0];
  logic [MIPILanes-1:0]                valid_lane_fifo [AlignDepth-1:0];
  logic [3:0]                          last_lane_bytes_index [MIPILanes-1:0];
  logic                                valid_out_reg;
  int                                  i;
  int                                  x;

  // Insert data into FIFO
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      for (i = 0; i < MIPILanes; i++) begin
        last_lane_bytes_index[i] <= 0;
      end
      for (x = 0; x < AlignDepth; x++) begin
        data_lane_fifo[x] <= '0;
        valid_lane_fifo[x] <= '0;
      end
    end else begin
      if (!(|bytes_valid_i || |lane_valid_o)) begin
        for (i = 0; i < MIPILanes; i++) begin
          last_lane_bytes_index[i] <= 0;
        end
      end
      for (i = 0; i < MIPILanes; i++) begin
        if (bytes_valid_i[i]) begin
          data_lane_fifo[0][i * MIPIGear +: MIPIGear] <= lane_bytes_i[i * MIPIGear +: MIPIGear];
          valid_lane_fifo[0][i] <= bytes_valid_i[i];

          last_lane_bytes_index[i] <= valid_out_reg ? last_lane_bytes_index[i] : last_lane_bytes_index[i] + 4'd1;

          for (x = 0; x < AlignDepth - 1; x++) begin
            data_lane_fifo[x + 1] <= data_lane_fifo[x];
            valid_lane_fifo[x + 1] <= valid_lane_fifo[x];
          end
        end
      end
    end
  end

  // Once all lanes are valid, stay valid until none are valid to not forget about the last bytes coming in.
  // This is implemented using a register to allow data to be written into the FIFO.
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      valid_out_reg <= 1'b0;
    end else begin
      if (&bytes_valid_i) begin
        valid_out_reg <= 1'b1;
      end else if (~|bytes_valid_i) begin
        valid_out_reg <= 1'b0;
      end
    end
  end

  // Extract data from FIFO
  always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      lane_valid_o <= '0;
      lane_bytes_o <= '0;
    end else begin
      if (valid_out_reg) begin
        for (int lane_idx = 0; lane_idx < MIPILanes; lane_idx++) begin
          lane_bytes_o[lane_idx * MIPIGear +: MIPIGear] <=
              data_lane_fifo[last_lane_bytes_index[lane_idx] - 1][lane_idx * MIPIGear +: MIPIGear];
          lane_valid_o[lane_idx] <=
              valid_lane_fifo[last_lane_bytes_index[lane_idx] - 1][lane_idx];
        end
      end else begin
        lane_valid_o <= '0;
        lane_bytes_o <= '0;
      end
    end
  end

endmodule