#include "Vnpc_top.h"
#include "Vnpc_top__Dpi.h"
#include "../include/macro.h"
#include "verilated.h"
#include <svdpi.h>
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

typedef enum {
  MSTATUS = 0x300, MEPC = 0x341, MCAUSE = 0x342, MTVEC = 0x305
} csr_addr_t;

static VerilatedContext *contextp = nullptr;
static Vnpc_top *top = nullptr;
#if VM_TRACE_FST
static VerilatedFstC *tfp = nullptr;
#elif VM_TRACE_VCD
static VerilatedVcdC *tfp = nullptr;
#endif

static svScope gpr_scope = nullptr;
static svScope csr_scope = nullptr;
static svScope pc_scope = nullptr;

const static int RESET_TIME = 10;

static void npc_regcpy(diff_context_t *dut) {
  svSetScope(gpr_scope);
  dpi_get_gpr((int *)dut->gpr);
  // csr
  svSetScope(csr_scope);
  dut->mcause = dpi_get_csr(MCAUSE);
  dut->mstatus = dpi_get_csr(MSTATUS);
  dut->mepc = dpi_get_csr(MEPC);
  dut->mtvec = dpi_get_csr(MTVEC);
}

static inline void record_wave() {
#if VM_TRACE
  tfp->dump(contextp->time());
#endif
}

extern "C" {

__EXPORT void npc_init(int argc, char **argv) {
  // Initialize top module and trace
  const char *NPC_HOME = getenv("NPC_HOME");
  if (NPC_HOME == nullptr) { panic("Can't find NPC_HOME environment variable"); }
  std::string wave_path = std::string(NPC_HOME) + "/build/simx";
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vnpc_top{contextp};

  // Set DPI-C scope
  gpr_scope = svGetScopeFromName("TOP.npc_top.u_core.u_idu.u_regfile.u_dpi_probe_gpr");
  csr_scope = svGetScopeFromName("TOP.npc_top.u_core.u_csr.u_dpi_probe_csr");
  pc_scope  = svGetScopeFromName("TOP.npc_top.u_core.u_ifu.u_dpi_probe_pc");
 
  assert(gpr_scope != nullptr && "failed to find gpr scope");
  assert(csr_scope != nullptr && "failed to find csr scope");
  assert(pc_scope  != nullptr && "failed to find pc scope");

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

  contextp->timeInc(1);
  record_wave();  // record clk = 1

  svSetScope(pc_scope);
  dpi_get_pc((int *)snpc, (int *)dnpc);

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
  npc_regcpy(regs);
}

} // extern "C"
