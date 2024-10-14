//------------------------------------------------------------------------------
// Module   : marian_fpga_top
//
// Project  : Vector-Crypto Subsystem (Marian)
// Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
// Created  : 22-dec-2023
//
// Description: Top-level wrapper to be used in FPGA Prototype of Vector-Crypto
// Subsystem.
//
// Parameters:
//  - None
//
// Inputs:
//  - clk_p_i: External clock (+ve)
//  - clk_n_i: External clock (-ve)
//  - rst_i: Asynchronous active-high reset
//  - uart_rx_i: UART Rx
//  - jtag_tck_i: JTAG test clock
//  - jtag_tms_i: JTAG test mode select signal
//  - jtag_trst_i: JTAG test reset (async, actve-high)
//  - jtag_tdi_i: JTAG test data in
//
// Outputs:
//  - uart_tx_o: UART tx
//  - jtag_tdo_o: JTAG test data out
//
// Revision History:
//  - Version 1.0: Initial release
//
//------------------------------------------------------------------------------

module marian_fpga_top (
  //input  logic clk_p_i,
  //input  logic clk_n_i,
  input  logic clk_i,
  input  logic rst_i,
  // UART
  input  logic uart_rx_i,
  output logic uart_tx_o,
  // JTAG
  input  logic jtag_tck_i,
  input  logic jtag_tms_i,
  input  logic jtag_trst_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o
);

  import marian_fpga_pkg::*;

  `include "axi/typedef.svh"

  // Buses
  marian_fpga_pkg::system_req_t  marian_axi_req;
  marian_fpga_pkg::system_resp_t marian_axi_resp;
  marian_fpga_pkg::system_req_t  dbg_m_axi_req;
  marian_fpga_pkg::system_resp_t dbg_m_axi_resp;

  marian_fpga_pkg::system_resp_t dbg_s_axi_resp;
  marian_fpga_pkg::system_req_t  dbg_s_axi_req;
  marian_fpga_pkg::system_resp_t uart_s_axi_resp;
  marian_fpga_pkg::system_req_t  uart_s_axi_req;
  marian_fpga_pkg::system_resp_t qspi_s_axi_resp;
  marian_fpga_pkg::system_req_t  qspi_s_axi_req;
  marian_fpga_pkg::system_resp_t gpio_s_axi_resp;
  marian_fpga_pkg::system_req_t  gpio_s_axi_req;
  marian_fpga_pkg::system_resp_t timer_s_axi_resp;
  marian_fpga_pkg::system_req_t  timer_s_axi_req;
  marian_fpga_pkg::system_resp_t memory_s_axi_resp;
  marian_fpga_pkg::system_req_t  memory_s_axi_req;

  // Ariane configuration
  localparam ariane_pkg::ariane_cfg_t ArianeAraConfig = '{
    RASDepth             :   2,
    BTBEntries           :  32,
    BHTEntries           : 128,
    // idempotent region
    NrNonIdempotentRules : 2,
    NonIdempotentAddrBase: {64'b0, 64'b0},
    NonIdempotentLength  : {64'b0, 64'b0},
    NrExecuteRegionRules : 3,
    //                      DRAM,       Boot ROM,   Debug Module
    ExecuteRegionAddrBase: {DRAMBase,   64'h1_0000, DbgBase},
    ExecuteRegionLength  : {DRAMLength, 64'h10000,  DbgLength},
    // cached region
    NrCachedRegionRules  : 1,
    CachedRegionAddrBase : {DRAMBase},
    CachedRegionLength   : {DRAMLength},
    //  cache config
    Axi64BitCompliant    : 1'b1,
    SwapEndianess        : 1'b0,
    // debug
    DmBaseAddress        : 64'h0,
    NrPMPEntries         : 0
  };

  logic locked;
  logic rstn_s;
  logic top_clk;
  logic jtag_trstn_s;

  logic [2:0] hart_id_s;
  logic       debug_req_irq_s;

  assign hart_id_s = '0;
  assign rstn_s    = locked;
  // invert JTAG reset as buttons on VCU118 are active-high
  assign jtag_trstn_s = ~jtag_trst_i;

// Bypass top_clock in behavioural simulation
`ifndef XSIM

  // top clock instance
  top_clock i_top_clock (
    .clk_in1    ( clk_i    ),
    .reset      ( rst_i    ),
    .locked     ( locked   ), // output locked, used for reset
    .clk_out1   ( top_clk  )
  );

