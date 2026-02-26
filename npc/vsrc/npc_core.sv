`include "npc_defines.svh"
module npc_core import npc_pkg::*; (
    input   logic                       clk         ,
    input   logic                       rst_n       ,

    input   npc_pkg::word_t             inst_i      ,   
    output  npc_pkg::word_t             pc_o        ,    
    
    // Assertion
    output  logic                       inst_err    ,

    // Trap
    output  logic                       trap_o      
);

`include "npc_dpi.svh"

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    npc_pkg::pc_update_t        pc_op       ;   // idu -> ifu
    npc_pkg::alu_op_t           alu_op      ;   // idu -> alu
    npc_pkg::imm_op_t           imm_op      ;   // idu -> imm_gen
    npc_pkg::wb_src_t           wb_src      ;   // idu -> regfile_mux
    npc_pkg::alu_sel_t          alu_sel     ;   // idu -> alu_mux
    npc_pkg::ld_op_t            ld_op       ;   // idu -> ld_mux
    npc_pkg::st_op_t            st_op       ;   // idu -> st_mux
    npc_pkg::csr_op_t           csr_op      ;   // idu -> csr

    npc_pkg::word_t             imm         ;   // imm_gen -> ifu alu_mux regfile_mux   
    npc_pkg::word_t             alu_src1    ;   // regfile -> alu
    npc_pkg::word_t             alu_src2    ;   // regfile imm_gen -> alu
    npc_pkg::word_t             alu_res     ;   // alu -> ifu 
 
    npc_pkg::regid_t            rs1         ;   // idu -> alu
    npc_pkg::regid_t            rs2         ;   // idu -> alu
    npc_pkg::regid_t            rd          ;   // idu -> regfile
    npc_pkg::word_t             rs1_data    ;   // regfile -> alu_mux 
    npc_pkg::word_t             rs2_data    ;   // regfile -> alu_mux
    npc_pkg::word_t             rd_data     ;   // mem alu ifu -> regfile
    npc_pkg::word_t             mem_rdata   ;   // memory -> regfile_mux
    npc_pkg::word_t             mem_wdata   ;   // regfile -> memory
    npc_pkg::word_t             mem_rd_tmp  ;
    npc_pkg::word_t             mem_raddr   ;
    npc_pkg::word_t             mem_waddr   ;
    npc_pkg::word_t             csr_data    ;   // csr -> regfile_mux
    npc_pkg::word_t             mepc        ;   // csr -> ifu
    npc_pkg::word_t             mtvec       ;   // csr -> ifu

    npc_pkg::word_t             snpc        ;   // ifu -> regfile_mux
    logic                       ecall       ;   // idu -> csr
    logic                       mret        ;   // idu -> csr

    logic                       rf_en       ;   // idu -> regfile
    logic                       csr_en      ;   // idu -> csr
    logic                       mem_rden    ;   // idu -> memory
    logic                       mem_wren    ;   // idu -> memory
    logic   [ 7:0]              mem_wlen    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    /////////////
    /* alu_mux */
    /////////////
    always_comb begin
        unique case (alu_sel)
            ALU_RS: begin
                alu_src1 = rs1_data     ; 
                alu_src2 = rs2_data     ;
            end
            ALU_IMM: begin
                alu_src1 = rs1_data     ;
                alu_src2 = imm          ;
            end
            ALU_PC_IMM: begin               // auipc
                alu_src1 = pc_o         ;
                alu_src2 = imm          ;
            end
        endcase
    end

    /////////////////
    /* regfile mux */
    /////////////////
    always_comb begin
        unique case (wb_src)
            WB_ALU:  rd_data = alu_res   ;
            WB_IMM:  rd_data = imm       ;
            WB_IFU:  rd_data = snpc      ; 
            WB_MEM:  rd_data = mem_rdata ;
            WB_CSR:  rd_data = csr_data  ;
            default: rd_data = `XLEN'd0  ;
        endcase
    end
    
    ///////////////////
    /* load data mux */
    ///////////////////
    
    assign mem_raddr = alu_res                                          ;
    // Just for verilator
    always_ff @(negedge clk) begin : Simulation
      if (mem_rden)
        mem_rd_tmp <= npc_pmem_read(mem_raddr);
    end

    always_comb begin
        unique case (ld_op)
            LD_B:  mem_rdata = {{24{mem_rd_tmp[7]}}, mem_rd_tmp[7:0]}   ;
            LD_H:  mem_rdata = {{16{mem_rd_tmp[15]}}, mem_rd_tmp[15:0]} ;
            LD_W:  mem_rdata = mem_rd_tmp                               ;
            LD_BU: mem_rdata = {24'd0, mem_rd_tmp[7:0]}                 ;
            LD_HU: mem_rdata = {16'd0, mem_rd_tmp[15:0]}                ;
            default: mem_rdata = `XLEN'd0                               ;
        endcase
    end
   
    ////////////////////
    /* store data mux */
    ////////////////////
    
    assign mem_waddr = alu_res  ;
    assign mem_wdata = rs2_data ;

    always_ff @(posedge clk) begin
        if (mem_wren) begin
            npc_pmem_write(mem_waddr, mem_wdata, mem_wlen);
        end
    end
    
    always_comb begin
        unique case (st_op)
            ST_B: mem_wlen = 8'd1      ;
            ST_H: mem_wlen = 8'd2      ;
            ST_W: mem_wlen = 8'd4      ;
        endcase
    end

    /////////////////
    /* EBREAK TRAP */
    /////////////////
    always_comb begin
        if (trap_o) begin
            npc_trap();
        end
    end


