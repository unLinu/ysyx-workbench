module dpi_sim_imem (
  axi4_lite_if.slave            s_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // DPI-C function declarations
  import "DPI-C" function int mem_read (input int raddr);

  // handshake success
  logic         ar_done     ;
  logic         r_done      ;

  // FSM state definition
  typedef enum logic [1:0] {
    R_WAIT_REQ, R_SEND_RSP
  } r_state_e ;

  r_state_e     r_state, r_next_state ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  //////////////////
  /* State Update */
  //////////////////
  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      r_state <= R_WAIT_REQ;
    else
      r_state <= r_next_state;
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

  //////////////////////////
  /* Read Address Channel */
  //////////////////////////
  assign  s_axi_if.arready = (r_state == R_WAIT_REQ);
  assign  ar_done = s_axi_if.arvalid & s_axi_if.arready;

  ///////////////////////
  /* Read Data Channel */
  ///////////////////////
  assign  r_done = s_axi_if.rvalid & s_axi_if.rready;

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      s_axi_if.rdata <= '0;
      s_axi_if.rresp <= '0;
      s_axi_if.rvalid <= 1'b0;
    end
    else if (ar_done) begin
      s_axi_if.rdata <= mem_read(s_axi_if.araddr);
      s_axi_if.rresp <= '0;
      s_axi_if.rvalid <= 1'b1;
    end
    else if (r_done) begin
      s_axi_if.rvalid <= 1'b0;
    end
  end

endmodule
