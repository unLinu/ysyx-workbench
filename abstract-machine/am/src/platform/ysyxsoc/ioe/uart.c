#include <am.h>
#include <ysyxsoc.h>

#define EOF -1
#define DIVISOR 1

#define UART_RBR UART_ADDR + 0  // Receiver Buffer
#define UART_THR UART_ADDR + 0  // Transmitter Holding Register
#define UART_IER UART_ADDR + 1  // Interrupt Enable Register
#define UART_IIR UART_ADDR + 2  // Interrupt Identification Register #define UART_FCR UART_ADDR + 2  // FIFO Control Register
#define UART_LCR UART_ADDR + 3  // Line Control Register
#define UART_MCR UART_ADDR + 4  // Modem Control Register
#define UART_LSR UART_ADDR + 5  // Line Status Register
#define UART_MSR UART_ADDR + 6  // Modem Status Register
// NOTE: The registers can be acessed when the 7th (DLAB) bit of the Line Control Register is set to "1"
#define UART_DLL UART_ADDR + 0  // Divisor Latch Low
#define UART_DLH UART_ADDR + 1  // Divisor Latch High

void __am_uart_init() {
  outb(UART_LCR, 0x83);
  outb(UART_DLH, DIVISOR >> 8);
  outb(UART_DLL, DIVISOR & 0xff);
  outb(UART_LCR, 0x03);
}

void __am_uart_tx(AM_UART_TX_T *uart) {
  putch(uart->data);
}

// void __am_uart_rx(AM_UART_RX_T *uart) {
//   int ret = getch();
//   if (ret == EOF) ret = -1;
//   uart->data = ret;
// }
