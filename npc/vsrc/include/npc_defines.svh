`ifndef __NPC_DEFINES_SVH__

`define __NPC_DEFINES_SVH__ 
`define XLEN 32
`define RLEN 5 
`define GPR_NUM 32 

// ysyxSoC address map
`define CLINT_BASE               `XLEN'h0200_0000
`define CLINT_SIZE               `XLEN'h0001_0000
`define SRAM_BASE                `XLEN'h0f00_0000
`define SRAM_SIZE                `XLEN'h0000_2000
`define UART_BASE                `XLEN'h1000_0000
`define UART_SIZE                `XLEN'h0000_1000
`define SPI_BASE                 `XLEN'h1000_1000
`define SPI_SIZE                 `XLEN'h0000_1000
`define GPIO_BASE                `XLEN'h1000_2000
`define GPIO_SIZE                `XLEN'h0000_0010
`define PS2_BASE                 `XLEN'h1001_1000
`define PS2_SIZE                 `XLEN'h0000_0008
`define MROM_BASE                `XLEN'h2000_0000
`define MROM_SIZE                `XLEN'h0000_1000
`define VGA_BASE                 `XLEN'h2100_0000
`define VGA_SIZE                 `XLEN'h0020_0000
`define FLASH_BASE               `XLEN'h3000_0000
`define FLASH_SIZE               `XLEN'h1000_0000
`define CHIPLINK_MMIO_BASE       `XLEN'h4000_0000
`define CHIPLINK_MMIO_SIZE       `XLEN'h4000_0000
`define PSRAM_BASE               `XLEN'h8000_0000
`define PSRAM_SIZE               `XLEN'h0040_0000
`define SDRAM_BASE               `XLEN'ha000_0000
`define SDRAM_SIZE               `XLEN'h0200_0000
`define CHIPLINK_MEM_BASE        `XLEN'hc000_0000
`define CHIPLINK_MEM_SIZE        `XLEN'h4000_0000

// IDU
`define ASSERT_INST(cond, inst) \
  if (cond) begin \
    assert(0) else $fatal(1, "Invalid inst: %x", inst); \
  end

// AXI4 ERROR
`define AXI_OKAY 2'b00
`define AXI_SLVERR 2'b10
`define AXI_DECERR 2'b11

// AXI4 SIZE
`define AXI_SIZE_BYTE     3'b000
`define AXI_SIZE_HWORD    3'b001
`define AXI_SIZE_WORD     3'b010

// AXI4 BURST
`define AXI_BURST_FIXED    2'b00
`define AXI_BURST_INCR     2'b01
`define AXI_BURST_WRAP     2'b10
`define AXI_BURST_RESERVED 2'b11

`endif // __NPC_DEFINES_SVH__
