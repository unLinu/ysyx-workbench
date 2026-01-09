`include "npc_defines.svh"
module imm_gen import npc_pkg::*; (
    input   npc_pkg::imm_op_t           imm_op_i    ,
    input   npc_pkg::word_t             inst_i      ,
    output  npc_pkg::word_t             imm_o    
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */


/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    always_comb begin
        unique case (imm_op_i)
            IMM_I_TYPE: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            IMM_S_TYPE: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            IMM_B_TYPE: imm_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            IMM_U_TYPE: imm_o = {inst_i[31:12], 12'b0};
            IMM_J_TYPE: imm_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            default: imm_o = {`XLEN{1'b1}};
        endcase
    end
    
endmodule  
