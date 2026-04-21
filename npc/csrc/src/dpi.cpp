#include <assert.h>
#include <cstdint>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include "../include/macro.h"
#include "../include/npc_utils.h" // IWYU pragma: keep

static int trap_flag = 0;
static int is_skip_ref = 0;
static uint32_t (*vaddr_read)(uint32_t addr, int len) = NULL;
static void (*vaddr_write)(uint32_t addr, int len, uint32_t data) = NULL;

#ifdef __cplusplus
extern "C" {
#endif

/* DPI-C */
void halt() {
  trap_flag = 1;
}

int mem_read(int raddr) {
  uint32_t addr = (uint32_t)raddr;
  int len = 0;
  // NOTE: serial addr
  if (addr >= 0xa00003f8 && addr <= 0xa00003ff)
    len = 1;
  else
    len = 4;
  return vaddr_read(addr, len);
}

void mem_write(int waddr, int wdata, char wstrb) {
  int len = 0;
  uint32_t aligned_waddr = (uint32_t)waddr & ~0x3u;
  uint32_t real_waddr = aligned_waddr;

  switch ((uint8_t)wstrb & 0x0f) {
    case 0x1: len = 1; real_waddr = aligned_waddr + 0; break;
    case 0x2: len = 1; real_waddr = aligned_waddr + 1; break;
    case 0x4: len = 1; real_waddr = aligned_waddr + 2; break;
    case 0x8: len = 1; real_waddr = aligned_waddr + 3; break;
    case 0x3: len = 2; real_waddr = aligned_waddr + 0; break;
    case 0xc: len = 2; real_waddr = aligned_waddr + 2; break;
    case 0xf: len = 4; real_waddr = aligned_waddr + 0; break;
    default: assert(0);
  }

  vaddr_write(real_waddr, len, (uint32_t)wdata);
}

void difftest_set_skip() {
  is_skip_ref = 1;
}

/* Interface */
 __EXPORT int npc_get_trap_flag() {
  return trap_flag;
}

__EXPORT void npc_init_mem(uint32_t (*vrd)(uint32_t addr, int len), void (*vwr)(uint32_t addr, int len, uint32_t data)) {
  vaddr_read = vrd;
  vaddr_write = vwr;
}

__EXPORT int npc_get_difftest_skip_flag() {
  int ret = is_skip_ref;
  is_skip_ref = 0;
  return ret;
}

#ifdef __cplusplus
}
#endif
