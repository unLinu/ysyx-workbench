#include "Vnpc_core.h"
#include "Vnpc_core___024root.h"
#include "Vnpc_core_ifu.h"
#include "Vnpc_core_npc_core.h"
#include "Vnpc_core_regfile.h"
#include "Vnpc_core_csr.h"
#include "../include/macro.h"
#include <assert.h>
#include <cstdint>
#include <stdint.h>
#ifdef FST
#include "verilated_fst_c.h"
#else
#include "verilated_vcd_c.h"
#endif

typedef struct {
    VerilatedContext *contextp;
    Vnpc_core *top;
    MUXDEF(FST, VerilatedFstC*, VerilatedVcdC*) tfp;
} NPCHandle;

typedef struct {
  uint32_t gpr[32];
  uint32_t pc;
  // csr 
  uint32_t mcause, mstatus, mepc, mtvec;
} diff_context_t;

static NPCHandle *npc_h = nullptr;
const static int RESET_TIME = 10;

static inline void npc_regcpy(diff_context_t *dut, Vnpc_core_npc_core *const npc_core) {
  for (int i = 0; i < 32; i++) {
    dut->gpr[i] = npc_core->u_regfile->gpr[i];
  }
  // csr
  dut->mcause = npc_core->u_csr->mcause;
  dut->mstatus = npc_core->u_csr->mstatus;
  dut->mepc = npc_core->u_csr->mepc;
  dut->mtvec = npc_core->u_csr->mtvec;
}

extern "C" {

__EXPORT void npc_init(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vnpc_core *top = new Vnpc_core{contextp};
  Verilated::traceEverOn(true);
#ifdef FST
  VerilatedFstC *tfp = new VerilatedFstC;
  top->trace(tfp, 99);
  tfp->open("build/obj_dir/simx.fst");
#else
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("build/obj_dir/simx.vcd");
#endif

  npc_h = new NPCHandle{contextp, top, tfp};
}

__EXPORT void npc_reset() {
  npc_h->top->rst_n = 0;
  npc_h->top->clk = 0;
  npc_h->top->inst_i = 0;

  npc_h->top->eval();
  npc_h->tfp->dump(npc_h->contextp->time());

  while (npc_h->contextp->time() < RESET_TIME) {
    npc_h->contextp->timeInc(1);
    npc_h->top->clk = !npc_h->top->clk;

    npc_h->top->eval();
    npc_h->tfp->dump(npc_h->contextp->time());  // record clk = 0
  }

  npc_h->top->clk = 1;
  npc_h->top->eval();
  npc_h->top->rst_n = 1; 
}

__EXPORT void npc_exec_once(uint32_t inst, uint32_t *snpc, uint32_t *dnpc) {
  // execution
  npc_h->top->sys_en = 1;
  npc_h->top->inst_i = inst;
  npc_h->top->eval();
  Assert(npc_h->top->inst_err == 0, "Instruction is invalid at PC = 0x%08x", npc_h->top->pc_o);

  npc_h->contextp->timeInc(1);
  npc_h->tfp->dump(npc_h->contextp->time());  // record clk = 1

  *snpc = npc_h->top->npc_core->u_ifu->snpc;
  *dnpc = npc_h->top->npc_core->u_ifu->dnpc;

  // negedege clk
  npc_h->top->clk = 0;
  npc_h->top->eval();
  npc_h->contextp->timeInc(1);
  npc_h->tfp->dump(npc_h->contextp->time());  // record clk = 0

  // posedge clk
  npc_h->top->clk = 1;
  npc_h->top->sys_en = 0;
  npc_h->top->eval();   // 更新 pc，寄存器堆等状态
}

__EXPORT void npc_delete() {
  if (npc_h) {
    npc_h->tfp->close();
    delete npc_h->tfp;
    delete npc_h->top;
    delete npc_h->contextp;
    delete npc_h;
    npc_h = nullptr;
  }
}

__EXPORT void npc_update_reg(diff_context_t *regs) {
  const auto npc_core = npc_h->top->npc_core;
  npc_regcpy(regs, npc_core);
}

} // extern "C"
