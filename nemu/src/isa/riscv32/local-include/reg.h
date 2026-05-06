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

#ifndef __RISCV_REG_H__
#define __RISCV_REG_H__

#include <common.h>

static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32)));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

enum {
  MVENDORID = 0xf11, MARCHID = 0xf12, MSTATUS = 0x300, MEPC = 0x341, MCAUSE = 0x342, MTVEC = 0x305
};

#define csr(idx) (*({ \
  word_t *_csr_ptr = NULL; \
  switch (idx & 0xfff) { \
    case MSTATUS: _csr_ptr = &cpu.mstatus; break; \
    case MEPC:    _csr_ptr = &cpu.mepc;    break; \
    case MCAUSE:  _csr_ptr = &cpu.mcause;  break; \
    case MTVEC:   _csr_ptr = &cpu.mtvec;   break; \
    case MVENDORID: _csr_ptr = &cpu.mvendorid; break; \
    case MARCHID:   _csr_ptr = &cpu.marchid;   break; \
    default: panic("unimplemented csr idx = " FMT_WORD, idx); \
  } \
  _csr_ptr; \
}))

#endif
