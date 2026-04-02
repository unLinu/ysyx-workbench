`include "npc_defines.svh"
module npc_idu_imm_gen import ctrl_pkg::*; (
  input   ctrl_pkg::imm_type_e        imm_type_i  ,
  input   isa_pkg::word_t             inst_i      ,
  output  isa_pkg::word_t             imm_o
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */


/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // optimized
  wire  unused_signal = &{1'b0, inst_i[6:0]};

  always_comb begin
    imm_o = `XLEN'd0;
    unique case (imm_type_i)
      IMM_TYPE_I: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
      IMM_TYPE_S: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
      IMM_TYPE_B: imm_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
      IMM_TYPE_U: imm_o = {inst_i[31:12], 12'b0};
      IMM_TYPE_J: imm_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
      default:    imm_type_i_error: assert(0) else $fatal(1,"Wrong imm_type_i!");
    endcase
  end

endmodule
