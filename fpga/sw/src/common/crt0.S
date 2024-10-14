/*
 * File      : crt0.S
 * Author(s) : Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
 * Date      : 05-mar-2024
 * Description: C runtime initialisation file for use within the Marian FPGA prototype.
 * It is a modified version of the crt0.S used within v3.0 of Pulp Ara:
 * https://github.com/pulp-platform/ara  
 */

.globl _start
.section .text;
.section .text.init;

#include "encoding.h"

// For the riscv-tests environment
.weak mtvec_handler
.weak stvec_handler

_start:
    // Initialize global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* reset vector */
    j reset_vector
reset_vector:
    li      x1, 0
    li      x4, 0
    li      x5, 0
    li      x6, 0
    li      x7, 0
    li      x8, 0
    li      x9, 0
    li      x10, 0
    li      x11, 0
    li      x12, 0
    li      x13, 0
    li      x14, 0
    li      x15, 0
    li      x16, 0
    li      x17, 0
    li      x18, 0
    li      x19, 0
    li      x20, 0
    li      x10, 0
    li      x21, 0
    li      x22, 0
    li      x23, 0
    li      x24, 0
    li      x25, 0
    li      x26, 0
    li      x27, 0
    li      x28, 0
    li      x29, 0
    li      x30, 0
    li      x31, 0
    // Initialize stack at the end of the DRAM region
    //la      t0, dram_end_address_reg
    ld      sp, l2_lim
    // Set up a PMP to permit all accesses
    li t0, (1 << (31 + (__riscv_xlen / 64) * (53 - 31))) - 1
    csrw pmpaddr0, t0
    li t0, PMP_NAPOT | PMP_R | PMP_W | PMP_X
    csrw pmpcfg0, t0
    // Delegate no traps
    csrwi   mie, 0
    la      t0, trap_vector
    csrw    mtvec, t0
    csrwi   medeleg, 0
    csrwi   mideleg, 0
    // If an stvec_handler is defined, delegate exceptions to it
    la t0, stvec_handler
    beqz t0, 1f
    csrw stvec, t0
    li t0, (1 << CAUSE_LOAD_PAGE_FAULT) |  \
           (1 << CAUSE_STORE_PAGE_FAULT) | \
           (1 << CAUSE_FETCH_PAGE_FAULT) | \
           (1 << CAUSE_MISALIGNED_FETCH) | \
           (1 << CAUSE_USER_ECALL) |       \
           (1 << CAUSE_BREAKPOINT)
    csrw medeleg, t0
    .align 2
1:  csrwi mstatus, 0
    // Enable FP Extension
    li      t0, (MSTATUS_FS & (MSTATUS_FS >> 1))
    csrs    mstatus, t0
    csrwi   fcsr, 0
    // Enable Vector Extension
    li      t0, (MSTATUS_VS & (MSTATUS_VS >> 1))
    csrs    mstatus, t0
    // Enable the counters
    csrsi   mcounteren, 1
    csrsi   scounteren, 1
    // Call main
    jal     ra, main
    // Return to _end
    j       _end

// Trap
    .align 2
trap_vector:
    // Jump to the mtvec_handler, if it exists
    la t5, mtvec_handler
    beqz t5, 1f
    jr t5
1:  csrr a0, mcause
    j _fail

// loop in end once returned from main
    .align 2
_end:
    j _end

// loop in fail
    .align 2
_fail:
    j _fail

.section .data

// last 64b address of 2MiB BRAM used for stack
l2_lim:
    .dword 0x8001FFF8

