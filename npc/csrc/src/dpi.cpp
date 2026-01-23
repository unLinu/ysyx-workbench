#include <assert.h>
#include <stdlib.h>
#include "../include/macro.h"

static int trap_flag = 0;

#ifdef __cplusplus
extern "C" {
#endif

/* DPI-C */
void npc_trap() {
  trap_flag = 1;
}

/* Interface */
 __EXPORT int npc_get_trap_flag() {
  return trap_flag;
}

#ifdef __cplusplus
}
#endif