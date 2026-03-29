interface mem_if;
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
endinterface