/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

    ifu u_ifu (
        .clk       	(clk        ),
        .rst_n     	(rst_n      ),
        .pc_op_i   	(pc_op      ),
        .imm_i     	(imm        ),
        .alu_res_i 	(alu_res    ),
        .mepc_i    	(mepc       ),
        .mtvec_i   	(mtvec      ),
        .pc_o      	(pc_o       ),
        .snpc_o    	(snpc       )
    );

    idu u_idu (
        .inst_i    	(inst_i     ),
        .rs1_o     	(rs1        ),
        .rs2_o     	(rs2        ),
        .rd_o      	(rd         ),
        .alu_op_o  	(alu_op     ),
        .imm_op_o  	(imm_op     ),
        .wb_src_o  	(wb_src     ),
        .alu_sel_o 	(alu_sel    ),
        .ld_op_o   	(ld_op      ),
        .st_op_o   	(st_op      ),
        .csr_op_o  	(csr_op     ),
        .mem_rden_o (mem_rden   ),
        .mem_wren_o (mem_wren   ),
        .rf_en_o    (rf_en      ),
        .csr_en_o   (csr_en     ),
        .pc_next   	(pc_op      ),
        .inst_err  	(inst_err   ),
        .ebreak_o   (trap_o     ),
        .ecall_o    (ecall      ),
        .mret_o     (mret       )
    );

    imm_gen u_imm_gen (
        .imm_op_i 	(imm_op    ),
        .inst_i   	(inst_i    ),
        .imm_o    	(imm       )
    );
    
    alu u_alu (
        .alu_op_i  	(alu_op     ),
        .src1_i    	(alu_src1   ),
        .src2_i    	(alu_src2   ),
        .alu_res_o 	(alu_res    )
    );
    
    regfile u_regfile (
        .clk        	(clk         ),
        .rs1_i      	(rs1         ),
        .rs2_i      	(rs2         ),
        .rd_i       	(rd          ),
        .wr_en_i    	(rf_en       ),
        .rd_data_i  	(rd_data     ),
        .rs1_data_o 	(rs1_data    ),
        .rs2_data_o 	(rs2_data    )
    );
    
    csr u_csr(
        .clk        	(clk         ),
        .rst_n      	(rst_n       ),
        .pc_i       	(pc_o        ),
        .csr_addr_i 	(imm[11:0]   ),
        .rs1_data_i 	(rs1_data    ),
        .wr_en_i    	(csr_en      ),
        .csr_op_i   	(csr_op      ),
        .ecall_i    	(ecall       ),
        .mret_i     	(mret        ),
        .csr_data_o 	(csr_data    ),
        .mepc_o     	(mepc        ),
        .mtvec_o    	(mtvec       )
    );
    
endmodule
