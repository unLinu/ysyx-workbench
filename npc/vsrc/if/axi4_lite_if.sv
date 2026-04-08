interface axi4_lite_if #(
  parameter   ADDR_WIDTH = 32             ,
  parameter   DATA_WIDTH = 32
)(
  // Global Signals
  input   logic               aclk        ,
  input   logic               aresetn
);
  // Write Address Channel
  logic   [ADDR_WIDTH-1:0]    awaddr      ;
  logic   [ 2:0]              awprot      ;
  logic                       awvalid     ;
  logic                       awready     ;
  // Write Data Channel
  logic   [DATA_WIDTH-1:0]    wdata       ;
  logic   [DATA_WIDTH/8-1:0]  wstrb       ;
  logic                       wvalid      ;
  logic                       wready      ;
  // Write Response Channel
  logic   [ 1:0]              bresp       ;
  logic                       bvalid      ;
  logic                       bready      ;
  // Read Address Channel
  logic   [ADDR_WIDTH-1:0]    araddr      ;
  logic   [ 2:0]              arprot      ;
  logic                       arvalid     ;
  logic                       arready     ;
  // Read Data Channel
  logic   [DATA_WIDTH-1:0]    rdata       ;
  logic   [ 1:0]              rresp       ;
  logic                       rvalid      ;
  logic                       rready      ;

  // Modports
  modport master (
    // Global Signals
    input   aclk, aresetn,
    // Write Address Channel
    input   awready,
    output  awaddr, awprot, awvalid,
    // Write Data Channel
    input   wready,
    output  wdata, wstrb, wvalid,
    // Write Response Channel
    input   bresp, bvalid,
    output  bready,
    // Read Address Channel
    input   arready,
    output  araddr, arprot, arvalid,
    // Read Data Channel
    input   rdata, rresp, rvalid,
    output  rready
  );

  modport slave (
    // Global Signals
    input   aclk, aresetn,
    // Write Address Channel
    output  awready,
    input   awaddr, awprot, awvalid,
    // Write Data Channel
    output  wready,
    input   wdata, wstrb, wvalid,
    // Write Response Channel
    output  bresp, bvalid,
    input   bready,
    // Read Address Channel
    output  arready,
    input   araddr, arprot, arvalid,
    // Read Data Channel
    output  rdata, rresp, rvalid,
    input   rready
  );

endinterface
