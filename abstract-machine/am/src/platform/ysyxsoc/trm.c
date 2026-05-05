#include <am.h>
#include <stdint.h>
#include <ysyxsoc.h>
#include <klib.h>

extern char _heap_start;
extern char _heap_end;
extern char _data_load;
extern char _data_start;
extern char _data_end;
extern char _bss_start;
extern char _bss_end;

int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
  while((inb(UART_ADDR + 5) & 0x20) == 0)
    ;
  outb(UART_ADDR, ch);
}

void halt(int code) {
  ysyxsoc_trap(code);

  // should not reach here
  while (1);
}

void _trm_init(uint32_t mvendorid, uint32_t marchid) {
  ioe_init();
  putstr("Welcome to ");
  for (int i = 3; i >= 0; i--)
    putch((char)(mvendorid >> (8 * i)));
  for (uint32_t d = 10000000; d; d /= 10)
    putch('0' + (marchid / d) % 10);
  putstr(" CPU!\n");

  int ret = main(mainargs);
  halt(ret);
}

void _boot_loader() {
  memcpy(&_data_start, &_data_load, &_data_end - &_data_start);
  memset(&_bss_start, 0, &_bss_end - &_bss_start);
}
