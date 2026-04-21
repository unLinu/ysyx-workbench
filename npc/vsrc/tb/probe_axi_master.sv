module probe_axi_master (
  input   logic                 bvalid      ,
  input   logic                 rvalid      ,
  input   logic   [ 1:0]        bresp       ,
  input   logic   [ 1:0]        rresp
);

  always_comb begin
    if (bvalid)
      assert(bresp == 2'b00) else $fatal(1, "AXI bresp is not OKAY: %b", bresp);
  end

  always_comb begin
    if (rvalid)
      assert(rresp == 2'b00) else $fatal(1, "AXI rresp is not OKAY: %b", rresp);
  end

endmodule
