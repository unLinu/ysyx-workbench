module dpi_sim_sram (
  // interface
  axi4_if.slave          s_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // DPI-C function declarations
  import "DPI-C" function int mem_read (input int raddr);
  import "DPI-C" function void mem_write (input int waddr, input int wdata, input byte wstrb);

  logic   [31:0]  awaddr_q ;
  logic   [ 3:0]  awid_q   ;
  logic   [31:0]  wdata_q  ;
  logic   [ 3:0]  wstrb_q  ;

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
      awaddr_q <= '0;
      awid_q   <= '0;
    end
    else if (aw_w_all_done) begin
      aw_get_q <= 1'b0;
    end
    else if (aw_done) begin
      aw_get_q <= 1'b1;
      awaddr_q <= s_axi_if.awaddr;
      awid_q   <= s_axi_if.awid;
    end
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      w_get_q <= 1'b0;
      wdata_q <= '0;
      wstrb_q <= '0;
    end
    else if (aw_w_all_done) begin
      w_get_q <= 1'b0;
    end
    else if (w_done) begin
      w_get_q <= 1'b1;
      wdata_q <= s_axi_if.wdata;
      wstrb_q <= s_axi_if.wstrb;
    end
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn) begin
      s_axi_if.bresp  <= '0;
      s_axi_if.bid    <= '0;
      s_axi_if.bvalid <= 1'b0;
    end
    else if (aw_w_all_done) begin
      mem_write(aw_get_q ? awaddr_q : s_axi_if.awaddr,
                w_get_q ? wdata_q : s_axi_if.wdata,
                byte'(w_get_q ? {4'b0, wstrb_q} : {4'b0, s_axi_if.wstrb}));
      s_axi_if.bresp  <= '0;
      s_axi_if.bid    <= aw_get_q ? awid_q : s_axi_if.awid;
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
      s_axi_if.rid    <= '0;
      s_axi_if.rlast  <= 1'b0;
      s_axi_if.rvalid <= 1'b0;
    end
    else if (ar_done) begin
      s_axi_if.rdata  <= mem_read(s_axi_if.araddr);
      s_axi_if.rresp  <= '0;
      s_axi_if.rid    <= s_axi_if.arid;
      s_axi_if.rlast  <= 1'b1;
      s_axi_if.rvalid <= 1'b1;
    end
    else if (r_done) begin
      s_axi_if.rvalid <= 1'b0;
    end
  end

endmodule
