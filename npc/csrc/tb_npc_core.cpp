#include "Vnpc_core.h"
#include "verilated.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef FST
#include "verilated_fst_c.h"
#else
#include "verilated_vcd_c.h"
#endif

#include "debug.hpp"

const int RESET_TIME = 10;
const int MAX_TIME = 1000;

int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vnpc_core *top = new Vnpc_core{contextp};
    // wave
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
    /* user simulation start */
    top->clk = 0;
    top->rst_n = 0;
    top->inst_i = 0;
    top->eval();
    tfp->dump(contextp->time());
    while (contextp->time() < MAX_TIME && !contextp->gotFinish()) {
        contextp->timeInc(1);

        top->clk = !top->clk;

        if (contextp->time() < RESET_TIME) {
            top->rst_n = 0;
        } else {
            top->rst_n = 1;
        }

        top->eval();
        NPC_TRAP();
        if (top->rst_n) {
            top->inst_i = pmem_read(top->pc_o);
            top->eval();
            NPC_TRAP();
            assert(top->inst_err == 0);
        }

        tfp->dump(contextp->time());

        /* user simulation end */
    }
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}
