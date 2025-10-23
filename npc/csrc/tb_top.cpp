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
    int result = 0;
    while (contextp->time() < sim_time && !contextp->gotFinish())
    {
        contextp->timeInc(1);
        /* user simulation start */
        int sel = rand() % 8;
        int A = rand() % 16;
        int B = rand() % 16;
        top->A = A;
        top->B = B;
        top->sel = sel;
        switch (top->sel)
        {
        case 0: // ADD
            result = A + B;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 1: // SUB
            result = A - B;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 2: // NOT
            result = ~A;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, sel = %d, result = %d\n", top->A, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 3: // AND
            result = A & B;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 4: // OR
            result = A | B;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 5: // XOR
            result = A ^ B;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == (result & 0xF));
            break;
        case 6: // LT
            if (A >> 3 != B >> 3) // 符号位不同
                result = (A >> 3) > (B >> 3) ? 1 : 0;
            else
                result = (A & 0x7) < (B & 0x7) ? 1 : 0;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result);
            assert(top->result == result);
            break;
        case 7: // EQ
            result = (A == B) ? 1 : 0;
            top->eval();
            tfp->dump(contextp->time());
            printf("A = %d, B = %d, sel = %d, result = %d\n", top->A, top->B, top->sel, top->result );
            assert(top->result == result);
            break;
        default:
            break;
        }
        /* user simulation end */
    }
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}
