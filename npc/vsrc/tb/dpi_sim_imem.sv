module dpi_sim_imem (
  input   logic                 clk             ,
  input   logic                 rst_n           ,
  input   logic                 rd_en_i         ,
  input   isa_pkg::word_t       pc_i            ,
  output  isa_pkg::word_t       inst_o          ,
  output  logic                 inst_valid_o
);

  // DPI-C function declarations
  import "DPI-C" function int mem_read (input int raddr, input byte rlen);

  // SRAM simulation
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      inst_o       <= '0;
      inst_valid_o <= 1'b0;
    end
    else if (rd_en_i) begin
      inst_o       <= mem_read(pc_i, 8'd4);
      inst_valid_o <= 1'b1;
    end
  end

endmodule
