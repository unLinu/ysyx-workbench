`include "npc_defines.svh"
module clint (
  // interface
  axi4_lite_if.slave          s_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  import "DPI-C" function void difftest_set_skip();

  // MTIME Register
  logic   [63:0]  mtime       ; // Machine Time Register (read-only)

  // handshake success
  logic         ar_done       ;
  logic         r_done        ;
  logic         aw_done       ;
  logic         w_done        ;
  logic         b_done        ;
  logic         aw_w_all_done ;
  logic         aw_get_q      ;
  logic         w_get_q       ;

  // FSM state definition
  typedef enum logic [1:0] {
    R_WAIT_REQ, R_SEND_RSP
  } r_state_e ;

  typedef enum logic [1:0] {
    W_WAIT_REQ, W_SEND_RSP
  } w_state_e ;

  r_state_e     r_state, r_next_state ;
  w_state_e     w_state, w_next_state ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  ////////////////////
  /* MTIME Register */
  ////////////////////
  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      mtime <= '0;
    else
      mtime <= mtime + 64'd1;
  end

  //////////////////
  /* State Update */
  //////////////////
  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      r_state <= R_WAIT_REQ;
      w_state <= W_WAIT_REQ;
    end
    else begin
      r_state <= r_next_state;
      w_state <= w_next_state;
    end
  end

  //////////////////
  /* State Switch */
  //////////////////
  always_comb begin
    unique case (r_state)
      R_WAIT_REQ: r_next_state = ar_done ? R_SEND_RSP : R_WAIT_REQ;
      R_SEND_RSP: r_next_state = r_done  ? R_WAIT_REQ : R_SEND_RSP;
      default:    r_next_state = R_WAIT_REQ;
    endcase
  end

  always_comb begin
    unique case (w_state)
      W_WAIT_REQ: w_next_state = aw_w_all_done ? W_SEND_RSP : W_WAIT_REQ;
      W_SEND_RSP: w_next_state = b_done        ? W_WAIT_REQ : W_SEND_RSP;
      default:    w_next_state = W_WAIT_REQ;
    endcase
  end

  ///////////////////
  /* Write Channel */
  ///////////////////
  assign  s_axi_if.awready = (w_state == W_WAIT_REQ);
  assign  s_axi_if.wready  = (w_state == W_WAIT_REQ);
  assign  aw_done = s_axi_if.awvalid & s_axi_if.awready;
  assign  w_done = s_axi_if.wvalid & s_axi_if.wready;
  assign  b_done = s_axi_if.bvalid & s_axi_if.bready;
  assign  aw_w_all_done = (aw_done && w_done) || (aw_get_q && w_get_q) || (aw_done && w_get_q) || (aw_get_q && w_done);

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      aw_get_q <= 1'b0;
    end
    else if (aw_w_all_done) begin
      aw_get_q <= 1'b0;
    end
    else if (aw_done) begin
      aw_get_q <= 1'b1;
    end
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      w_get_q <= 1'b0;
    end
    else if (aw_w_all_done) begin
      w_get_q <= 1'b0;
    end
    else if (w_done) begin
      w_get_q <= 1'b1;
    end
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      s_axi_if.bresp  <= '0;
      s_axi_if.bvalid <= 1'b0;
    end
    else if (aw_w_all_done) begin
      $display("MTIME Register is not writable!");
      s_axi_if.bresp  <= `AXI_SLVERR;
      s_axi_if.bvalid <= 1'b1;
    end
    else if (b_done) begin
      s_axi_if.bvalid <= 1'b0;
    end
  end

  //////////////////
  /* Read Channel */
  //////////////////
  assign  s_axi_if.arready = (r_state == R_WAIT_REQ);
  assign  ar_done = s_axi_if.arvalid & s_axi_if.arready;
  assign  r_done = s_axi_if.rvalid & s_axi_if.rready;

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      s_axi_if.rdata  <= '0;
      s_axi_if.rresp  <= '0;
      s_axi_if.rvalid <= 1'b0;
    end
    else if (ar_done) begin
      s_axi_if.rdata  <= s_axi_if.araddr == '0 ? mtime[31:0] : (s_axi_if.araddr == `XLEN'd4 ? mtime[63:32] : '0);
      s_axi_if.rresp  <= s_axi_if.araddr == '0 || s_axi_if.araddr == `XLEN'd4 ? `AXI_OKAY : `AXI_SLVERR;
      difftest_set_skip();
      s_axi_if.rvalid <= 1'b1;
    end
    else if (r_done) begin
      s_axi_if.rvalid <= 1'b0;
    end
  end

endmodule
