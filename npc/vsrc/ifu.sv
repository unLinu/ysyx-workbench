`include "npc_defines.svh"
module ifu import npc_pkg::*; (
    input   logic                       clk         ,
    input   logic                       rst_n       ,

    // control
    input   npc_pkg::pc_update_t        pc_op_i     ,

    // data
    input   npc_pkg::word_t             imm_i       ,   // from imm_gen
    input   npc_pkg::word_t             alu_res_i   ,

    output  npc_pkg::word_t             pc_o        ,
    output  npc_pkg::word_t             snpc_o          // always curpc+4
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    npc_pkg::pc_reg_t   pc /* verilator public */;
    npc_pkg::word_t     br_target  /* verilator public */ ;
    npc_pkg::word_t     temp_target ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    assign  pc_o    =   pc.curpc;
    assign  snpc_o  =   pc.snpc;
    assign  pc.snpc =   pc.curpc + `XLEN'd4;
    assign  pc.dnpc =   (pc_op_i == PC_SEQ) ? pc.snpc : br_target;
      
    assign  temp_target = pc.curpc + imm_i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            pc.curpc <= `PC_RST;
        else 
            pc.curpc <= pc.dnpc;
    end

    /* branch unit */
    always_comb begin
        unique case (pc_op_i)
            PC_BR: begin
                if (alu_res_i == `XLEN'd1)
                    br_target = temp_target; 
                else 
                    br_target = pc.snpc; 
            end
            PC_JUMP: br_target = temp_target;
            PC_JALR: br_target = alu_res_i & ~`XLEN'd1;     // clear the LSB 
            default: br_target = pc.snpc;
        endcase
    end
    

endmodule
