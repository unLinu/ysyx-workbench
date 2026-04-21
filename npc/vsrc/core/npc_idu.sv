`include "npc_defines.svh"
module npc_idu import isa_pkg::*, ctrl_pkg::*; (
  // system signals
  input   logic             clk               ,
  // forward path from wbu
  input   isa_pkg::regid_t  wb_rd_i           ,
  input   isa_pkg::word_t   wb_rd_data_i      ,
  input   logic             wb_rf_wb_en_i     ,
  // interface
  handshake_if.slave        rx_if             ,   // ifu -> idu
  handshake_if.master       tx_if                 // idu -> exu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  isa_pkg::inst_type_t          inst          ;   // union

  // interface data
  pipeline_pkg::if2id_data_t    rx_data       ;
  pipeline_pkg::id2ex_data_t    tx_data       ;

  // internal signals
  isa_pkg::regid_t              rs1           ;   // decoder -> regfile
  isa_pkg::regid_t              rs2           ;   // decoder -> regfile
  ctrl_pkg::imm_type_e          imm_type      ;   // decoder -> imm_gen

  isa_pkg::regid_t              rd            ;   // decoder -> tx_if
  isa_pkg::word_t               rs1_data      ;   // regfile -> tx_if
  isa_pkg::word_t               rs2_data      ;   // regfile -> tx_if
  isa_pkg::word_t               imm           ;   // imm_gen -> tx_if
  ctrl_pkg::alu_op_e            alu_op        ;   // decoder -> tx_if
  ctrl_pkg::alu_src1_e          alu_src1      ;   // decoder -> tx_if
  ctrl_pkg::alu_src2_e          alu_src2      ;   // decoder -> tx_if
  ctrl_pkg::wb_sel_e            wb_sel        ;   // decoder -> tx_if
  ctrl_pkg::ld_type_e           ld_type       ;   // decoder -> tx_if
  ctrl_pkg::st_type_e           st_type       ;   // decoder -> tx_if
  ctrl_pkg::csr_op_e            csr_op        ;   // decoder -> tx_if
  ctrl_pkg::br_type_e           br_type       ;   // decoder -> tx_if
  logic                         rf_wb_en      ;   // decoder -> tx_if
  logic                         ebreak_flag   ;   // decoder -> tx_if
  logic                         ecall_flag    ;   // decoder -> tx_if
  logic                         mret_flag     ;   // decoder -> tx_if
  logic                         csr_wb_en     ;   // decoder -> tx_if
  logic                         mem_wr_en     ;   // decoder -> tx_if
  logic                         mem_rd_en     ;   // decoder -> tx_if

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  ///////////////////////////////
  /* pipeline control and data */
  ///////////////////////////////
  assign tx_if.valid  = rx_if.valid                                         ;
  assign rx_if.ready  = tx_if.ready                                         ;

  assign  rx_data             = pipeline_pkg::if2id_data_t'(rx_if.data_pkg) ;   // unpacking
  assign  inst.raw            = rx_data.inst                                ;   // slice
  assign  tx_if.data_pkg      = tx_data                                     ;   // packing

  assign  tx_data = '{
    // PC reg
    pc                        : rx_data.pc                                  ,
    // Debug
    inst                      : rx_data.inst                                ,
    // Write back
    rf_wb_en                  : rf_wb_en                                    ,
    rd                        : rd                                          ,
    wb_sel                    : wb_sel                                      ,
    // ALU execution
    imm                       : imm                                         ,
    rs1_data                  : rs1_data                                    ,
    rs2_data                  : rs2_data                                    ,
    alu_op                    : alu_op                                      ,
    alu_src1                  : alu_src1                                    ,
    alu_src2                  : alu_src2                                    ,
    br_type                   : rx_if.valid ? br_type : BR_TYPE_NONE        ,
    // Mem access
    mem_wr_en                 : mem_wr_en                                   ,
    mem_rd_en                 : mem_rd_en                                   ,
    ld_type                   : ld_type                                     ,
    st_type                   : st_type                                     ,
    // Exception
    ebreak_flag               : ebreak_flag                                 ,
    ecall_flag                : ecall_flag                                  ,
    mret_flag                 : mret_flag                                   ,
    csr_wb_en                 : csr_wb_en                                   ,
    csr_addr                  : inst.i.imm[11:0]                            ,
    csr_op                    : csr_op                                      ,

    default                   : '0
  };

  // ===============================================
  // ========= decoder combinational logic =========
  // ===============================================
  always_comb begin
    rs1           = `RLEN'd0            ;
    rs2           = `RLEN'd0            ;
    rd            = `RLEN'd0            ;
    rf_wb_en      = 1'b0                ;
    imm_type      = IMM_TYPE_I          ;
    alu_op        = ALU_OP_ADD          ;
    alu_src1      = ALU_SRC1_RS         ;
    alu_src2      = ALU_SRC2_RS         ;
    wb_sel        = WB_SEL_ALU          ;
    ld_type       = LD_TYPE_W           ;
    st_type       = ST_TYPE_W           ;
    br_type       = BR_TYPE_NONE        ;
    csr_op        = CSR_OP_W            ;
    csr_wb_en     = 1'b0                ;
    ebreak_flag   = 1'b0                ;
    ecall_flag    = 1'b0                ;
    mret_flag     = 1'b0                ;
    mem_wr_en     = 1'b0                ;
    mem_rd_en     = 1'b0                ;

    unique case (inst.r.opcode)

      ////////////
      /* R-TYPE */
      ////////////
      OPCODE_R: begin
        alu_src1  = ALU_SRC1_RS   ;
        alu_src2  = ALU_SRC2_RS   ;
        wb_sel    = WB_SEL_ALU    ;

        rs1       = inst.r.rs1    ;
        rs2       = inst.r.rs2    ;
        rd        = inst.r.rd     ;
        rf_wb_en  = 1'b1          ;

        unique case ({inst.r.funct3, inst.r.funct7})
          {3'h0, 7'h00}: alu_op = ALU_OP_ADD     ;     // add
          {3'h0, 7'h20}: alu_op = ALU_OP_SUB     ;     // sub
          {3'h4, 7'h00}: alu_op = ALU_OP_XOR     ;     // xor
          {3'h6, 7'h00}: alu_op = ALU_OP_OR      ;     // or
          {3'h7, 7'h00}: alu_op = ALU_OP_AND     ;     // and
          {3'h1, 7'h00}: alu_op = ALU_OP_SLL     ;     // sll
          {3'h5, 7'h00}: alu_op = ALU_OP_SRL     ;     // srl
          {3'h5, 7'h20}: alu_op = ALU_OP_SRA     ;     // sra
          {3'h2, 7'h00}: alu_op = ALU_OP_LT      ;     // slt
          {3'h3, 7'h00}: alu_op = ALU_OP_LTU     ;     // sltu
          default: r_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
        endcase
      end

      ////////////
      /* I-TYPE */
      ////////////
      OPCODE_I: begin
        imm_type    = IMM_TYPE_I    ;
        wb_sel      = WB_SEL_ALU    ;
        alu_src1    = ALU_SRC1_RS   ;
        alu_src2    = ALU_SRC2_IMM  ;

        rs1         = inst.i.rs1    ;
        rd          = inst.i.rd     ;
        rf_wb_en    = 1'b1          ;

        unique case (inst.i.funct3)
          3'h0: alu_op = ALU_OP_ADD   ;           // addi
          3'h4: alu_op = ALU_OP_XOR   ;           // xori
          3'h6: alu_op = ALU_OP_OR    ;           // ori
          3'h7: alu_op = ALU_OP_AND   ;           // andi
          3'h2: alu_op = ALU_OP_LT    ;           // slti
          3'h3: alu_op = ALU_OP_LTU   ;           // sltiu
          3'h1: begin
            unique if (inst.i.imm[11:5] == 7'h00)
              alu_op   = ALU_OP_SLL   ;           // slli
            else 
              i_inst_err1: `ASSERT_INST(rx_if.valid, inst.raw)
          end
          3'h5: begin
            unique if (inst.i.imm[11:5] == 7'h00)
              alu_op   = ALU_OP_SRL   ;           // srli
            else if (inst.i.imm[11:5] == 7'h20)
              alu_op   = ALU_OP_SRA   ;           // srai
            else
              i_inst_err2: `ASSERT_INST(rx_if.valid, inst.raw)
          end
        endcase
      end

      ///////////////
      /* LOAD-TYPE */
      ///////////////
      OPCODE_LD: begin
        imm_type    = IMM_TYPE_I    ;
        wb_sel      = WB_SEL_MEM    ;
        alu_src1    = ALU_SRC1_RS   ;
        alu_src2    = ALU_SRC2_IMM  ;
        alu_op      = ALU_OP_ADD    ;

        rs1         = inst.i.rs1    ;
        rd          = inst.i.rd     ;
        rf_wb_en    = 1'b1          ;
        mem_rd_en   = 1'b1          ;

        unique case (inst.i.funct3)
          3'h0: ld_type = LD_TYPE_B   ;     // lb
          3'h1: ld_type = LD_TYPE_H   ;     // lh
          3'h2: ld_type = LD_TYPE_W   ;     // lw
          3'h4: ld_type = LD_TYPE_BU  ;     // lbu
          3'h5: ld_type = LD_TYPE_HU  ;     // lhu
          default: ld_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
        endcase
      end

      ////////////
      /* S-TYPE */
      ////////////
      OPCODE_S: begin
        imm_type    = IMM_TYPE_S    ;
        alu_src1    = ALU_SRC1_RS   ;
        alu_src2    = ALU_SRC2_IMM  ;
        alu_op      = ALU_OP_ADD    ;

        rs1         = inst.s.rs1    ;
        rs2         = inst.s.rs2    ;
        mem_wr_en   = 1'b1          ;

        unique case (inst.s.funct3)
          3'h0: st_type = ST_TYPE_B ;       // sb
          3'h1: st_type = ST_TYPE_H ;       // sh
          3'h2: st_type = ST_TYPE_W ;       // sw
          default: st_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
        endcase
      end

      ////////////
      /* B-TYPE */
      ////////////
      OPCODE_B: begin
        imm_type    = IMM_TYPE_B    ;
        br_type     = BR_TYPE_COND  ;
        alu_src1    = ALU_SRC1_RS   ;
        alu_src2    = ALU_SRC2_RS   ;

        rs1         = inst.b.rs1    ;
        rs2         = inst.b.rs2    ;

        unique case (inst.b.funct3)
          3'h0: alu_op = ALU_OP_EQ  ;       // beq
          3'h1: alu_op = ALU_OP_NE  ;       // bne
          3'h4: alu_op = ALU_OP_LT  ;       // blt
          3'h5: alu_op = ALU_OP_GE  ;       // bge
          3'h6: alu_op = ALU_OP_LTU ;       // bltu
          3'h7: alu_op = ALU_OP_GEU ;       // bgeu
          default: b_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
        endcase
      end

      ////////////////
      /* OPCODE JAL */
      ////////////////
      OPCODE_JAL: begin
        imm_type    = IMM_TYPE_J    ;
        br_type     = BR_TYPE_JAL   ;
        wb_sel      = WB_SEL_IFU    ;
        alu_src1    = ALU_SRC1_PC   ;
        alu_src2    = ALU_SRC2_IMM  ;

        rd          = inst.j.rd     ;
        rf_wb_en    = 1'b1          ;
      end


      /////////////////
      /* OPCODE JALR */
      /////////////////
      OPCODE_JALR: begin
        unique if (inst.i.funct3 == 3'h0) begin
          imm_type  = IMM_TYPE_I    ;
          br_type   = BR_TYPE_JALR  ;
          wb_sel    = WB_SEL_IFU    ;
          alu_src1  = ALU_SRC1_RS   ;
          alu_src2  = ALU_SRC2_IMM  ;
          alu_op    = ALU_OP_ADD    ;

          rs1       = inst.i.rs1    ;
          rd        = inst.i.rd     ;
          rf_wb_en  = 1'b1          ;
        end
        else
          jalr_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
      end


      ////////////////
      /* OPCODE LUI */
      ////////////////
      OPCODE_LUI: begin
        imm_type    = IMM_TYPE_U    ;
        wb_sel      = WB_SEL_ALU    ;
        alu_src1    = ALU_SRC1_ZERO ;
        alu_src2    = ALU_SRC2_IMM  ;

        rd          = inst.u.rd     ;
        rf_wb_en    = 1'b1          ;
      end

      //////////////////
      /* OPCODE AUIPC */
      //////////////////
      OPCODE_AUI: begin
        imm_type    = IMM_TYPE_U    ;
        wb_sel      = WB_SEL_ALU    ;
        alu_op      = ALU_OP_ADD    ;
        alu_src1    = ALU_SRC1_PC   ;
        alu_src2    = ALU_SRC2_IMM  ;

        rd          = inst.u.rd     ;
        rf_wb_en    = 1'b1          ;
      end

      ////////////
      /* SYSTEM */
      ////////////
      OPCODE_SYS: begin
        imm_type    = IMM_TYPE_I    ;
        wb_sel      = WB_SEL_CSR    ;
        alu_op      = ALU_OP_ADD    ;
        alu_src1    = ALU_SRC1_RS   ;
        alu_src2    = ALU_SRC2_ZERO ;

        rd          = inst.i.rd     ;
        rs1         = inst.i.rs1    ;
        rf_wb_en    = 1'b1          ;
        csr_wb_en   = 1'b1          ;

        unique case (inst.i.funct3)
          3'h1: csr_op = CSR_OP_W   ;           // csrrw
          3'h2: csr_op = CSR_OP_S   ;           // csrrs
          3'h0: begin
            rf_wb_en  = 1'b0        ;
            csr_wb_en = 1'b0        ;
            unique case (inst.raw)
              I_EBREAK: ebreak_flag = 1'b1  ;   // ebreak
              I_ECALL:  ecall_flag  = 1'b1  ;   // ecall
              I_MRET:   mret_flag   = 1'b1  ;   // mret
            endcase
          end
          default: sys_inst_err: `ASSERT_INST(rx_if.valid, inst.raw)
        endcase
      end

      default: decode_err: `ASSERT_INST(rx_if.valid, inst.raw)

    endcase
  end

/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  npc_idu_regfile u_regfile (
    // Interfaces
    .rs1_i        ( rs1           ),
    .rs2_i        ( rs2           ),
    .rd_i         ( wb_rd_i       ),
    .rd_data_i    ( wb_rd_data_i  ),
    .rs1_data_o   ( rs1_data      ),
    .rs2_data_o   ( rs2_data      ),
    // Inputs
    .clk          ( clk           ),
    .wr_en_i      ( wb_rf_wb_en_i )
  );

  npc_idu_imm_gen u_imm_gen (
    // Interfaces
    .imm_type_i  ( imm_type   ),
    .inst_i      ( inst.raw   ),
    .imm_o       ( imm        )
  );

endmodule
