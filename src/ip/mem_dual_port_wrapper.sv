/* 
    File: mem_dual_port_wrapper.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References:

    Functionality:
    -   The file includes 4 lines RAMs used by the debayer filer to interpolate the RGB values
    -   The file has line RAMs for ASIC, FPGA and simualtion model.
        The instnatiation priority is as follows ASIC->FPGA->MODEL  
        One of these types are instantiated based on either ASIC or FPGA defines
        if both are defined ASIC RAMs are instantiated
        if neither are defined simulation model is instantiated

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
module mem_dual_port_wrappe #(   
  parameter int AddrWidth = 11,
  parameter int DataWidth = 45,
  parameter int MemNum = 1  // Number of memories
) (
  input  logic                                      reset_n_i,
  input  logic                                      clk_i,
  input  logic [MemNum-1:0]                         ram_write_enable_i,
  input  logic [MemNum-1:0]                         ram_read_enable_i,
  input  logic [AddrWidth-1:0]                      ram_write_address_i,
  input  logic [DataWidth-1:0]                      ram_data_i,
  input  logic [AddrWidth-1:0]                      ram_read_address_i,
  output logic [MemNum-1:0][DataWidth-1:0]          ram_data_o
);

  for (genvar i = 0; i < MemNum; i++) begin : gen_mem
    `ifdef ASIC
      // TODO: Instantiate line RAMs for ASIC
      assign ram_data_o = '0;
    `elsif FPGA
      xil_dual_port #(
          .RAM_WIDTH  (DataWidth),  // Specify RAM data width
          .RAM_DEPTH  (2**AddrWidth) // Specify RAM depth (number of entries)
      ) xil_dual_port_i (
          .rstb       (~reset_n_i),            // Output reset (does not affect memory contents)
          .clka       (clk_i),                 // Clock
          .enb        (ram_read_enable_i[i]),  // Read Enable, for additional power savings, disable when not in use
          .wea        (ram_write_enable_i[i]), // Write enable
          .addra      (ram_write_address_i),   // Write address bus, width determined from RAM_DEPTH
          .dina       (ram_data_i),            // RAM input data
          .addrb      (ram_read_address_i),    // Read address bus, width determined from RAM_DEPTH
          .doutb      (ram_data_o[i]),         // RAM output data
          .regceb     (1'b0)                   // Output register enable
      );
    `else
      mem_dual_port_model #(
          .AddrWidth  (AddrWidth),
          .DataWidth  (DataWidth)
      ) mem_dual_port_model_i (
          .rst_i      (~reset_n_i),
          .clk_i      (clk_i),                 // Data and address latch in on rising edge
          .rd_en_i    (ram_read_enable_i[i]),
          .wr_en_i    (ram_write_enable_i[i]),
          .wr_addr_i  (ram_write_address_i),
          .wr_data_i  (ram_data_i),
          .rd_addr_i  (ram_read_address_i),
          .rd_data_o  (ram_data_o[i])
      );
    `endif
  end
  
endmodule