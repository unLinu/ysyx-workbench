#include <nvboard.h>
#include <Vtop.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME *top);

static void single_cycle()
{
#ifdef SEQ_LOGIC
  dut.clk = 0;
  dut.eval();
  dut.clk = 1;
#endif
  dut.eval();
}

static void reset(int n)
{
#ifdef SEQ_LOGIC
  dut.rst = 1;
  while (n-- > 0)
    single_cycle();
  dut.rst = 0;
#endif
}

int main()
{
  nvboard_bind_all_pins(&dut);
  nvboard_init();

  reset(10);

  while (1)
  {
    nvboard_update();
    single_cycle();
  }
}
