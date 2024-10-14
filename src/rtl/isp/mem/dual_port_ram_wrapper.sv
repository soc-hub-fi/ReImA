/* 
    File: line_ram_wrapper.sv
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
module dual_port_ram_wrapper#(   parameter ADDR_WIDTH=11,
                            parameter DATA_WIDTH=45,
                            parameter MEM_NUM=1  // number of memories
                    )
                        (
                            input                                                   reset_n_i,
                            input                                                   clk_i,
                            input           [MEM_NUM-1:0]                           ram_write_enable_i,
                            input           [MEM_NUM-1:0]                           ram_read_enable_i,
                            input           [ADDR_WIDTH-1:0]                        ram_write_address_i,
                            input           [DATA_WIDTH-1:0]                        ram_data_i,
                            input           [ADDR_WIDTH-1:0]                        ram_read_address_i,
                            output logic    [MEM_NUM-1:0]       [DATA_WIDTH-1:0]    ram_data_o          
                    );
    // for generate 4 times
    genvar i;
    generate
        for (i=0; i<MEM_NUM; i++) begin: gen_mem
            `ifdef ASIC
                //TODO instantiate line rams need to be added
                assign ram_data_o = 0;
            `elsif FPGA
                xil_dual_port#(
                                .RAM_WIDTH  ( DATA_WIDTH                ),  // Specify RAM data width
                                .RAM_DEPTH  ( 2**ADDR_WIDTH             )   // Specify RAM depth (number of entries)
                            )
                        line(
                                .rstb       (   ~reset_n_i              ),  // Output reset (does not affect memory contents)
                                .clka       (   clk_i                   ),  // Clock
                                .enb        (   ram_read_enable_i[i]    ),  // Read Enable, for additional power savings, disable when not in use
                                .wea        (   ram_write_enable_i[i]   ),  // Write enable
                                .addra      (   ram_write_address_i     ),  // Write address bus, width determined from RAM_DEPTH
                                .dina       (   ram_data_i              ),  // RAM input data
                                .addrb      (   ram_read_address_i      ),  // Read address bus, width determined from RAM_DEPTH
                                .doutb      (   ram_data_o[i]           ),   // RAM output data
                                .regceb     (   1'b0                    )  // Output register enable
                            );
            `else
                dual_port_ram_model#(   .ADDR_WIDTH(ADDR_WIDTH),
                                        .DATA_WIDTH(DATA_WIDTH)
                                ) 
                        line( 
                                .rst_i          (   ~reset_n_i              ), 
                                .clk_i          (   clk_i                   ), 		//data and address latch in on rising edge 
                                .rd_en_i        (   ram_read_enable_i[i]    ),
                                .wr_en_i        (   ram_write_enable_i[i]   ),
                                .wr_addr_i      (   ram_write_address_i     ),
                                .wr_data_i      (   ram_data_i              ),
                                .rd_addr_i      (   ram_read_address_i      ), 
                                .rd_data_o      (   ram_data_o[i]           )
                );
            `endif
        end
    endgenerate
endmodule