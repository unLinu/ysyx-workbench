#include "Vnpc_core.h"
#include "Vnpc_core___024root.h"
#include "Vnpc_core_ifu.h"
#include "Vnpc_core_npc_core.h"
#include "Vnpc_core_regfile.h"
#include "../include/macro.h"
#include <assert.h>
#include <cstdint>
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

static NPCHandle *npc_h = nullptr;
const static int RESET_TIME = 10;

static inline void npc_regcpy(uint32_t *regs, const uint32_t *npc_gpr) {
  for (int i = 0; i < 32; i++) {
    regs[i] = npc_gpr[i];
  }
}

static inline void npc_pccpy(uint32_t *pc, const uint32_t *npc_pc) {
  *pc = *npc_pc;
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
    npc_h->tfp->dump(npc_h->contextp->time());
  }

  npc_h->top->clk = 0;
  npc_h->top->eval();
}

__EXPORT uint32_t npc_exec_once(uint32_t (*ifetch)(uint32_t addr, int len)) {
  // posedge clk
  npc_h->top->clk = 1;
  npc_h->top->eval();

  npc_h->top->rst_n = 1;
  npc_h->top->inst_i = ifetch(npc_h->top->pc_o, 4);
  npc_h->top->eval();
  Assert(npc_h->top->inst_err == 0, "Instruction is invalid at PC = 0x%08x", npc_h->top->pc_o);

  npc_h->contextp->timeInc(1);
  npc_h->tfp->dump(npc_h->contextp->time());

  // negedge clk
  npc_h->top->clk = 0;
  npc_h->top->eval();

  npc_h->contextp->timeInc(1);
  npc_h->tfp->dump(npc_h->contextp->time());

  return npc_h->top->inst_i;
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

__EXPORT void npc_update_reg(uint32_t *regs, uint32_t *snpc, uint32_t *dnpc) {
  const auto gpr = &npc_h->top->npc_core->u_regfile->gpr;
  const auto snpc_v = &npc_h->top->npc_core->u_ifu->pc[1];
  const auto dnpc_v = &npc_h->top->npc_core->u_ifu->br_target;
  npc_regcpy(regs, &(*gpr)[0]);
  npc_pccpy(snpc, snpc_v);
  npc_pccpy(dnpc, dnpc_v);
}

} // extern "C"