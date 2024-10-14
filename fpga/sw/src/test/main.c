#include <stdint.h>

#include "uart16550.h"

void test_uart(uint32_t baud) {
  // Write 0x0000_0080 to the Line Control Register. This configures the DLAB bit, which
  // allows writing into the Divisor Latch least significant and most significant bytes.
  LCR = 0x80U;

  // divisor = (AXI CLK frequency/(16 × Baud Rate))
  uint64_t divisor = 50000000 / (16 * baud);
  uint32_t div_lo = (uint32_t)(divisor & 0xFFFFFFFFUL);
  uint32_t div_hi = (uint32_t)(divisor >> 32);
  DLL = div_lo;
  DLM = div_hi;

  // Write 0x0000_003 to Line Control register. This configures word length to 8 bits,
  // number of stop bits to 1, parity is disabled and the DLAB bit is set
  // to 0 to enable the use of the Transmitter Holding register and Receiver Buffer register
  // data for transmission and reception.
  LCR = 0x3;

  const char* msg = "Hello from Marian!\r\n";

  uint8_t* c = (uint8_t*)(msg);
  while (*c != '\0') {
    THR = *c;
    c++;
    // wait for THR to report empty (bit 6)
    while((~(LSR) & 0x40));
  }

}

int main(void) {

  test_uart(115200);

  return 0;
}