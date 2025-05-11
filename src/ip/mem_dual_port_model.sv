module mem_dual_port_model #(
  parameter int DataWidth = 14,
  parameter int AddrWidth = 11
) (
  input  logic                        rst_i, 
  input  logic                        clk_i, 
  input  logic                        rd_en_i, 
  input  logic                        wr_en_i, 
  input  logic [AddrWidth-1:0]       wr_addr_i, 
  input  logic [DataWidth-1:0]       wr_data_i, 
  input  logic [AddrWidth-1:0]       rd_addr_i, 
  output logic [DataWidth-1:0]       rd_data_o
);
  integer i;
  logic [DataWidth-1:0] ram [2**AddrWidth];

  //write logic
  generate
      initial
          for(i=0; i<2**AddrWidth; i++)
              ram[i] = 0;
  endgenerate

  always@(posedge clk_i) begin
      if(rst_i) begin
          for(i=0; i<2**AddrWidth; i++)
              ram[i] = 0;
      end
      else if(wr_en_i)
          ram[wr_addr_i] <= wr_data_i;
  end

  //read logic
  always@(posedge clk_i) begin
      if(rst_i)
          rd_data_o <= 0;
      else begin
          if(rd_en_i)
              rd_data_o <= ram[rd_addr_i];
      end
  end
endmodule