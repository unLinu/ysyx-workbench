`include "npc_defines.svh"
module dpi_probe_gpr (
  input   isa_pkg::word_t     gpr_i [0:`GPR_NUM-1]
);

  export "DPI-C" function dpi_get_gpr         ;

  function automatic void dpi_get_gpr(output int gpr_o[`GPR_NUM]);
    for (int i = 0; i < `GPR_NUM; i++) begin
      gpr_o[i] = gpr_i[i];
    end
  endfunction

endmodule
