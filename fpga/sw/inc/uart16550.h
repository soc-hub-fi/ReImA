//******************************************************************************
// File      : uart16550.h
// Author(s) : Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
// Date      : 05-mar-2024
// Description: Header file for Xilinx AXI UART 16650 operations
// Reg map for UART IP. Note: bit 8 of LCR controls the access to some of
// the registers.
// ┌──────┬────────┬───┬──────┬────────────────────────────────────────────────┐ 
// │LCR(7)│ OFFSET │REG│ACCESS│DESC                                            │ 
// ├──────┼────────┼───┼──────┼────────────────────────────────────────────────┤ 
// │  0   │ 0x1000 │RBR│  RO  │ Receiver Buffer Register                       │ 
// │  0   │ 0x1000 │THR│  WO  │ Transmitter Holding Register                   │ 
// │  0   │ 0x1004 │IER│  R/W │ Interrupt Enable Register                      │ 
// │  x   │ 0x1008 │IIR│  RO  │ Interrupt Identification Register              │ 
// │  x   │ 0x1008 │FCR│  WO  │ FIFO Control Register                          │ 
// │  1   │ 0x1008 │FCR│  RO  │ FIFO Control Register                          │ 
// │  x   │ 0x100C │LCR│  R/W │ Line Control Register                          │ 
// │  x   │ 0x1010 │MCR│  R/W │ Modem Control Register                         │ 
// │  x   │ 0x1014 │LSR│  R/W │ Line Status Register                           │ 
// │  x   │ 0x1018 │MSR│  R/W │ Modem Status Register                          │ 
// │  x   │ 0x101C │SCR│  R/W │ Scratch Register                               │ 
// │  1   │ 0x1000 │DLL│  R/W │ Divisor Latch (Least Significant Byte) Register│ 
// │  1   │ 0x1004 │DLM│  R/W │ Divisor Latch (Most Significant Byte) Register │ 
// └──────┴────────┴───┴──────┴────────────────────────────────────────────────┘ 
//******************************************************************************
#ifndef __UART16550__H__
#define __UART16550__H__

#include <stdint.h>

#include "marian.h"                                                       

#define RBR_ADDR_OFFSET 0x1000U
#define THR_ADDR_OFFSET 0x1000U
#define IER_ADDR_OFFSET 0x1004U
#define IIR_ADDR_OFFSET 0x1008U
#define FCR_ADDR_OFFSET 0x1008U
#define LCR_ADDR_OFFSET 0x100CU
#define MCR_ADDR_OFFSET 0x1010U
#define LSR_ADDR_OFFSET 0x1014U
#define MSR_ADDR_OFFSET 0x1018U
#define SCR_ADDR_OFFSET 0x101CU
#define DLL_ADDR_OFFSET 0x1000U
#define DLM_ADDR_OFFSET 0x1004U

#define RBR_ADDR (UART_BASE_ADDR + RBR_ADDR_OFFSET)
#define THR_ADDR (UART_BASE_ADDR + THR_ADDR_OFFSET)
#define IER_ADDR (UART_BASE_ADDR + IER_ADDR_OFFSET)
#define IIR_ADDR (UART_BASE_ADDR + IIR_ADDR_OFFSET)
#define FCR_ADDR (UART_BASE_ADDR + FCR_ADDR_OFFSET)
#define LCR_ADDR (UART_BASE_ADDR + LCR_ADDR_OFFSET)
#define MCR_ADDR (UART_BASE_ADDR + MCR_ADDR_OFFSET)
#define LSR_ADDR (UART_BASE_ADDR + LSR_ADDR_OFFSET)
#define MSR_ADDR (UART_BASE_ADDR + MSR_ADDR_OFFSET)
#define SCR_ADDR (UART_BASE_ADDR + SCR_ADDR_OFFSET)
#define DLL_ADDR (UART_BASE_ADDR + DLL_ADDR_OFFSET)
#define DLM_ADDR (UART_BASE_ADDR + DLM_ADDR_OFFSET)

#define RBR *((volatile uint32_t*)(RBR_ADDR))
#define THR *((volatile uint32_t*)(THR_ADDR))
#define IER *((volatile uint32_t*)(IER_ADDR))
#define IIR *((volatile uint32_t*)(IIR_ADDR))
#define FCR *((volatile uint32_t*)(FCR_ADDR))
#define LCR *((volatile uint32_t*)(LCR_ADDR))
#define MCR *((volatile uint32_t*)(MCR_ADDR))
#define LSR *((volatile uint32_t*)(LSR_ADDR))
#define MSR *((volatile uint32_t*)(MSR_ADDR))
#define SCR *((volatile uint32_t*)(SCR_ADDR))
#define DLL *((volatile uint32_t*)(DLL_ADDR))
#define DLM *((volatile uint32_t*)(DLM_ADDR))



#endif // __UART16550__H__