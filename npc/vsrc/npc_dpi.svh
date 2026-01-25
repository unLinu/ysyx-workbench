`ifndef __NPC_DPI_SVH__
`define __NPC_DPI_SVH__ 

import "DPI-C" function void npc_trap();
import "DPI-C" function int npc_pmem_read(input int raddr);
import "DPI-C" function void npc_pmem_write(input int waddr, input int wdata, input byte wmlen);
import "DPI-C" function void npc_pmem_readlog(input int raddr, input int pc, input int data, input byte len);

`endif // __NPC_DPI_SVH__
