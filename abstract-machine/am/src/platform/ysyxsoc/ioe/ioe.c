#include <am.h>
#include <klib-macros.h>

void __am_uart_init();
void __am_uart_tx(AM_UART_TX_T *uart);
void __am_uart_rx(AM_UART_RX_T *uart);

static void __am_uart_config(AM_UART_CONFIG_T *cfg) { cfg->present = true;  }

typedef void (*handler_t)(void *buf);
static void *lut[128] = {
  [AM_UART_CONFIG]  = __am_uart_config,
  [AM_UART_TX     ] = __am_uart_tx,
  // [AM_UART_RX     ] = __am_uart_rx
};

static void fail(void *buf) { panic("access nonexist register"); }

bool ioe_init() {
  for (int i = 0; i < LENGTH(lut); i++)
    if (!lut[i]) lut[i] = fail;
  __am_uart_init();
  return true;
}

void ioe_read (int reg, void *buf) { ((handler_t)lut[reg])(buf); }
void ioe_write(int reg, void *buf) { ((handler_t)lut[reg])(buf); }
