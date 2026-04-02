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

`endif // __NPC_DEFINES_SVH__
