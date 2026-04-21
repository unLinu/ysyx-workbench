`ifndef __NPC_DEFINES_SVH__

`define __NPC_DEFINES_SVH__ 
`define XLEN 32
`define RLEN 5 
`define GPR_NUM 32 

// IDU
`define ASSERT_INST(cond, inst) \
  if (cond) begin \
    assert(0) else $fatal(1, "Invalid inst: %x", inst); \
  end

// AXI4-Lite ERROR
`define AXI_OKAY 2'b00
`define AXI_SLVERR 2'b10
`define AXI_DECERR 2'b11

`endif // __NPC_DEFINES_SVH__
