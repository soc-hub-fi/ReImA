module dual_port_ram_model #(
  parameter DATA_WIDTH = 14,
  parameter ADDR_WIDTH = 11
)(
  input                               rst_i, 
  input                               clk_i, 
  input                               rd_en_i, 
  input                               wr_en_i, 
  input           [ADDR_WIDTH-1:0]    wr_addr_i, 
  input           [DATA_WIDTH-1:0]    wr_data_i, 
  input           [ADDR_WIDTH-1:0]    rd_addr_i, 
  output logic    [DATA_WIDTH-1:0]    rd_data_o
);
    integer i;
    logic [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH];
    
    //write logic
    generate
        initial
            for(i=0; i<2**ADDR_WIDTH; i++)
                ram[i] = 0;
    endgenerate

    always@(posedge clk_i) begin
        if(wr_en_i)
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