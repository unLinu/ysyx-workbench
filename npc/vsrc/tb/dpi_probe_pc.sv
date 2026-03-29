`include "npc_defines.svh"
module dpi_probe_pc (
  input   isa_pkg::word_t         pc_i      ,
  input   isa_pkg::word_t         dnpc_i
);

  export "DPI-C" function dpi_get_pc        ;

  function automatic void dpi_get_pc(output int snpc, output int dnpc);
    snpc  = pc_i + `XLEN'd4   ;
    dnpc  = dnpc_i            ;
  endfunction

endmodule
