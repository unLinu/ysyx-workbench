`include "npc_defines.svh"
package npc_pkg;
    typedef logic [`XLEN-1:0]    word_t  ;
    typedef logic [      4:0]    regid_t ;

    /* Instruction types */
    typedef struct packed {
        logic [ 6:0] funct7     ;
        regid_t      rs2        ;
        regid_t      rs1        ;
        logic [ 2:0] funct3     ;
        regid_t      rd         ;
        logic [ 6:0] opcode     ;
    } r_type_t;

    typedef struct packed {
        logic [11:0] imm        ;
        regid_t      rs1        ;
        logic [ 2:0] funct3     ;
        regid_t      rd         ;
        logic [ 6:0] opcode     ;
    } i_type_t;

    typedef struct packed {
        logic [ 6:0] imm_11_5   ;
        regid_t      rs1        ;
        regid_t      rs2        ;
        logic [ 2:0] funct3     ;
        logic [ 4:0] imm_4_0    ;
        logic [ 6:0] opcode     ;
    } s_type_t;

    typedef struct packed {
        logic [ 6:0] imm_12_10_5;
        regid_t      rs2        ;
        regid_t      rs1        ;
        logic [ 2:0] funct3     ;
        logic [ 4:0] imm_4_1_11 ;
        logic [ 6:0] opcode     ;
    } b_type_t;

    typedef struct packed {
        logic [19:0] imm        ;
        regid_t      rd         ;
        logic [ 6:0] opcode     ;
    } u_type_t;

    typedef struct packed {
        logic [19:0] imm        ;
        regid_t      rd         ;
        logic [ 6:0] opcode     ;
    } j_type_t;

    typedef union packed {
        logic [31:0] raw        ;
        r_type_t     r          ;
        i_type_t     i          ;
        s_type_t     s          ;
        b_type_t     b          ;
        u_type_t     u          ;
        j_type_t     j          ;
    } inst_type_t;
    
    /* Enum define */
    typedef enum [3:0] {
        ALU_ADD, ALU_SUB,
        ALU_AND, ALU_OR, ALU_XOR,
        ALU_EQ, ALU_NE, ALU_GE, ALU_GEU,
        ALU_SLL, ALU_SRL, ALU_SRA,
        ALU_LT, ALU_LTU
    } alu_op_t;

    typedef enum [2:0] {
        IMM_I_TYPE, IMM_S_TYPE,
        IMM_B_TYPE, IMM_U_TYPE,
        IMM_J_TYPE
    } imm_op_t;

    typedef enum [1:0] {
        PC_SEQ, PC_JUMP, PC_JALR, PC_BR
    } pc_update_t;

    typedef enum [1:0] {
        WB_ALU, WB_MEM, WB_IMM, WB_IFU
    } wb_src_t;

    typedef enum [1:0] {
        ALU_RS, ALU_IMM, ALU_PC_IMM
    } alu_sel_t;

    typedef enum [2:0] {
        LD_B, LD_H, LD_W, LD_BU, LD_HU
    } ld_op_t;

    typedef enum [1:0] {
        ST_B, ST_H, ST_W
    } st_op_t;

endpackage
