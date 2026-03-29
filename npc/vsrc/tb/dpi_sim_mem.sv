module dpi_sim_mem (
  input   logic               clk             ,

  // interface
  mem_if.slave                s_mem_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // DPI-C function declarations
  import "DPI-C" function int mem_read (input int raddr, input byte rlen);
  import "DPI-C" function void mem_write (input int waddr, input int wdata, input byte wlen);

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  always_ff @(posedge clk) begin: DPI_MEM_WR
    if (s_mem_if.wr_en) begin
      mem_write(s_mem_if.addr, s_mem_if.wr_data, s_mem_if.wlen);
    end
  end

  always_ff @(negedge clk) begin : DPI_MEM_RD
    if (s_mem_if.rd_en) begin
      s_mem_if.rd_data <= mem_read(s_mem_if.addr, s_mem_if.rlen);
    end
  end


endmodule
