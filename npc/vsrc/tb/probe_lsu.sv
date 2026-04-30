`include "npc_defines.svh"
module probe_lsu (
  input   logic                   clk         ,
  input   logic                   req_done    ,
  input   logic   [`XLEN-1:0]     req_addr
);

  import "DPI-C" function void difftest_set_skip();

  always_ff @(posedge clk) begin
    if (req_done && req_addr >= `UART_BASE && req_addr < `UART_BASE + `UART_SIZE)
      difftest_set_skip();
  end

endmodule
