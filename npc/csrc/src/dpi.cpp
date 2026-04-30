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

void difftest_set_skip() {
  is_skip_ref = 1;
}

void flash_read(int32_t addr, int32_t *data) { assert(0); }
void mrom_read(int32_t addr, int32_t *data) {
  uint32_t map_addr = (uint32_t)addr & ~0x3u;
  *data = vaddr_read(map_addr, 4);
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
