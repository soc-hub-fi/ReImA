//------------------------------------------------------------------------------
// Module   : csi_fpga_pkg
//
// Project  : Vector-Crypto Subsystem (Marian)
// Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
// Created  : 20-jan-2024
//
// Description: Package to contain types and values which will aid with FPGA
//              synthesis. The creation of this was motivated by the fact that
//              a number of PULP AXI components generate errors when running 
//              synthesis in Vivado.
//
// Revision History:
//  - Version 1.0: Initial release
//
//------------------------------------------------------------------------------

package csi_fpga_pkg;

`include "axi/typedef.svh"
`include "axi_assign.svh"

  import axi_pkg::*;
  import ara_pkg::*;

  // AXI Interface
  localparam int unsigned AxiDataWidth = 32;
  localparam int unsigned AxiAddrWidth =  32;
  localparam int unsigned AxiLiteAddrWidth =  9;
  localparam int unsigned AxiUserWidth =   1;
  localparam int unsigned AxiIdWidth   =   5;
  localparam int unsigned AxiStrbWidth = AxiDataWidth / 8;

  // Ara's AXI params
  localparam integer AxiWideDataWidth   = AxiDataWidth;
  localparam integer AxiWideStrbWidth   = AxiStrbWidth;
  // Ariane's AXI params
  localparam integer AxiNarrowDataWidth = 64;
  localparam integer AxiNarrowStrbWidth = AxiNarrowDataWidth / 8;
  localparam integer AxiCoreIdWidth     = AxiIdWidth - 1;
  // SoC AXI params
  localparam integer AxiSocIdWidth  = AxiIdWidth + $clog2(NrAXIMasters);
  // Periph AXI params
  localparam integer AxiPeriphDataWidth = 32;
  localparam integer AxiPeriphStrbWidth = AxiPeriphDataWidth / 8;
  localparam integer AxiPeriphIdWidth   = AxiUserWidth;

  // Dependant parameters. DO NOT CHANGE!
  typedef logic [      AxiDataWidth-1:0] axi_data_t;
  typedef logic [    AxiDataWidth/8-1:0] axi_strb_t;
  typedef logic [      AxiAddrWidth-1:0] axi_addr_t;
  typedef logic [      AxiLiteAddrWidth-1:0] axi_lite_addr_t;
  typedef logic [      AxiUserWidth-1:0] axi_user_t;
  typedef logic [        AxiIdWidth-1:0] axi_id_t  ;

  // internal types
  typedef logic [AxiNarrowDataWidth-1:0] axi_narrow_data_t;
  typedef logic [AxiNarrowStrbWidth-1:0] axi_narrow_strb_t;
  typedef logic [    AxiCoreIdWidth-1:0] axi_core_id_t;
  typedef logic [AxiPeriphDataWidth-1:0] axi_periph_data_t;
  typedef logic [AxiPeriphStrbWidth-1:0] axi_periph_strb_t;
  typedef logic [  AxiPeriphIdWidth-1:0] axi_periph_id_t;
  typedef logic [     AxiSocIdWidth-1:0] axi_soc_id_t;

  // AXI typedefs
  // PERIPH:
  `AXI_TYPEDEF_ALL(periph, axi_addr_t, axi_periph_id_t, axi_periph_data_t, axi_periph_strb_t,
  axi_user_t)

  // PERIPH_LITE:
  `AXI_LITE_TYPEDEF_ALL(periph_lite, axi_lite_addr_t, axi_periph_data_t, axi_periph_strb_t)

  // FPGA Memory Address Lengths
  localparam logic [63:0] DbgLength = 64'h1000;

  // FPGA Memory Map
  localparam logic [63:0] DbgBase  = 64'h0000_0000;
  localparam logic [63:0] QSPIBase = 64'h0000_3000;
  localparam logic [63:0] GPIOBase = 64'h0000_4000;
  localparam logic [63:0] TimrBase = 64'h0000_5000;
  localparam logic [63:0] DRAMBase = 64'h8000_0000;
  localparam logic [63:0] UARTBase = 64'hC000_0000;

endpackage
