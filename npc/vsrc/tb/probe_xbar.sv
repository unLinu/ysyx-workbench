module probe_xbar (
  input   logic                   arvalid           ,
  input   logic                   awvalid           ,
  input   logic                   rd_in_pmem        ,
  input   logic                   rd_in_uart        ,
  input   logic                   rd_in_clint       ,
  input   logic                   wr_in_pmem        ,
  input   logic                   wr_in_uart        ,
  input   logic                   wr_in_clint
);

  always_comb begin
    if (arvalid) begin
      a_raddr_decode_onehot0: assert($onehot0({rd_in_pmem, rd_in_uart, rd_in_clint}))
        else $fatal(1, "Error: Read address decode overlaps!");
    end

    if (awvalid) begin
      a_waddr_decode_onehot0: assert($onehot0({wr_in_pmem, wr_in_uart, wr_in_clint}))
        else $fatal(1, "Error: Write address decode overlaps!");
    end
  end

endmodule
