#include <am.h>
#include <ysyxsoc.h>

#define EOF -1

void __am_uart_tx(AM_UART_TX_T *uart) {
  putch(uart->data);
}

void __am_uart_rx(AM_UART_RX_T *uart) {
  int ret = getch();
  if (ret == EOF) ret = -1;
  uart->data = ret;
}
