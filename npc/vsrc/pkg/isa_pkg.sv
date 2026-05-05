`include "npc_defines.svh"
package isa_pkg;
  // parameter
  localparam PC_RST      = `XLEN'h3000_0000  ;

  localparam OPCODE_R    = 7'h33             ;
  localparam OPCODE_I    = 7'h13             ;
  localparam OPCODE_LD   = 7'h03             ;
  localparam OPCODE_S    = 7'h23             ;
  localparam OPCODE_B    = 7'h63             ;
  localparam OPCODE_JAL  = 7'h6f             ;
  localparam OPCODE_JALR = 7'h67             ;
  localparam OPCODE_LUI  = 7'h37             ;
  localparam OPCODE_AUI  = 7'h17             ;
  localparam OPCODE_SYS  = 7'h73             ;

  localparam I_EBREAK    = `XLEN'h00100073   ;
  localparam I_ECALL     = `XLEN'h00000073   ;
  localparam I_MRET      = `XLEN'h30200073   ;

  // typedef
  typedef logic [`XLEN-1:0]    word_t  ;
  typedef logic [`RLEN-1:0]    regid_t ;

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
    regid_t      rs2        ;
    regid_t      rs1        ;
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

  // CSR
  typedef struct packed {
    word_t       mstatus    ;
    word_t       mepc       ;
    word_t       mcause     ;
    word_t       mtvec      ;
  } csr_file_t;

endpackage
