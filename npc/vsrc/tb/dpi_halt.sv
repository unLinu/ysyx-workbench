module dpi_halt (
  input   logic               ebreak_i
);

  import "DPI-C" function void halt ();

  always_comb begin
    if (ebreak_i) begin
      halt();
    end
  end

endmodule