`else

  assign top_clk = clk_i;
  assign locked  = ~rst_i;

`endif

  // system containing Ara, Ariane and AXI infrastructure
  marian_fpga_system #(
    .ArianeCfg          ( ArianeAraConfig )
  ) i_marian_system (
    .clk_i         ( top_clk         ),
    .rst_ni        ( locked          ),
    .boot_addr_i   ( DRAMBase        ),
    .hart_id_i     ( hart_id_s       ),
    .scan_enable_i ( 1'b0            ),
    .scan_data_i   ( 1'b0            ),
    .scan_data_o   ( /* UNUSED */    ),
    .debug_req_i   ( debug_req_irq_s ),
    .axi_req_o     ( marian_axi_req  ),
    .axi_resp_i    ( marian_axi_resp )
  );

  /*****************
   * 128b AXI xbar *
   *****************/
  axi_xbar_128_wrapper i_axi_xbar (
    .clk_i               ( top_clk           ),
    .rstn_i              ( locked            ),
    .marian_m_axi_req_i  ( marian_axi_req    ),
    .marian_m_axi_resp_o ( marian_axi_resp   ),
    .dbg_m_axi_req_i     ( dbg_m_axi_req     ),
    .dbg_m_axi_resp_o    ( dbg_m_axi_resp    ),
    .dbg_s_axi_resp_i    ( dbg_s_axi_resp    ),
    .dbg_s_axi_req_o     ( dbg_s_axi_req     ),
    .uart_s_axi_resp_i   ( uart_s_axi_resp   ),
    .uart_s_axi_req_o    ( uart_s_axi_req    ),
    .qspi_s_axi_resp_i   ( qspi_s_axi_resp   ),
    .qspi_s_axi_req_o    ( qspi_s_axi_req    ),
    .gpio_s_axi_resp_i   ( gpio_s_axi_resp   ),
    .gpio_s_axi_req_o    ( gpio_s_axi_req    ),
    .timer_s_axi_resp_i  ( timer_s_axi_resp  ),
    .timer_s_axi_req_o   ( timer_s_axi_req   ),
    .memory_s_axi_resp_i ( memory_s_axi_resp ),
    .memory_s_axi_req_o  ( memory_s_axi_req  )
  );

  /****************
   * Debug System *
   ****************/

  axi_debug_system_fpga i_debug_system (
    .clk_i              ( top_clk         ),
    .rstn_i             ( locked          ),
    .debug_axi_s_req_i  ( dbg_s_axi_req   ),
    .debug_axi_s_resp_o ( dbg_s_axi_resp  ),
    .debug_axi_m_resp_i ( dbg_m_axi_resp  ),
    .debug_axi_m_req_o  ( dbg_m_axi_req   ),
    .debug_req_irq_o    ( debug_req_irq_s ),
    .jtag_tck_i         ( jtag_tck_i      ),
    .jtag_tms_i         ( jtag_tms_i      ),
    .jtag_trstn_i       ( jtag_trstn_s    ),
    .jtag_tdi_i         ( jtag_tdi_i      ),
    .jtag_tdo_o         ( jtag_tdo_o      )
  );

  /**********************
   * Peripherals System *
   **********************/

  axi_peripheral_system_fpga i_peripheral_system (
    .clk_i                     ( top_clk          ),
    .rstn_i                    ( locked           ),
    .system_uart_s_axi_req_i   ( uart_s_axi_req   ),
    .system_uart_s_axi_resp_o  ( uart_s_axi_resp  ),
    .system_qspi_s_axi_req_i   ( qspi_s_axi_req   ),
    .system_qspi_s_axi_resp_o  ( qspi_s_axi_resp  ),
    .system_gpio_s_axi_req_i   ( gpio_s_axi_req   ),
    .system_gpio_s_axi_resp_o  ( gpio_s_axi_resp  ),
    .system_timer_s_axi_req_i  ( timer_s_axi_req  ),
    .system_timer_s_axi_resp_o ( timer_s_axi_resp ),
    .uart_rx_i                 ( uart_rx_i        ),
    .uart_tx_o                 ( uart_tx_o        )
  );

   /****************
   * Memory System *
   *****************/

  axi_memory_system_fpga i_memory_system (
    .clk_i             ( top_clk           ),
    .rst_ni            ( locked            ),
    .memory_axi_req_i  ( memory_s_axi_req  ),
    .memory_axi_resp_o ( memory_s_axi_resp )
  );

endmodule

