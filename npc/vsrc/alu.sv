`include "npc_defines.svh"
module alu import npc_pkg::*; (
    // control
    input   npc_pkg::alu_op_t        alu_op_i    ,

    // data
    input   npc_pkg::word_t          src1_i      ,
    input   npc_pkg::word_t          src2_i      ,
    output  npc_pkg::word_t          alu_res_o 
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    logic           is_sub      ;
    logic           is_eq       ;
    logic           is_lt       ;
    logic           is_geu      ;
    
    logic   [ 4:0]  shift       ;
    logic           cout        ;
    logic           cin         ;
    
    npc_pkg::word_t          src2_mux    ;
    npc_pkg::word_t          adder_res   ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    assign  shift    = src2_i[`RLEN-1:0];
    assign  is_sub   = alu_op_i inside {ALU_SUB, ALU_LT, ALU_LTU, ALU_EQ, ALU_NE, ALU_GE, ALU_GEU};
    assign  is_eq    = adder_res == `XLEN'd0;
    assign  is_lt    = (src1_i[`XLEN-1] != src2_i[`XLEN-1]) ? src1_i[`XLEN-1] : adder_res[`XLEN-1];
    assign  is_geu   = cout; 
    assign  src2_mux = is_sub ? ~src2_i : src2_i;
    assign  cin      = is_sub;     
    assign  {cout, adder_res} = {1'b0, src1_i} + {1'b0, src2_mux} + {{(`XLEN-1){1'b0}} ,cin};


    always_comb begin
        unique case (alu_op_i)
            ALU_ADD, ALU_SUB: alu_res_o = adder_res; 
            ALU_AND:  alu_res_o = src1_i & src2_i;
            ALU_OR:   alu_res_o = src1_i | src2_i;
            ALU_XOR:  alu_res_o = src1_i ^ src2_i;
            ALU_SLL:  alu_res_o = src1_i << shift;
            ALU_SRL:  alu_res_o = src1_i >> shift;
            ALU_SRA:  alu_res_o = $signed(src1_i) >>> shift;
            ALU_EQ:   alu_res_o = {{(`XLEN-1){1'b0}},  is_eq };
            ALU_NE:   alu_res_o = {{(`XLEN-1){1'b0}}, ~is_eq };
            ALU_LT:   alu_res_o = {{(`XLEN-1){1'b0}},  is_lt };
            ALU_LTU:  alu_res_o = {{(`XLEN-1){1'b0}}, ~is_geu};
            ALU_GE:   alu_res_o = {{(`XLEN-1){1'b0}}, ~is_lt };
            ALU_GEU:  alu_res_o = {{(`XLEN-1){1'b0}},  is_geu};
            default:  alu_res_o = `XLEN'd0;
        endcase
    end

endmodule
