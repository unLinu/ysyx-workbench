`include "npc_defines.svh"
module idu import npc_pkg::*; (
    // data
    input   npc_pkg::word_t         inst_i      ,
    output  npc_pkg::regid_t        rs1_o       ,
    output  npc_pkg::regid_t        rs2_o       ,
    output  npc_pkg::regid_t        rd_o        ,
    
    // control 
    output  npc_pkg::alu_op_t       alu_op_o    ,
    output  npc_pkg::imm_op_t       imm_op_o    ,
    output  npc_pkg::wb_src_t       wb_src_o    ,
    output  npc_pkg::alu_sel_t      alu_sel_o   ,
    output  npc_pkg::ld_op_t        ld_op_o     ,
    output  npc_pkg::st_op_t        st_op_o     ,

    output  logic                   rf_en_o     ,   // write back enable

    // Go to IFU
    output  npc_pkg::pc_update_t    pc_next     ,

    // Instruction Invalid
    output  logic                   inst_err    ,
    
    // Trap Flag
    output  logic                   ebreak_o   
);


/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    npc_pkg::inst_type_t    inst    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    assign  inst.raw    = inst_i    ;

    always_comb begin
        rs1_o       = `RLEN'd0      ;
        rs2_o       = `RLEN'd0      ;
        rd_o        = `RLEN'd0      ;
        rf_en_o     = 1'b0          ;
        alu_op_o    = ALU_ADD       ;
        imm_op_o    = IMM_I_TYPE    ;
        wb_src_o    = WB_ALU        ;
        alu_sel_o   = ALU_RS        ;
        ld_op_o     = LD_W          ;
        st_op_o     = ST_W          ;
        pc_next     = PC_SEQ        ;
        inst_err    = 1'b1          ;
        ebreak_o    = 1'b0          ;

        unique case (inst.r.opcode)
        
            ////////////
            /* R-TYPE */
            ////////////
            7'h33: begin        
                wb_src_o    = WB_ALU        ;
                alu_sel_o   = ALU_RS        ;
                pc_next     = PC_SEQ        ;

                rs1_o       = inst.r.rs1    ;
                rs2_o       = inst.r.rs2    ;
                rd_o        = inst.r.rd     ;
                rf_en_o     = 1'b1          ;

                inst_err = 1'b0             ;

                unique case ({inst.r.funct3, inst.r.funct7})
                    {3'h0, 7'h00}: alu_op_o = ALU_ADD     ;     // add
                    {3'h0, 7'h20}: alu_op_o = ALU_SUB     ;     // sub
                    {3'h4, 7'h00}: alu_op_o = ALU_XOR     ;     // xor
                    {3'h6, 7'h00}: alu_op_o = ALU_OR      ;     // or
                    {3'h7, 7'h00}: alu_op_o = ALU_AND     ;     // and
                    {3'h1, 7'h00}: alu_op_o = ALU_SLL     ;     // sll
                    {3'h5, 7'h00}: alu_op_o = ALU_SRL     ;     // srl
                    {3'h5, 7'h20}: alu_op_o = ALU_SRA     ;     // sra
                    {3'h2, 7'h00}: alu_op_o = ALU_LT      ;     // slt
                    {3'h3, 7'h00}: alu_op_o = ALU_LTU     ;     // sltu
                    default: begin
                        alu_op_o = ALU_ADD;
                        inst_err = 1'b1;
                    end 
                endcase
            end 

            ////////////
            /* I-TYPE */
            ////////////
            7'h13: begin
                imm_op_o    = IMM_I_TYPE    ;
                wb_src_o    = WB_ALU        ;
                alu_sel_o   = ALU_IMM       ;
                pc_next     = PC_SEQ        ;

                rs1_o       = inst.i.rs1    ;
                rd_o        = inst.i.rd     ;
                rf_en_o     = 1'b1          ;

                inst_err    = 1'b0          ;

                unique case ({inst.i.funct3, inst.i.imm[11:5]}) inside
                    {3'h0, 7'h??}: alu_op_o = ALU_ADD   ;       // addi
                    {3'h4, 7'h??}: alu_op_o = ALU_XOR   ;       // xori
                    {3'h6, 7'h??}: alu_op_o = ALU_OR    ;       // ori
                    {3'h7, 7'h??}: alu_op_o = ALU_AND   ;       // andi
                    {3'h1, 7'h00}: alu_op_o = ALU_SLL   ;       // slli
                    {3'h5, 7'h00}: alu_op_o = ALU_SRL   ;       // srli
                    {3'h5, 7'h20}: alu_op_o = ALU_SRA   ;       // srai
                    {3'h2, 7'h??}: alu_op_o = ALU_LT    ;       // slti
                    {3'h3, 7'h??}: alu_op_o = ALU_LTU   ;       // sltiu
                    default: begin
                        alu_op_o = ALU_ADD;
                        inst_err = 1'b1;
                    end 
                endcase
            end

            ///////////////
            /* LOAD TYPE */
            ///////////////
            7'h03: begin
                imm_op_o    = IMM_I_TYPE    ;
                wb_src_o    = WB_MEM        ;
                alu_sel_o   = ALU_IMM       ;
                alu_op_o    = ALU_ADD       ;
                pc_next     = PC_SEQ        ;

                rs1_o       = inst.i.rs1    ;
                rd_o        = inst.i.rd     ;
                rf_en_o     = 1'b0          ;   // 暂时的 

                inst_err    = 1'b0          ;

                unique case (inst.i.funct3) 
                    3'h0:    ld_op_o = LD_B ;                   // lb
                    3'h1:    ld_op_o = LD_H ;                   // lh
                    3'h2:    ld_op_o = LD_W ;                   // lw
                    3'h4:    ld_op_o = LD_BU;                   // lbu
                    3'h5:    ld_op_o = LD_HU;                   // lhu
                    default: begin
                        ld_op_o = LD_W ;
                        inst_err = 1'b1;
                    end
                endcase
            end

            ////////////
            /* S-TYPE */
            ////////////
            7'h23: begin
                imm_op_o    = IMM_S_TYPE    ;
                alu_sel_o   = ALU_IMM       ;
                alu_op_o    = ALU_ADD       ;
                pc_next     = PC_SEQ        ;

                rs1_o       = inst.s.rs1    ;
                rs2_o       = inst.s.rs2    ;

                inst_err    = 1'b0          ;

                unique case (inst.s.funct3)
                    3'h0:    st_op_o = ST_B ;                   // sb
                    3'h1:    st_op_o = ST_H ;                   // sh
                    3'h2:    st_op_o = ST_W ;                   // sw
                    default: begin
                        st_op_o = ST_W ;
                        inst_err = 1'b1;
                    end
                endcase
            end

            ////////////
            /* B-TYPE */  
            ////////////
            7'h63: begin
                imm_op_o    = IMM_B_TYPE    ;
                alu_sel_o   = ALU_RS        ;
                pc_next     = PC_BR         ;

                rs1_o       = inst.b.rs1    ;
                rs2_o       = inst.b.rs2    ;

                inst_err    = 1'b0          ;

                unique case (inst.b.funct3)
                    3'h0:    alu_op_o = ALU_EQ  ;               // beq
                    3'h1:    alu_op_o = ALU_NE  ;               // bne
                    3'h4:    alu_op_o = ALU_LT  ;               // blt
                    3'h5:    alu_op_o = ALU_GE  ;               // bge
                    3'h6:    alu_op_o = ALU_LTU ;               // bltu
                    3'h7:    alu_op_o = ALU_GEU ;               // bgeu
                    default: begin
                        alu_op_o = ALU_EQ;
                        inst_err = 1'b1;
                    end
                endcase
            end

            ////////////////
            /* OPCODE JAL */    /* ifu -> regfile imm -> ifu */
            ////////////////
            7'h6f: begin
                imm_op_o    = IMM_J_TYPE    ;
                wb_src_o    = WB_IFU        ;
                pc_next     = PC_JUMP       ;

                rd_o        = inst.j.rd     ;
                rf_en_o     = 1'b1          ;

                inst_err    = 1'b0          ;
            end  

            /////////////////
            /* OPCODE JALR */   /* ifu -> regfile alu -> ifu */   
            /////////////////
            7'h67: begin
                if (inst.i.funct3 == 3'h0) begin
                    imm_op_o    = IMM_I_TYPE    ;
                    wb_src_o    = WB_IFU        ;
                    alu_sel_o   = ALU_IMM       ;
                    alu_op_o    = ALU_ADD       ;
                    pc_next     = PC_JALR       ;

                    rs1_o       = inst.i.rs1    ;
                    rd_o        = inst.i.rd     ;
                    rf_en_o     = 1'b1          ;

                    inst_err    = 1'b0          ;
                end
                else 
                    inst_err    = 1'b1          ;
            end

            ////////////////
            /* OPCODE LUI */    /* imm -> regfile */
            ////////////////
            7'h37: begin
                imm_op_o    = IMM_U_TYPE    ;
                wb_src_o    = WB_IMM        ;

                rd_o        = inst.u.rd     ;
                rf_en_o     = 1'b1          ;

                inst_err    = 1'b0          ;
            end

            //////////////////
            /* OPCODE AUIPC */  
            //////////////////
            7'h17: begin
                imm_op_o    = IMM_U_TYPE    ;
                wb_src_o    = WB_ALU        ;
                alu_op_o    = ALU_ADD       ;
                alu_sel_o   = ALU_PC_IMM    ;

                rd_o        = inst.u.rd     ;
                rf_en_o     = 1'b1          ;

                inst_err    = 1'b0          ;
            end

            ////////////
            /* EBREAK */
            ////////////
            7'h73: begin
                if (inst.i.funct3 == 3'h0 && inst.i.imm == 12'h1) begin
                    inst_err  = 1'b0 ;    
                    ebreak_o  = 1'b1 ;
                end
                else 
                    inst_err  = 1'b1 ;
            end

            default: inst_err = 1'b1 ;
        endcase
    end
    
endmodule 
