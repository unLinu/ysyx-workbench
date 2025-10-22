#include "Vtop.h"
#include "verilated.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#ifdef FST
#include "verilated_fst_c.h"
#else
#include "verilated_vcd_c.h"
#endif

const int sim_time = 1000; // 或你想要的仿真步数

int main(int argc, char **argv)
{
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vtop *top = new Vtop{contextp};
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
    while (contextp->time() < sim_time && !contextp->gotFinish())
    {
        contextp->timeInc(1);
        /* user simulation start */
        int Y = rand() % 4;
        int X0 = rand() % 4;
        int X1 = rand() % 4;
        int X2 = rand() % 4;
        int X3 = rand() % 4;
        top->X0 = X0;
        top->X1 = X1;
        top->X2 = X2;
        top->X3 = X3;
        top->Y = Y;
        top->eval();
        tfp->dump(contextp->time());
        printf("X0 = %d, X1 = %d, X2 = %d, X3 = %d, Y = %d, F = %d\n", X0, X1, X2, X3, Y, top->F);
        assert(top->F == ((Y == 0) ? X0 : (Y == 1) ? X1 : (Y == 2) ? X2 : X3));
        /* user simulation end */
    }
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}
