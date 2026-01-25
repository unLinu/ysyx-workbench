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

void npc_pmem_readlog(int raddr, int pc, int data, char len) {
#ifdef CONFIG_MTRACE
  if (raddr >= CONFIG_MTRACE_START && raddr <= CONFIG_MTRACE_END) {
    printf(ANSI_FMT("[mtrace]", ANSI_FG_MAGENTA));
    printf(" PC: 0x%08x " ANSI_FMT("READ", ANSI_FG_GREEN), pc);
    printf("  Addr: 0x%08x Data: 0x%08x Len: %d\n", raddr, data, len);
  }
#endif
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
