`include "npc_defines.svh"
module npc_ifu import isa_pkg::PC_RST; (
  // system signals
  input   logic                       clk             ,
  input   logic                       rst_n           ,
  // forward path
  input   bypass_pkg::pc_fwd_t        ex_jump_i       ,   // branch, jump
  input   bypass_pkg::pc_fwd_t        wb_trap_i       ,   // ecall
  input   bypass_pkg::pc_fwd_t        wb_mret_i       ,   // mret
  // inst mem access
  input   logic                       inst_valid_i    ,
  input   isa_pkg::word_t             inst_i          ,
  output  isa_pkg::word_t             pc_o            ,
  output  logic                       ifetch_req_o    ,

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

  // FSM state
  typedef enum logic [1:0] {
    IF_REQ, IF_FETCH, IF_IDLE
  } if_state_e ;

  if_state_e                      state       ;
  if_state_e                      next_state  ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // handshake
  assign  tx_if.valid     = inst_valid_i & (state == IF_FETCH)      ;

  assign  snpc            = pc + `XLEN'd4                           ;
  assign  pc_o            = pc                                      ;
  assign  tx_if.data_pkg  = tx_data                                 ;   // packing

  assign  ifetch_req_o    = (state == IF_REQ)                       ;

  // --------------------------- tx drive begin ---------------------------
  assign  tx_data = '{
    pc                    : pc                ,
    inst                  : inst_i            ,
    default               : '0
  };
  // --------------------------- tx drive end -----------------------------

  /* ----- FSM Start ----- */
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= IF_IDLE    ;
    else
      state <= next_state ;
  end

  always_comb begin
    unique case (state)
      IF_IDLE : next_state = IF_REQ                                           ;
      IF_REQ  : next_state = IF_FETCH                                         ;
      IF_FETCH: next_state = inst_valid_i && tx_if.ready ? IF_REQ : IF_FETCH  ;
      default : next_state = IF_IDLE                                          ;
    endcase
  end
  /* ----- FSM End ------- */

  /* PC Register */
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      pc <= PC_RST  ;
    else if ((state == IF_FETCH) && inst_valid_i && tx_if.ready)
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
