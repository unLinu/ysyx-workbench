`include "npc_defines.svh"
module axi4_xbar (
  // interface
  axi4_if.slave              s_axi_if          ,
  axi4_if.master             m_uart_axi_if     ,
  axi4_if.master             m_clint_axi_if    ,
  axi4_if.master             m_sram_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // Address
  localparam    PMEM_BASE_ADDR  = `XLEN'h8000_0000              ;
  localparam    PMEM_SIZE       = `XLEN'h0800_0000              ;
  localparam    UART_BASE_ADDR  = `XLEN'ha000_03f8              ;
  localparam    UART_SIZE       = `XLEN'h0000_0008              ;
  localparam    CLINT_BASE_ADDR = `XLEN'ha000_0048              ;
  localparam    CLINT_SIZE      = `XLEN'h0000_0008              ;

  // Slaver select signals
  typedef enum logic [2:0] {
    NONE_SEL, UART_SEL, CLINT_SEL, SRAM_SEL, DECERR_SEL
  } slave_sel_e                                                 ;

  slave_sel_e         rd_sel_q, wr_sel_q                        ;

  // Internal signals
  logic   [ 3:0]      rd_id_q, wr_id_q                          ;
  logic               rd_in_pmem, rd_in_uart, rd_in_clint       ;
  logic               wr_in_pmem, wr_in_uart, wr_in_clint       ;
  logic               rd_in_other, wr_in_other                  ;
  logic               wr_decerr_data_done_q                     ;
  logic               ar_done, r_done, aw_done, w_done, b_done  ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // Address decoding
  assign  rd_in_pmem  = (s_axi_if.araddr >= PMEM_BASE_ADDR  && s_axi_if.araddr < PMEM_BASE_ADDR  + PMEM_SIZE);
  assign  rd_in_uart  = (s_axi_if.araddr >= UART_BASE_ADDR  && s_axi_if.araddr < UART_BASE_ADDR  + UART_SIZE);
  assign  rd_in_clint = (s_axi_if.araddr >= CLINT_BASE_ADDR && s_axi_if.araddr < CLINT_BASE_ADDR + CLINT_SIZE);
  assign  wr_in_pmem  = (s_axi_if.awaddr >= PMEM_BASE_ADDR  && s_axi_if.awaddr < PMEM_BASE_ADDR  + PMEM_SIZE);
  assign  wr_in_uart  = (s_axi_if.awaddr >= UART_BASE_ADDR  && s_axi_if.awaddr < UART_BASE_ADDR  + UART_SIZE);
  assign  wr_in_clint = (s_axi_if.awaddr >= CLINT_BASE_ADDR && s_axi_if.awaddr < CLINT_BASE_ADDR + CLINT_SIZE);

  // 其他地址映射到SRAM，方便调试设备
  assign  rd_in_other = ~(rd_in_pmem | rd_in_uart | rd_in_clint);
  assign  wr_in_other = ~(wr_in_pmem | wr_in_uart | wr_in_clint);

  //////////////////
  /* Read Channel */
  //////////////////
  assign  ar_done = s_axi_if.arvalid & s_axi_if.arready;
  assign  r_done  = s_axi_if.rvalid  & s_axi_if.rready;

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      rd_sel_q <= NONE_SEL;
    else if (ar_done) begin
      if (rd_in_pmem)
        rd_sel_q <= SRAM_SEL;
      else if (rd_in_uart)
        rd_sel_q <= UART_SEL;
      else if (rd_in_clint)
        rd_sel_q <= CLINT_SEL;
      else if (rd_in_other)
        rd_sel_q <= SRAM_SEL;
      else
        rd_sel_q <= DECERR_SEL;
    end
    else if (r_done)
      rd_sel_q <= NONE_SEL;
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      rd_id_q <= '0;
    else if (ar_done)
      rd_id_q <= s_axi_if.arid;
  end

  ///////////////////
  /* Write Channel */
  ///////////////////
  assign  aw_done = s_axi_if.awvalid & s_axi_if.awready;
  assign  w_done  = s_axi_if.wvalid  & s_axi_if.wready;
  assign  b_done  = s_axi_if.bvalid  & s_axi_if.bready;

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      wr_sel_q <= NONE_SEL;
    else if (aw_done) begin
      if (wr_in_pmem)
        wr_sel_q <= SRAM_SEL;
      else if (wr_in_uart)
        wr_sel_q <= UART_SEL;
      else if (wr_in_clint)
        wr_sel_q <= CLINT_SEL;
      else if (wr_in_other)
        wr_sel_q <= SRAM_SEL;
      else
        wr_sel_q <= DECERR_SEL;
    end
    else if (b_done)
      wr_sel_q <= NONE_SEL;
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      wr_id_q <= '0;
    else if (aw_done)
      wr_id_q <= s_axi_if.awid;
  end

  always_ff @(posedge s_axi_if.aclk or negedge s_axi_if.aresetn) begin
    if (~s_axi_if.aresetn)
      wr_decerr_data_done_q <= 1'b0;
    else if (wr_sel_q != DECERR_SEL)
      wr_decerr_data_done_q <= 1'b0;
    else if (w_done)
      wr_decerr_data_done_q <= 1'b1;
    else if (b_done)
      wr_decerr_data_done_q <= 1'b0;
  end

  /////////////////////////////
  /* Upstream <-> Downstream */
  /////////////////////////////
  always_comb begin
    s_axi_if.awready = 1'b0;
    s_axi_if.wready  = 1'b0;
    s_axi_if.bresp   = '0;
    s_axi_if.bid     = '0;
    s_axi_if.bvalid  = 1'b0;
    s_axi_if.arready = 1'b0;
    s_axi_if.rdata   = '0;
    s_axi_if.rresp   = '0;
    s_axi_if.rid     = '0;
    s_axi_if.rlast   = 1'b0;
    s_axi_if.rvalid  = 1'b0;

    m_uart_axi_if.awaddr  = '0;
    m_uart_axi_if.awprot  = '0;
    m_uart_axi_if.awid    = '0;
    m_uart_axi_if.awlen   = '0;
    m_uart_axi_if.awsize  = '0;
    m_uart_axi_if.awburst = '0;
    m_uart_axi_if.awvalid = 1'b0;
    m_uart_axi_if.wdata   = '0;
    m_uart_axi_if.wstrb   = '0;
    m_uart_axi_if.wlast   = 1'b0;
    m_uart_axi_if.wvalid  = 1'b0;
    m_uart_axi_if.bready  = 1'b0;
    m_uart_axi_if.araddr  = '0;
    m_uart_axi_if.arprot  = '0;
    m_uart_axi_if.arid    = '0;
    m_uart_axi_if.arlen   = '0;
    m_uart_axi_if.arsize  = '0;
    m_uart_axi_if.arburst = '0;
    m_uart_axi_if.arvalid = 1'b0;
    m_uart_axi_if.rready  = 1'b0;

    m_clint_axi_if.awaddr  = '0;
    m_clint_axi_if.awprot  = '0;
    m_clint_axi_if.awid    = '0;
    m_clint_axi_if.awlen   = '0;
    m_clint_axi_if.awsize  = '0;
    m_clint_axi_if.awburst = '0;
    m_clint_axi_if.awvalid = 1'b0;
    m_clint_axi_if.wdata   = '0;
    m_clint_axi_if.wstrb   = '0;
    m_clint_axi_if.wlast   = 1'b0;
    m_clint_axi_if.wvalid  = 1'b0;
    m_clint_axi_if.bready  = 1'b0;
    m_clint_axi_if.araddr  = '0;
    m_clint_axi_if.arprot  = '0;
    m_clint_axi_if.arid    = '0;
    m_clint_axi_if.arlen   = '0;
    m_clint_axi_if.arsize  = '0;
    m_clint_axi_if.arburst = '0;
    m_clint_axi_if.arvalid = 1'b0;
    m_clint_axi_if.rready  = 1'b0;

    m_sram_axi_if.awaddr  = '0;
    m_sram_axi_if.awprot  = '0;
    m_sram_axi_if.awid    = '0;
    m_sram_axi_if.awlen   = '0;
    m_sram_axi_if.awsize  = '0;
    m_sram_axi_if.awburst = '0;
    m_sram_axi_if.awvalid = 1'b0;
    m_sram_axi_if.wdata   = '0;
    m_sram_axi_if.wstrb   = '0;
    m_sram_axi_if.wlast   = 1'b0;
    m_sram_axi_if.wvalid  = 1'b0;
    m_sram_axi_if.bready  = 1'b0;
    m_sram_axi_if.araddr  = '0;
    m_sram_axi_if.arprot  = '0;
    m_sram_axi_if.arid    = '0;
    m_sram_axi_if.arlen   = '0;
    m_sram_axi_if.arsize  = '0;
    m_sram_axi_if.arburst = '0;
    m_sram_axi_if.arvalid = 1'b0;
    m_sram_axi_if.rready  = 1'b0;

    // Read request routing
    if (rd_in_pmem) begin
      m_sram_axi_if.araddr  = s_axi_if.araddr;
      m_sram_axi_if.arprot  = s_axi_if.arprot;
      m_sram_axi_if.arid    = s_axi_if.arid;
      m_sram_axi_if.arlen   = s_axi_if.arlen;
      m_sram_axi_if.arsize  = s_axi_if.arsize;
      m_sram_axi_if.arburst = s_axi_if.arburst;
      m_sram_axi_if.arvalid = s_axi_if.arvalid;
      s_axi_if.arready      = m_sram_axi_if.arready;
    end
    else if (rd_in_uart) begin
      m_uart_axi_if.araddr  = s_axi_if.araddr - UART_BASE_ADDR;
      m_uart_axi_if.arprot  = s_axi_if.arprot;
      m_uart_axi_if.arid    = s_axi_if.arid;
      m_uart_axi_if.arlen   = s_axi_if.arlen;
      m_uart_axi_if.arsize  = s_axi_if.arsize;
      m_uart_axi_if.arburst = s_axi_if.arburst;
      m_uart_axi_if.arvalid = s_axi_if.arvalid;
      s_axi_if.arready      = m_uart_axi_if.arready;
    end
    else if (rd_in_clint) begin
      m_clint_axi_if.araddr  = s_axi_if.araddr - CLINT_BASE_ADDR;
      m_clint_axi_if.arprot  = s_axi_if.arprot;
      m_clint_axi_if.arid    = s_axi_if.arid;
      m_clint_axi_if.arlen   = s_axi_if.arlen;
      m_clint_axi_if.arsize  = s_axi_if.arsize;
      m_clint_axi_if.arburst = s_axi_if.arburst;
      m_clint_axi_if.arvalid = s_axi_if.arvalid;
      s_axi_if.arready       = m_clint_axi_if.arready;
    end
    else if (rd_in_other) begin
      m_sram_axi_if.araddr  = s_axi_if.araddr;
      m_sram_axi_if.arprot  = s_axi_if.arprot;
      m_sram_axi_if.arid    = s_axi_if.arid;
      m_sram_axi_if.arlen   = s_axi_if.arlen;
      m_sram_axi_if.arsize  = s_axi_if.arsize;
      m_sram_axi_if.arburst = s_axi_if.arburst;
      m_sram_axi_if.arvalid = s_axi_if.arvalid;
      s_axi_if.arready      = m_sram_axi_if.arready;
    end

    // Read response routing
    unique case (rd_sel_q)
      UART_SEL: begin
        m_uart_axi_if.rready = s_axi_if.rready;
        s_axi_if.rdata       = m_uart_axi_if.rdata;
        s_axi_if.rresp       = m_uart_axi_if.rresp;
        s_axi_if.rid         = m_uart_axi_if.rid;
        s_axi_if.rlast       = m_uart_axi_if.rlast;
        s_axi_if.rvalid      = m_uart_axi_if.rvalid;
      end

      CLINT_SEL: begin
        m_clint_axi_if.rready = s_axi_if.rready;
        s_axi_if.rdata        = m_clint_axi_if.rdata;
        s_axi_if.rresp        = m_clint_axi_if.rresp;
        s_axi_if.rid          = m_clint_axi_if.rid;
        s_axi_if.rlast        = m_clint_axi_if.rlast;
        s_axi_if.rvalid       = m_clint_axi_if.rvalid;
      end

      SRAM_SEL: begin
        m_sram_axi_if.rready = s_axi_if.rready;
        s_axi_if.rdata       = m_sram_axi_if.rdata;
        s_axi_if.rresp       = m_sram_axi_if.rresp;
        s_axi_if.rid         = m_sram_axi_if.rid;
        s_axi_if.rlast       = m_sram_axi_if.rlast;
        s_axi_if.rvalid      = m_sram_axi_if.rvalid;
      end

      DECERR_SEL: begin
        s_axi_if.rdata       = '0;
        s_axi_if.rresp       = `AXI_DECERR;
        s_axi_if.rid         = rd_id_q;
        s_axi_if.rlast       = 1'b1;
        s_axi_if.rvalid      = 1'b1;
      end

      default: begin
      end
    endcase

    // Write address routing
    if (wr_in_pmem) begin
      m_sram_axi_if.awaddr  = s_axi_if.awaddr;
      m_sram_axi_if.awprot  = s_axi_if.awprot;
      m_sram_axi_if.awid    = s_axi_if.awid;
      m_sram_axi_if.awlen   = s_axi_if.awlen;
      m_sram_axi_if.awsize  = s_axi_if.awsize;
      m_sram_axi_if.awburst = s_axi_if.awburst;
      m_sram_axi_if.awvalid = s_axi_if.awvalid;
      s_axi_if.awready      = m_sram_axi_if.awready;
    end
    else if (wr_in_uart) begin
      m_uart_axi_if.awaddr  = s_axi_if.awaddr - UART_BASE_ADDR;
      m_uart_axi_if.awprot  = s_axi_if.awprot;
      m_uart_axi_if.awid    = s_axi_if.awid;
      m_uart_axi_if.awlen   = s_axi_if.awlen;
      m_uart_axi_if.awsize  = s_axi_if.awsize;
      m_uart_axi_if.awburst = s_axi_if.awburst;
      m_uart_axi_if.awvalid = s_axi_if.awvalid;
      s_axi_if.awready      = m_uart_axi_if.awready;
    end
    else if (wr_in_clint) begin
      m_clint_axi_if.awaddr  = s_axi_if.awaddr - CLINT_BASE_ADDR;
      m_clint_axi_if.awprot  = s_axi_if.awprot;
      m_clint_axi_if.awid    = s_axi_if.awid;
      m_clint_axi_if.awlen   = s_axi_if.awlen;
      m_clint_axi_if.awsize  = s_axi_if.awsize;
      m_clint_axi_if.awburst = s_axi_if.awburst;
      m_clint_axi_if.awvalid = s_axi_if.awvalid;
      s_axi_if.awready       = m_clint_axi_if.awready;
    end
    else if (wr_in_other) begin
      m_sram_axi_if.awaddr  = s_axi_if.awaddr;
      m_sram_axi_if.awprot  = s_axi_if.awprot;
      m_sram_axi_if.awid    = s_axi_if.awid;
      m_sram_axi_if.awlen   = s_axi_if.awlen;
      m_sram_axi_if.awsize  = s_axi_if.awsize;
      m_sram_axi_if.awburst = s_axi_if.awburst;
      m_sram_axi_if.awvalid = s_axi_if.awvalid;
      s_axi_if.awready      = m_sram_axi_if.awready;
    end

    // Write data/response routing
    unique case (wr_sel_q)
      UART_SEL: begin
        m_uart_axi_if.wdata  = s_axi_if.wdata;
        m_uart_axi_if.wstrb  = s_axi_if.wstrb;
        m_uart_axi_if.wlast  = s_axi_if.wlast;
        m_uart_axi_if.wvalid = s_axi_if.wvalid;
        m_uart_axi_if.bready = s_axi_if.bready;
        s_axi_if.wready      = m_uart_axi_if.wready;
        s_axi_if.bresp       = m_uart_axi_if.bresp;
        s_axi_if.bid         = m_uart_axi_if.bid;
        s_axi_if.bvalid      = m_uart_axi_if.bvalid;
      end

      CLINT_SEL: begin
        m_clint_axi_if.wdata  = s_axi_if.wdata;
        m_clint_axi_if.wstrb  = s_axi_if.wstrb;
        m_clint_axi_if.wlast  = s_axi_if.wlast;
        m_clint_axi_if.wvalid = s_axi_if.wvalid;
        m_clint_axi_if.bready = s_axi_if.bready;
        s_axi_if.wready       = m_clint_axi_if.wready;
        s_axi_if.bresp        = m_clint_axi_if.bresp;
        s_axi_if.bid          = m_clint_axi_if.bid;
        s_axi_if.bvalid       = m_clint_axi_if.bvalid;
      end

      SRAM_SEL: begin
        m_sram_axi_if.wdata  = s_axi_if.wdata;
        m_sram_axi_if.wstrb  = s_axi_if.wstrb;
        m_sram_axi_if.wlast  = s_axi_if.wlast;
        m_sram_axi_if.wvalid = s_axi_if.wvalid;
        m_sram_axi_if.bready = s_axi_if.bready;
        s_axi_if.wready      = m_sram_axi_if.wready;
        s_axi_if.bresp       = m_sram_axi_if.bresp;
        s_axi_if.bid         = m_sram_axi_if.bid;
        s_axi_if.bvalid      = m_sram_axi_if.bvalid;
      end

      DECERR_SEL: begin
        s_axi_if.wready      = ~wr_decerr_data_done_q;
        s_axi_if.bresp       = `AXI_DECERR;
        s_axi_if.bid         = wr_id_q;
        s_axi_if.bvalid      = wr_decerr_data_done_q;
      end

      default: begin
      end
    endcase
  end

endmodule
