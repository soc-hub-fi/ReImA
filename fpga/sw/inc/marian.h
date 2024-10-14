//******************************************************************************
// File      : marian.h
// Author(s) : Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
// Date      : 05-mar-2024
// Description: Header file for all subsytem level definitions.
//******************************************************************************
#ifndef __MARIAN__H__
#define __MARIAN__H__

  // base addresses of each component in subsystem (corresponds to xbar)
  #define DBGM_BASE_ADDR 0x00001000UL
  #define QSPI_BASE_ADDR 0x00003000UL
  #define GPIO_BASE_ADDR 0x00004000UL
  #define TIMR_BASE_ADDR 0x00005000UL
  #define DRAM_BASE_ADDR 0x80000000UL
  #define UART_BASE_ADDR 0xC0000000UL

#endif // __MARIAN__H__