`include "npc_defines.svh"
module npc_ifu import isa_pkg::PC_RST; (
  // system signals
  input   logic                       clk             ,
  input   logic                       rst_n           ,
  // forward path
  input   bypass_pkg::pc_fwd_t        ex_jump_i       ,   // branch, jump
  input   bypass_pkg::pc_fwd_t        wb_trap_i       ,   // ecall
  input   bypass_pkg::pc_fwd_t        wb_mret_i       ,   // mret
  // interface
  core_mem_if.master                  ifetch_if       ,   // ifetch interface
  handshake_if.master                 tx_if               // ifu -> idu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // interface data
  pipeline_pkg::if2id_data_t      tx_data     ;

  // PC Register
  isa_pkg::word_t                 pc          ;
  isa_pkg::word_t                 next_pc     ;

  // Internal signals
  logic                           ifetch_done ;
  logic                           req_done    ;
  logic                           tx_done     ;

  // FSM state definition
  typedef enum logic [0:0] {
    IF_REQ, IF_FETCH
  } if_state_e ;

  if_state_e                      state       ;
  if_state_e                      next_state  ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  ///////////////////////////////
  /* pipeline control and data */
  ///////////////////////////////
  assign  tx_done = tx_if.valid & tx_if.ready                       ;
  assign  tx_if.valid = ifetch_done                                 ;
  assign  tx_if.data_pkg  = tx_data                                 ;   // packing
  assign  tx_data = '{
    pc                    : pc                    ,
    inst                  : ifetch_if.rsp_data    ,
    default               : '0
  };


  ///////////////
  /* ifetch_if */
  ///////////////
  assign  ifetch_done = ifetch_if.rsp_valid & ~ifetch_if.rsp_err    ;
  // Request Channel
  assign  req_done = ifetch_if.req_valid & ifetch_if.req_ready      ;
  assign  ifetch_if.req_addr  = pc                                  ;
  assign  ifetch_if.req_data  = '0                                  ;
  assign  ifetch_if.req_wstrb = '0                                  ;
  assign  ifetch_if.req_is_write = 1'b0                             ;
  assign  ifetch_if.req_valid = (state == IF_REQ)                   ;
  // Response Channel
  assign  ifetch_if.rsp_ready = tx_if.ready                         ;

  //                      req_done
  // +--------+  ------------------------>  +----------+
  // | IF_REQ |                             | IF_FETCH |
  // +--------+  <------------------------  +----------+
  //                      tx_done

  ///////////////////////////
  /* ----- FSM Start ----- */
  ///////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= IF_REQ     ;
    else
      state <= next_state ;
  end

  always_comb begin
    unique case (state)
      IF_REQ  : next_state = req_done ? IF_FETCH : IF_REQ           ;
      IF_FETCH: next_state = tx_done  ? IF_REQ   : IF_FETCH         ;
      default : next_state = IF_REQ                                 ;
    endcase
  end

  /////////////////
  /* PC Register */
  /////////////////
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      pc <= PC_RST  ;
    else if (tx_done)
      pc <= next_pc ;
  end

  ////////////
  /* PC MUX */
  ////////////
  always_comb begin
    if (wb_trap_i.valid)
      next_pc = wb_trap_i.pc    ;
    else if (wb_mret_i.valid)
      next_pc = wb_mret_i.pc    ;
    else if (ex_jump_i.valid)
      next_pc = ex_jump_i.pc    ;
    else
      next_pc = pc + `XLEN'd4   ;
  end

endmodule
