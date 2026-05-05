#include "VysyxSoCFull.h"
#include "VysyxSoCFull__Dpi.h"
#include "../include/macro.h"
#include "../include/npc_utils.h" // IWYU pragma: keep
#include "verilated.h"
#include <cstdint>
#include <cstdio>
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
static VysyxSoCFull *top = nullptr;
#if VM_TRACE_FST
static VerilatedFstC *tfp = nullptr;
#elif VM_TRACE_VCD
static VerilatedVcdC *tfp = nullptr;
#endif

static svScope gpr_scope = nullptr;
static svScope csr_scope = nullptr;
static svScope pc_scope = nullptr;
static svScope wbu_scope = nullptr;

const static int RESET_TIME = 20;

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
  Verilated::commandArgs(argc, argv);
  const char *NPC_HOME = getenv("NPC_HOME");
  if (NPC_HOME == nullptr) { panic("Can't find NPC_HOME environment variable"); }
  std::string wave_path = std::string(NPC_HOME) + "/build/simx";
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VysyxSoCFull{contextp};

  // Set DPI-C scope name
  gpr_scope = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu.u_npc_core_wrapper.u_core.u_idu.u_regfile.u_dpi_probe_gpr");
  csr_scope = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu.u_npc_core_wrapper.u_core.u_csr.u_dpi_probe_csr");
  pc_scope  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu.u_npc_core_wrapper.u_core.u_ifu.u_dpi_probe_pc");
  wbu_scope = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu.u_npc_core_wrapper.u_core.u_wbu.u_dpi_probe_wbu");
 
  Assert(gpr_scope != nullptr, "failed to find gpr scope");
  Assert(csr_scope != nullptr, "failed to find csr scope");
  Assert(pc_scope  != nullptr, "failed to find pc scope");
  Assert(wbu_scope != nullptr, "failed to find wbu scope");

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
  top->clock = 0;
  top->reset = 1;
  top->eval();
  record_wave();

  while (contextp->time() < RESET_TIME) {
    contextp->timeInc(1);
    top->clock = !top->clock;
    top->eval();
    record_wave();
  }

  top->clock = 1;
  top->reset = 0;
  top->eval();
  contextp->timeInc(1);
  record_wave();
}

__EXPORT void npc_exec_once(uint32_t *inst, uint32_t *snpc, uint32_t *dnpc) {
  svSetScope(wbu_scope);
  static int timeout_cycle = 0;
  do {
  #ifdef CONFIG_TIMEOUT_EXIT
    if (timeout_cycle++ > CONFIG_TIMEOUT_EXIT_MAX_CYCLE) {
      void npc_delete();
      npc_delete();
      panic("NPC execution timeout at PC = 0x%08x", *snpc - 4);
    }
  #endif
    // negedge clk
    top->clock = 0;
    top->eval();
    contextp->timeInc(1);
    record_wave();  // record clk = 0

    svSetScope(pc_scope);
    dpi_get_pc((int *)snpc, (int *)dnpc);

    // posedge clk
    top->clock = 1;
    top->eval();    // 更新架构状态
    contextp->timeInc(1);
    record_wave();  // record clk = 1
    svSetScope(wbu_scope);
  } while (!dpi_get_commit());

  svSetScope(wbu_scope);
  *inst = dpi_get_inst();
  timeout_cycle = 0;
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

void vl_fatal(const char *filename, int linenum, const char *hier, const char *msg) {
  fprintf(stderr, "Fatal error at %s:%d: %s: %s\n", filename, linenum, hier, msg);
  npc_delete();
  panic("Verilator fatal error at %s:%d", __FILE__, __LINE__);
}
