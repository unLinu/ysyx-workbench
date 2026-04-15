interface core_mem_if #(
  parameter   ADDR_WIDTH  = 32              ,
  parameter   DATA_WIDTH  = 32
);

  // +--------+                                                          +--------+
  // | Master | -- req_addr, req_data, req_wstrb --------------------->  | Slave  |
  // |        | -- req_is_write, req_valid --------------------------->  |        |
  // |        | <- req_ready -----------------------------------------   |        |
  // |        | <- rsp_data, rsp_err, rsp_valid ----------------------   |        |
  // |        | -- rsp_ready ----------------------------------------->  |        |
  // +--------+                                                          +--------+

  // Request Channel
  logic   [ADDR_WIDTH-1:0]    req_addr      ;
  logic   [DATA_WIDTH-1:0]    req_data      ;
  logic   [DATA_WIDTH/8-1:0]  req_wstrb     ;
  logic                       req_is_write  ;
  logic                       req_valid     ;
  logic                       req_ready     ;
  // Response Channel
  logic   [DATA_WIDTH-1:0]    rsp_data      ;
  logic                       rsp_err       ;
  logic                       rsp_valid     ;
  logic                       rsp_ready     ;

  // Modports
  modport master (
    // Request Channel
    input   req_ready,
    output  req_addr, req_data, req_wstrb, req_is_write, req_valid,
    // Response Channel
    input   rsp_data, rsp_err, rsp_valid,
    output  rsp_ready
  );

  modport slave (
    // Request Channel
    output  req_ready,
    input   req_addr, req_data, req_wstrb, req_is_write, req_valid,
    // Response Channel
    output  rsp_data, rsp_err, rsp_valid,
    input   rsp_ready
  );

endinterface
