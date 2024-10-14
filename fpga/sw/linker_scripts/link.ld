/* 
   Author :  Tom Szymkowiak <thomas.szymkowiak@tuni.fi>

   This file is used to to compile software for the Marian FPGA prototype.
   It is a modified version of the linker script used within v3.0 of Pulp Ara:
   https://github.com/pulp-platform/ara

   It is restricted for use with the following HW configuration only:
   VLEN = 512,
   NrLanes = 4,
   DRAM size = 2MiB
*/

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  L2 : ORIGIN = 0x80000000, LENGTH = 0x00020000
}

/*
  Ara's TB works only if the sections are aligned to a AxiWideBeWidth boundary
*/
SECTIONS {
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > L2

  .data : ALIGN(16) {
    *(.data)
    *(.data.*)
  } > L2

  .rodata  : ALIGN(16) { *(.rodata .rodata.* .gnu.linkonce.r.*) } > L2
  .rodata1 : ALIGN(16) { *(.rodata1) } > L2
  .sdata2  : ALIGN(16) {
    *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
  } > L2

  .sdata   : ALIGN(16) {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  } > L2

  .bss : ALIGN(16) {
    __bss_start = .;
    *(.bss)
    *(.sbss .sbss.* .sbss2 .sbss2.* .gnu.linkonce.sb2.*);
    __bss_end = .;
  } > L2

  .l2 : ALIGN(16) {
    *(.l2)
    l2_alloc_base = ALIGN(16);
  } > L2

  .comment : ALIGN(16) { *(.comment) } > L2
}
