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
        int in = rand() % 256;
        top->in = in;
        top->eval();
        tfp->dump(contextp->time());
        printf("in = %d, valid = %d, led = %d, seg = %d\n", in, top->valid, top->led, top->seg);
        /* user simulation end */
    }
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}
