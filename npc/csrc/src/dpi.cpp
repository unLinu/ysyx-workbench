#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include "../include/macro.h"
#include "../include/npc_utils.h" // IWYU pragma: keep
#include <../../../nemu/include/generated/autoconf.h>

static int trap_flag = 0;
static uint32_t (*vaddr_read)(uint32_t addr, int len) = NULL;
static void (*vaddr_write)(uint32_t addr, int len, uint32_t data) = NULL;

#ifdef __cplusplus
extern "C" {
#endif

/* DPI-C */
void npc_trap() {
  trap_flag = 1;
}

int npc_pmem_read(int raddr) {
  uint32_t ret = vaddr_read((uint32_t)raddr, 4);
  return ret;
}

void npc_pmem_write(int waddr, int wdata, char wlen) {
  vaddr_write((uint32_t)waddr, (int)wlen, (uint32_t)wdata);
}

/* Interface */
 __EXPORT int npc_get_trap_flag() {
  return trap_flag;
}

__EXPORT void npc_init_mem(uint32_t (*vrd)(uint32_t addr, int len), void (*vwr)(uint32_t addr, int len, uint32_t data)) {
  vaddr_read = vrd;
  vaddr_write = vwr;
}

#ifdef __cplusplus
}
#endif
