/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"
#include "common.h"

static inline void difftest_fail_msg(vaddr_t pc) {
  printf(ANSI_FMT("Difftest failed at pc = " FMT_WORD "\n", ANSI_FG_RED), pc);
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for (int i = 0; i < ARRLEN(ref_r->gpr); i++) {
    if (ref_r->gpr[i] != gpr(i)) {
      printf(ANSI_FMT("GPR[%d] wrong. Expect " FMT_WORD ", actual " FMT_WORD "\n", ANSI_FG_RED), i, ref_r->gpr[i], gpr(i));
      difftest_fail_msg(pc);
      return false;
    }
  }

#define CHECK_REG(name) \
  do { \
    if (ref_r->name != cpu.name) { \
      printf(ANSI_FMT(#name " wrong. Expect " FMT_WORD ", actual " FMT_WORD "\n", ANSI_FG_RED), ref_r->name, cpu.name); \
      difftest_fail_msg(pc); \
      return false; \
    } \
  } while (0)

  CHECK_REG(pc);
  CHECK_REG(mstatus);
  CHECK_REG(mcause);
  CHECK_REG(mepc);
  CHECK_REG(mtvec);

#undef CHECK_REG

  return true;
}

void isa_difftest_attach() {
}
