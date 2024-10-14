
  //  Xilinx Simple Dual Port Single Clock RAM
  //  This code implements a parameterizable SDP single clock memory.
  //  If a reset or enable is not necessary, it may be tied off or removed from the code.
module xil_dual_port#(
  parameter RAM_WIDTH = 32,                  // Specify RAM data width
  parameter RAM_DEPTH = 2048,                  // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  parameter INIT_FILE = ""                       // Specify name/location of RAM initialization file if using one (leave blank if not)
)(
  input wire [clogb2(RAM_DEPTH-1)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
  input wire [clogb2(RAM_DEPTH-1)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
  input wire [RAM_WIDTH-1:0] dina,          // RAM input data
  input wire clka,                          // Clock
  input wire wea,                           // Write enable
  input wire enb,                           // Read Enable, for additional power savings, disable when not in use
  input wire rstb,                          // Output reset (does not affect memory contents)
  input wire regceb,                        // Output register enable
  output wire [RAM_WIDTH-1:0] doutb                  // RAM output data
);
  reg [RAM_WIDTH-1:0] ram_name [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram_name, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram_name[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clka) begin
    if (wea)
      ram_name[addra] <= dina;
    if (enb)
      ram_data <= ram_name[addrb];
  end

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
    if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

      // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
       assign doutb = ram_data;

    end else begin: output_register

      // The following is a 2 clock cycle read latency with improve clock-to-out timing

      reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

      always @(posedge clka)
        if (rstb)
          doutb_reg <= {RAM_WIDTH{1'b0}};
        else if (regceb)
          doutb_reg <= ram_data;

      assign doutb = doutb_reg;

    end
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
						
endmodule