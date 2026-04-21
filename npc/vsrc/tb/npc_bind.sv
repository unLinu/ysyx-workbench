module npc_bind;

bind npc_ifu dpi_probe_pc u_dpi_probe_pc (
  .pc_i   ( pc        ),
  .dnpc_i ( next_pc   )
);

bind npc_idu_regfile dpi_probe_gpr u_dpi_probe_gpr (
  // Interfaces
  .gpr_i  ( gpr/*.[0:`GPR_NUM-1]*/)
);

bind npc_csr dpi_probe_csr u_dpi_probe_csr (
  .csr_i  ( csr       )
);

bind npc_wbu dpi_probe_wbu u_dpi_probe_wbu (
  .wbu_inst_i         ( rx_data.inst    ),
  .wbu_commit_valid_i ( commit_valid_o  )
);

bind axi4_lite_master probe_axi_master u_probe_axi_master (
  // Inputs
  .bvalid    ( m_axi_if.bvalid  ),
  .rvalid    ( m_axi_if.rvalid  ),
  .bresp     ( m_axi_if.bresp   ),
  .rresp     ( m_axi_if.rresp   )
);

bind axi4_lite_xbar probe_xbar u_probe_xbar (
  // Inputs
  .arvalid      ( s_axi_if.arvalid ),
  .awvalid      ( s_axi_if.awvalid ),
  .rd_in_pmem   ( rd_in_pmem       ),
  .rd_in_uart   ( rd_in_uart       ),
  .rd_in_clint  ( rd_in_clint      ),
  .wr_in_pmem   ( wr_in_pmem       ),
  .wr_in_uart   ( wr_in_uart       ),
  .wr_in_clint  ( wr_in_clint      )
);

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
