package pipeline_pkg;

  /* ==================== */
  /* ===== IF -> ID ===== */
  /* ==================== */
  typedef struct packed {
    // PC reg [ifu -> wbu]
    isa_pkg::word_t           pc          ;
    // Inst [ifu -> idu]
    isa_pkg::word_t           inst        ;
  } if2id_data_t;

  /* ==================== */
  /* ===== ID -> EX ===== */
  /* ==================== */
  typedef struct packed {
    // PC reg [ifu -> wbu]
    isa_pkg::word_t           pc          ;
    // Debug
    isa_pkg::word_t           inst        ;
    // Write back [idu -> wbu]
    logic                     rf_wb_en    ;
    isa_pkg::regid_t          rd          ;
    ctrl_pkg::wb_sel_e        wb_sel      ;
    // ALU execution [idu -> exu]
    isa_pkg::word_t           imm         ;
    isa_pkg::word_t           rs1_data    ;
    isa_pkg::word_t           rs2_data    ;
    ctrl_pkg::alu_op_e        alu_op      ;
    ctrl_pkg::alu_src1_e      alu_src1    ;
    ctrl_pkg::alu_src2_e      alu_src2    ;
    ctrl_pkg::br_type_e       br_type     ;
    // Mem access [idu -> lsu]
    logic                     mem_wr_en   ;
    logic                     mem_rd_en   ;
    ctrl_pkg::ld_type_e       ld_type     ;
    ctrl_pkg::st_type_e       st_type     ;
    // Exception [idu -> wbu/csr]
    logic                     ebreak_flag ;
    logic                     ecall_flag  ;
    logic                     mret_flag   ;
    logic                     csr_wb_en   ;
    logic   [11:0]            csr_addr    ;
    ctrl_pkg::csr_op_e        csr_op      ;
  } id2ex_data_t;

  /* ==================== */
  /* ===== EX -> LS ===== */
  /* ==================== */
  typedef struct packed {
    // PC reg [ifu -> wbu]
    isa_pkg::word_t           pc          ;
    // Debug
    isa_pkg::word_t           inst        ;
    // Write back [idu -> wbu]
    logic                     rf_wb_en    ;
    ctrl_pkg::wb_sel_e        wb_sel      ;
    isa_pkg::regid_t          rd          ;
    // Mem access [idu/exu -> lsu]
    logic                     mem_wr_en   ;
    logic                     mem_rd_en   ;
    ctrl_pkg::ld_type_e       ld_type     ;
    ctrl_pkg::st_type_e       st_type     ;
    isa_pkg::word_t           rs2_data    ;   // M[rs1+imm] = rs2
    // Execution result [exu -> lsu]
    isa_pkg::word_t           alu_res     ;   // [Shared] addr | write back data
    // Exception [idu/exu -> wbu/csr]
    logic                     ebreak_flag ;
    logic                     ecall_flag  ;
    logic                     mret_flag   ;
    logic                     csr_wb_en   ;
    logic   [11:0]            csr_addr    ;
    ctrl_pkg::csr_op_e        csr_op      ;
  } ex2ls_data_t;

  /* ==================== */
  /* ===== LS -> WB ===== */
  /* ==================== */
  typedef struct packed {
    // PC reg [ifu -> wbu]
    isa_pkg::word_t           pc          ;
    // Debug
    isa_pkg::word_t           inst        ;
    // Write back [idu/exu -> wbu]
    logic                     rf_wb_en    ;
    isa_pkg::regid_t          rd          ;
    ctrl_pkg::wb_sel_e        wb_sel      ;
    // Execution result [exu -> lsu]
    isa_pkg::word_t           alu_res     ;   // [Shared] write csr | write back regfile
    // Exception [idu/exu/lsu -> wbu/csr]
    logic                     ebreak_flag ;
    logic                     ecall_flag  ;
    logic                     mret_flag   ;
    logic                     csr_wb_en   ;
    logic   [11:0]            csr_addr    ;
    ctrl_pkg::csr_op_e        csr_op      ;
    isa_pkg::word_t           mem_rdata   ;
  } ls2wb_data_t;

endpackage
