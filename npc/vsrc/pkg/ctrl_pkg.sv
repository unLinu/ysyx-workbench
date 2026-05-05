package ctrl_pkg;
  /* Enum define */
  typedef enum logic [3:0] {
    ALU_OP_ADD, ALU_OP_SUB,
    ALU_OP_AND, ALU_OP_OR, ALU_OP_XOR,
    ALU_OP_EQ, ALU_OP_NE, ALU_OP_GE, ALU_OP_GEU,
    ALU_OP_SLL, ALU_OP_SRL, ALU_OP_SRA,
    ALU_OP_LT, ALU_OP_LTU
  } alu_op_e;

  typedef enum logic [2:0] {
    IMM_TYPE_I, IMM_TYPE_S,
    IMM_TYPE_B, IMM_TYPE_U,
    IMM_TYPE_J
  } imm_type_e;

  typedef enum logic [2:0] {
    WB_SEL_ALU, WB_SEL_MEM, WB_SEL_IMM, WB_SEL_IFU, WB_SEL_CSR
  } wb_sel_e;

  typedef enum logic [1:0] {
    ALU_SRC1_RS, ALU_SRC1_PC, ALU_SRC1_ZERO
  } alu_src1_e;

  typedef enum logic [1:0] {
    ALU_SRC2_RS, ALU_SRC2_IMM, ALU_SRC2_ZERO
  } alu_src2_e;

  typedef enum logic [2:0] {
    LD_TYPE_B, LD_TYPE_H, LD_TYPE_W, LD_TYPE_BU, LD_TYPE_HU
  } ld_type_e;

  typedef enum logic [1:0] {
    ST_TYPE_B, ST_TYPE_H, ST_TYPE_W
  } st_type_e;

  typedef enum logic [1:0] {
    BR_TYPE_JAL, BR_TYPE_JALR, BR_TYPE_COND, BR_TYPE_NONE
  } br_type_e;
  
  typedef enum logic [11:0] {
    MVENDORID = 12'hf11, MARCHID = 12'hf12, MSTATUS = 12'h300, MEPC = 12'h341, MCAUSE = 12'h342, MTVEC = 12'h305
  } csr_addr_e;
  
  typedef enum logic [0:0] {
    CSR_OP_W, CSR_OP_S
  } csr_op_e;

endpackage
