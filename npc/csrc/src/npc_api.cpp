#include "Vnpc_core.h"
#include "Vnpc_core___024root.h"
#include "Vnpc_core_ifu.h"
#include "Vnpc_core_npc_core.h"
#include "Vnpc_core_regfile.h"
#include "Vnpc_core_csr.h"
#include "../include/macro.h"
#include "../include/npc_utils.h" // IWYU pragma: keep
#include "verilated.h"
#include <assert.h>
#include <cstdint>
#include <stdint.h>
#include <string>
#include <stdlib.h>

#if VM_TRACE_FST
#include "verilated_fst_c.h"
#elif VM_TRACE_VCD
#include "verilated_vcd_c.h"
#endif

typedef struct {
  uint32_t gpr[32];
  uint32_t pc;
  // csr 
  uint32_t mcause, mstatus, mepc, mtvec;
} diff_context_t;

static VerilatedContext *contextp = nullptr;
static Vnpc_core *top = nullptr;
#if VM_TRACE_FST
static VerilatedFstC *tfp = nullptr;
#elif VM_TRACE_VCD
static VerilatedVcdC *tfp = nullptr;
#endif

const static int RESET_TIME = 10;

static void npc_regcpy(diff_context_t *dut, Vnpc_core_npc_core *const npc_core) {
  for (int i = 0; i < 32; i++) {
    dut->gpr[i] = npc_core->u_regfile->gpr[i];
  }
  // csr
  dut->mcause = npc_core->u_csr->mcause;
  dut->mstatus = npc_core->u_csr->mstatus;
  dut->mepc = npc_core->u_csr->mepc;
  dut->mtvec = npc_core->u_csr->mtvec;
}

static inline void record_wave() {
#if VM_TRACE
  tfp->dump(contextp->time());
#endif
}

extern "C" {

__EXPORT void npc_init(int argc, char **argv) {
  const char *NPC_HOME = getenv("NPC_HOME");
  if (NPC_HOME == nullptr) { panic("Can't find NPC_HOME environment variable"); }
  std::string wave_path = std::string(NPC_HOME) + "/build/simx";
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vnpc_core{contextp};
#if VM_TRACE_FST
  Verilated::traceEverOn(true);
  tfp = new VerilatedFstC;
  top->trace(tfp, 99);
  tfp->open((wave_path + ".fst").c_str());
#elif VM_TRACE_VCD
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open((wave_path + ".vcd").c_str());
#endif
}

__EXPORT void npc_reset() {
  top->rst_n = 0;
  top->clk = 0;
  top->inst_i = 0;

  top->eval();
  record_wave();

  while (contextp->time() < RESET_TIME) {
    contextp->timeInc(1);
    top->clk = !top->clk;
    top->eval();
    record_wave();
  }

  top->clk = 1;
  top->eval();
  top->rst_n = 1; 
}

__EXPORT void npc_exec_once(uint32_t inst, uint32_t *snpc, uint32_t *dnpc) {
  // execution
  top->inst_i = inst;
  top->eval();
  Assert(top->inst_err == 0, "Instruction is invalid at PC = 0x%08x", top->pc_o);

  contextp->timeInc(1);
  record_wave();  // record clk = 1

  *snpc = top->npc_core->u_ifu->snpc;
  *dnpc = top->npc_core->u_ifu->dnpc;

  // negedege clk
  top->clk = 0;
  top->eval();
  contextp->timeInc(1);
  record_wave();  // record clk = 0

  // posedge clk
  top->clk = 1;
  top->eval();   // 更新 pc，寄存器堆等状态
}

__EXPORT void npc_delete() {
#if VM_TRACE
  if (tfp) {
    tfp->close();
    delete tfp;
    tfp = nullptr;
    printf(ANSI_FMT("Waveform file generated.", ANSI_FG_GREEN) "\n");
  }
#endif
  if (top) {
    delete top;
    top = nullptr;
  }
  if (contextp) {
    delete contextp;
    contextp = nullptr;
  }
}

__EXPORT void npc_update_reg(diff_context_t *regs) {
  const auto npc_core = top->npc_core;
  npc_regcpy(regs, npc_core);
}

} // extern "C"
