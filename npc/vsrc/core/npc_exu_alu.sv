`include "npc_defines.svh"
module npc_exu_alu import ctrl_pkg::*; (
  // control
  input   ctrl_pkg::alu_op_e       alu_op_i    ,
  // data
  input   isa_pkg::word_t          src1_i      ,
  input   isa_pkg::word_t          src2_i      ,
  output  isa_pkg::word_t          alu_res_o
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  logic                        is_sub      ;
  logic                        is_eq       ;
  logic                        is_lt       ;
  logic                        is_geu      ;
  
  logic   [$clog2(`XLEN)-1:0]  shift       ;
  logic                        cout        ;
  logic                        cin         ;
  
  isa_pkg::word_t              src2_mux    ;
  isa_pkg::word_t              adder_res   ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  assign  shift    = src2_i[`RLEN-1:0];
  assign  is_sub   = alu_op_i inside {ALU_OP_SUB, ALU_OP_LT, ALU_OP_LTU, ALU_OP_EQ, ALU_OP_NE, ALU_OP_GE, ALU_OP_GEU};
  assign  is_eq    = adder_res == `XLEN'd0;
  assign  is_lt    = (src1_i[`XLEN-1] != src2_i[`XLEN-1]) ? src1_i[`XLEN-1] : adder_res[`XLEN-1];
  assign  is_geu   = cout; 
  assign  src2_mux = is_sub ? ~src2_i : src2_i;
  assign  cin      = is_sub;     
  assign  {cout, adder_res} = {1'b0, src1_i} + {1'b0, src2_mux} + {{(`XLEN-1){1'b0}} ,cin};


  always_comb begin
    alu_res_o = 'd0;
    unique case (alu_op_i)
      ALU_OP_ADD, ALU_OP_SUB: alu_res_o = adder_res; 
      ALU_OP_AND:  alu_res_o = src1_i & src2_i;
      ALU_OP_OR:   alu_res_o = src1_i | src2_i;
      ALU_OP_XOR:  alu_res_o = src1_i ^ src2_i;
      ALU_OP_SLL:  alu_res_o = src1_i << shift;
      ALU_OP_SRL:  alu_res_o = src1_i >> shift;
      ALU_OP_SRA:  alu_res_o = $signed(src1_i) >>> shift;
      ALU_OP_EQ:   alu_res_o = {{(`XLEN-1){1'b0}},  is_eq };
      ALU_OP_NE:   alu_res_o = {{(`XLEN-1){1'b0}}, ~is_eq };
      ALU_OP_LT:   alu_res_o = {{(`XLEN-1){1'b0}},  is_lt };
      ALU_OP_LTU:  alu_res_o = {{(`XLEN-1){1'b0}}, ~is_geu};
      ALU_OP_GE:   alu_res_o = {{(`XLEN-1){1'b0}}, ~is_lt };
      ALU_OP_GEU:  alu_res_o = {{(`XLEN-1){1'b0}},  is_geu};
      default:     alu_op_error: assert(0); else $fatal("Invalid alu_op_i!");
    endcase
  end

endmodule
