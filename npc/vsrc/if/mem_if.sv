interface mem_if (
  input   logic         clk       ,
  input   logic         rst_n
);
  logic                 rd_en     ;
  logic                 wr_en     ;
  logic   [ 7:0]        rlen      ;
  logic   [ 7:0]        wlen      ;
  isa_pkg::word_t       rd_data   ;
  isa_pkg::word_t       wr_data   ;
  isa_pkg::word_t       addr      ;

  modport master (
    input   rd_data,
    output  addr,
    output  rd_en, wr_en,
    output  wr_data,
    output  wlen, rlen
  );

  modport slave (
    output  rd_data,
    input   addr,
    input   rd_en, wr_en,
    input   wr_data,
    input   wlen, rlen
  );

  // Property
  /* verilator lint_off SYNCASYNCNET */
  property p_rden_one_pulse;
    @(posedge clk) disable iff (~rst_n)
      rd_en |=> !rd_en;
  endproperty

  property p_wren_one_pulse;
    @(posedge clk) disable iff (~rst_n)
      wr_en |=> !wr_en;
  endproperty
  /* verilator lint_on SYNCASYNCNET */

  // Assertion
  ap_rden_one_pulse: assert property (p_rden_one_pulse) else $warning("rd_en should be one pulse");
  ap_wren_one_pulse: assert property (p_wren_one_pulse) else $warning("wr_en should be one pulse");

endinterface
