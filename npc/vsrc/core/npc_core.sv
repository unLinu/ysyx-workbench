module npc_core (
  // System signals
  input   logic               clk               ,
  input   logic               rst_n             ,
  // Fetch Instruction
  input   logic               inst_valid        ,
  input   isa_pkg::word_t     inst_i            ,
  output  isa_pkg::word_t     pc_o              ,
  // Mem access [DPI]
  mem_if.master               m_mem_if          ,
  // Halt [Debug]
  output  logic               ebreak_o
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // internal signals
  // IFU <-> WBU/CSR
  logic                     wb2if_trap_valid    ;
  logic                     wb2if_mret_valid    ;
  isa_pkg::word_t           csr2if_trap_pc      ;
  isa_pkg::word_t           csr2if_mret_pc      ;
  bypass_pkg::pc_fwd_t      wb2if_trap          ;
  bypass_pkg::pc_fwd_t      wb2if_mret          ;

  // IFU <-> IDU
  bypass_pkg::pc_fwd_t      ex2if_jump          ;

  // IDU <-> WBU
  logic                     wb2id_rf_wb_en      ;
  isa_pkg::regid_t          wb2id_rd            ;
  isa_pkg::word_t           wb2id_rd_data       ;

  // WBU <-> CSR
  isa_pkg::word_t           wb2csr_pc           ;
  isa_pkg::word_t           csr2wb_csr_rdata    ;
  isa_pkg::word_t           wb2csr_rs1_data     ;   // for csr inst
  logic   [11:0]            wb2csr_csr_addr     ;
  ctrl_pkg::csr_op_e        wb2csr_csr_op       ;
  logic                     wb2csr_wb_en        ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  assign  wb2if_trap = '{pc: csr2if_trap_pc, valid: wb2if_trap_valid}    ;
  assign  wb2if_mret = '{pc: csr2if_mret_pc, valid: wb2if_mret_valid}    ;

/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  // Interface
  handshake_if #(pipeline_pkg::if2id_data_t)    if2id_if()      ;
  handshake_if #(pipeline_pkg::id2ex_data_t)    id2ex_if()      ;
  handshake_if #(pipeline_pkg::ex2ls_data_t)    ex2ls_if()      ;
  handshake_if #(pipeline_pkg::ls2wb_data_t)    ls2wb_if()      ;

  // Unit
  npc_ifu u_ifu (
    // Interfaces
    .ex_jump_i    ( ex2if_jump      ),
    .wb_trap_i    ( wb2if_trap      ),
    .wb_mret_i    ( wb2if_mret      ),
    .inst_i       ( inst_i          ),
    .pc_o         ( pc_o            ),
    .tx_if        ( if2id_if.master ),
    // Inputs
    .clk          ( clk             ),
    .rst_n        ( rst_n           ),
    .inst_valid   ( inst_valid      )
  );

  npc_idu u_idu (
    // Interfaces
    .wb_rd_i          ( wb2id_rd        ),
    .wb_rd_data_i     ( wb2id_rd_data   ),
    .rx_if            ( if2id_if.slave  ),
    .tx_if            ( id2ex_if.master ),
    // Inputs
    .clk              ( clk             ),
    .wb_rf_wb_en_i    ( wb2id_rf_wb_en  )
  );

  npc_exu u_exu (
    // Interfaces
    .ex_jump_o  ( ex2if_jump      ),
    .rx_if      ( id2ex_if.slave  ),
    .tx_if      ( ex2ls_if.master )
  );

  npc_lsu u_lsu (
     // Interfaces
    .m_mem_if   ( m_mem_if.master ),
    .rx_if      ( ex2ls_if.slave  ),
    .tx_if      ( ls2wb_if.master )
  );

  npc_wbu u_wbu (
    // Interfaces
    .rd_o             ( wb2id_rd         ),
    .rd_data_o        ( wb2id_rd_data    ),
    .csr_rdata_i      ( csr2wb_csr_rdata ),
    .csr_wdata_o      ( wb2csr_rs1_data  ),
    .csr_op_o         ( wb2csr_csr_op    ),
    .csr_wb_en_o      ( wb2csr_wb_en     ),
    .wb_pc_o          ( wb2csr_pc        ),
    .rx_if            ( ls2wb_if.slave   ),
    // Outputs
    .rf_wb_en_o       ( wb2id_rf_wb_en   ),
    .csr_addr_o       ( wb2csr_csr_addr  ),
    .ebreak_flag_o    ( ebreak_o         ),
    .wb_trap_valid_o  ( wb2if_trap_valid ),
    .wb_mret_valid_o  ( wb2if_mret_valid )
  );

  npc_csr u_csr (
    // Interfaces
    .pc_i          ( wb2csr_pc        ),
    .csr_addr_i    ( wb2csr_csr_addr  ),
    .rs1_data_i    ( wb2csr_rs1_data  ),
    .csr_op_i      ( wb2csr_csr_op    ),
    .csr_data_o    ( csr2wb_csr_rdata ),
    .mepc_o        ( csr2if_mret_pc   ),
    .mtvec_o       ( csr2if_trap_pc   ),
    // Inputs
    .clk           ( clk              ),
    .rst_n         ( rst_n            ),
    .wr_en_i       ( wb2csr_wb_en     ),
    .is_ecall_i    ( wb2if_trap_valid ),
    .is_mret_i     ( wb2if_mret_valid )
  );

  /* ================================ */
  /* ======= Bind DPI Probes ======== */
  /* ================================ */
  bind npc_ifu dpi_probe_pc u_dpi_probe_pc (
    // Interfaces
    .pc_i      ( pc       ),
    .dnpc_i    ( next_pc  )
  );

  bind npc_idu_regfile dpi_probe_gpr u_dpi_probe_gpr (
    // Interfaces
    .gpr_i     ( gpr/*.[0:`GPR_NUM-1]*/ )
  );

  bind npc_csr dpi_probe_csr u_dpi_probe_csr (
    // Interfaces
    .csr_i     ( csr )
  );

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
