module npc_yosys_top (
  input   logic         clk,
  input   logic         rst_n,

  output  logic [31:0]  o_mem_axi_awaddr,
  output  logic [ 2:0]  o_mem_axi_awprot,
  output  logic         o_mem_axi_awvalid,
  input   logic         o_mem_axi_awready,

  output  logic [31:0]  o_mem_axi_wdata,
  output  logic [ 3:0]  o_mem_axi_wstrb,
  output  logic         o_mem_axi_wvalid,
  input   logic         o_mem_axi_wready,

  input   logic [ 1:0]  o_mem_axi_bresp,
  input   logic         o_mem_axi_bvalid,
  output  logic         o_mem_axi_bready,

  output  logic [31:0]  o_mem_axi_araddr,
  output  logic [ 2:0]  o_mem_axi_arprot,
  output  logic         o_mem_axi_arvalid,
  input   logic         o_mem_axi_arready,

  input   logic [31:0]  o_mem_axi_rdata,
  input   logic [ 1:0]  o_mem_axi_rresp,
  input   logic         o_mem_axi_rvalid,
  output  logic         o_mem_axi_rready,

  output  logic         ebreak_o
);

  axi4_lite_if o_mem_axi_if (
    .aclk     ( clk   ),
    .aresetn  ( rst_n )
  );

  assign o_mem_axi_awaddr       = o_mem_axi_if.awaddr;
  assign o_mem_axi_awprot       = o_mem_axi_if.awprot;
  assign o_mem_axi_awvalid      = o_mem_axi_if.awvalid;
  assign o_mem_axi_if.awready   = o_mem_axi_awready;

  assign o_mem_axi_wdata        = o_mem_axi_if.wdata;
  assign o_mem_axi_wstrb        = o_mem_axi_if.wstrb;
  assign o_mem_axi_wvalid       = o_mem_axi_if.wvalid;
  assign o_mem_axi_if.wready    = o_mem_axi_wready;

  assign o_mem_axi_if.bresp     = o_mem_axi_bresp;
  assign o_mem_axi_if.bvalid    = o_mem_axi_bvalid;
  assign o_mem_axi_bready       = o_mem_axi_if.bready;

  assign o_mem_axi_araddr       = o_mem_axi_if.araddr;
  assign o_mem_axi_arprot       = o_mem_axi_if.arprot;
  assign o_mem_axi_arvalid      = o_mem_axi_if.arvalid;
  assign o_mem_axi_if.arready   = o_mem_axi_arready;

  assign o_mem_axi_if.rdata     = o_mem_axi_rdata;
  assign o_mem_axi_if.rresp     = o_mem_axi_rresp;
  assign o_mem_axi_if.rvalid    = o_mem_axi_rvalid;
  assign o_mem_axi_rready       = o_mem_axi_if.rready;

  npc_core u_core (
    .clk          ( clk         ),
    .rst_n        ( rst_n       ),
    .o_mem_axi_if ( o_mem_axi_if ),
    .ebreak_o     ( ebreak_o    )
  );

endmodule
