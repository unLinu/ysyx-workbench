`include "npc_defines.svh"
module npc_ifu import isa_pkg::PC_RST; #(
  parameter ARCH = "SINGLE"
)(
  // system signals
  input   logic                       clk             ,
  input   logic                       rst_n           ,
  // forward path
  input   bypass_pkg::pc_fwd_t        ex_jump_i       ,   // branch, jump
  input   bypass_pkg::pc_fwd_t        wb_trap_i       ,   // ecall
  input   bypass_pkg::pc_fwd_t        wb_mret_i       ,   // mret
  // inst mem access
  input   isa_pkg::word_t             inst_i          ,
  output  isa_pkg::word_t             pc_o            ,

  // interface
  handshake_if.master                 tx_if               // ifu -> idu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // interface data
  pipeline_pkg::if2id_data_t      tx_data     ;

  // PC Register
  isa_pkg::word_t                 pc          ;

  // internal signals
  isa_pkg::word_t                 snpc        ;   // static next pc
  isa_pkg::word_t                 next_pc     ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // handshake
  generate
    if (ARCH == "SINGLE") begin: g_single_arch
      assign tx_if.valid  = 1'b1              ;
    end
  endgenerate

  assign  snpc            = pc + `XLEN'd4     ;
  assign  pc_o            = pc                ;
  assign  tx_if.data_pkg  = tx_data           ;   // packing

  // --------------------------- tx drive begin ---------------------------
  assign  tx_data = '{
    pc                    : pc                ,
    inst                  : inst_i            ,
    default               : '0
  };
  // --------------------------- tx drive end -----------------------------

  /* PC Register */
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      pc <= PC_RST  ;
    else
      pc <= next_pc ;
  end

  /* PC MUX */
  always_comb begin
    if (wb_trap_i.valid)
      next_pc = wb_trap_i.pc    ;
    else if (wb_mret_i.valid)
      next_pc = wb_mret_i.pc    ;
    else if (ex_jump_i.valid)
      next_pc = ex_jump_i.pc    ;
    else
      next_pc = snpc            ;
  end

endmodule
