`include "npc_defines.svh"
module npc_exu import ctrl_pkg::*; #(
  parameter string ARCH = "SINGLE"
)(
  // forward path to ifu
  output  bypass_pkg::pc_fwd_t      ex_jump_o     ,
  // interface
  handshake_if.slave                rx_if         ,       // idu -> exu
  handshake_if.master               tx_if                 // exu -> lsu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // interface
  pipeline_pkg::id2ex_data_t    rx_data       ;
  pipeline_pkg::ex2ls_data_t    tx_data       ;

  // internal signals
  isa_pkg::word_t               pc            ;
  isa_pkg::word_t               br_target     ;
  isa_pkg::word_t               imm           ;
  isa_pkg::word_t               rs1_data      ;
  isa_pkg::word_t               rs2_data      ;
  isa_pkg::word_t               alu_res       ;
  ctrl_pkg::alu_op_e            alu_op        ;
  ctrl_pkg::alu_src1_e          alu_src1      ;
  ctrl_pkg::alu_src2_e          alu_src2      ;
  ctrl_pkg::br_type_e           br_type       ;
  isa_pkg::word_t               src1          ;
  isa_pkg::word_t               src2          ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // handshake
  generate
    if (ARCH == "SINGLE") begin: g_single_arch
      assign tx_if.valid  = 1'b1              ;
      assign rx_if.ready  = 1'b1              ;
    end
  endgenerate

  assign  rx_data             = pipeline_pkg::id2ex_data_t'(rx_if.data_pkg) ;   // unpacking
  assign  tx_if.data_pkg      = tx_data                                     ;   // packing

  // --------------------------- rx signals begin -------------------------
  assign  pc                  = rx_data.pc                                  ;
  assign  imm                 = rx_data.imm                                 ;
  assign  alu_op              = rx_data.alu_op                              ;
  assign  br_type             = rx_data.br_type                             ;
  assign  rs1_data            = rx_data.rs1_data                            ;
  assign  rs2_data            = rx_data.rs2_data                            ;
  assign  alu_src1            = rx_data.alu_src1                            ;
  assign  alu_src2            = rx_data.alu_src2                            ;
  // --------------------------- rx signals end ---------------------------

  // --------------------------- tx drive begin ---------------------------
  assign  tx_data = '{
    // PC reg
    pc                        : rx_data.pc                                  ,
    // Write back
    rf_wb_en                  : rx_data.rf_wb_en                            ,
    wb_sel                    : rx_data.wb_sel                              ,
    rd                        : rx_data.rd                                  ,
    // Mem access
    mem_wr_en                 : rx_data.mem_wr_en                           ,
    mem_rd_en                 : rx_data.mem_rd_en                           ,
    ld_type                   : rx_data.ld_type                             ,
    st_type                   : rx_data.st_type                             ,
    rs2_data                  : rx_data.rs2_data                            ,
    // Execution result
    alu_res                   : alu_res                                     ,
    // Exception
    ebreak_flag               : rx_data.ebreak_flag                         ,
    ecall_flag                : rx_data.ecall_flag                          ,
    mret_flag                 : rx_data.mret_flag                           ,
    csr_wb_en                 : rx_data.csr_wb_en                           ,
    csr_addr                  : rx_data.csr_addr                            ,
    csr_op                    : rx_data.csr_op                              ,

    default                   : '0
  };
  // --------------------------- tx drive end -----------------------------

  /* ALU Src Mux */
  always_comb begin
    unique case (alu_src1)
      ALU_SRC1_RS  : src1 = rs1_data ;
      ALU_SRC1_PC  : src1 = pc       ;
      ALU_SRC1_ZERO: src1 = '0       ;
      default      : src1 = '0       ;
    endcase

    unique case (alu_src2)
      ALU_SRC2_RS  : src2 = rs2_data ;
      ALU_SRC2_IMM : src2 = imm      ;
      ALU_SRC2_ZERO: src2 = '0       ;
      default      : src2 = '0       ;
    endcase
  end

  /* pc control */
  always_comb begin
    unique case (br_type)
      BR_TYPE_COND: br_target = pc + imm                                    ;
      BR_TYPE_JAL : br_target = alu_res                                     ;
      BR_TYPE_JALR: br_target = alu_res & ~`XLEN'd1                         ;
      BR_TYPE_NONE: br_target = '0                                          ;
    endcase
  end
 
  // forward path to ifu
  assign  ex_jump_o.pc    = br_target                                       ;
  always_comb begin
    ex_jump_o.valid = 1'b0                                                  ;
    unique case (br_type)
      BR_TYPE_NONE: ex_jump_o.valid = 1'b0                                  ;
      BR_TYPE_JAL : ex_jump_o.valid = 1'b1                                  ;
      BR_TYPE_JALR: ex_jump_o.valid = 1'b1                                  ;
      BR_TYPE_COND: ex_jump_o.valid = alu_res[0] ? 1'b1 : 1'b0              ;
    endcase
  end

/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  npc_exu_alu u_alu (
    .alu_op_i      ( alu_op     ),
    .src1_i        ( src1       ),
    .src2_i        ( src2       ),
    .alu_res_o     ( alu_res    )
  );

endmodule
