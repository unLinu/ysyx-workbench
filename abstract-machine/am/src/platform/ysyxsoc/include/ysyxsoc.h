#ifndef YSYX_SOC_H__
#define YSYX_SOC_H__

#include <klib-macros.h>

#include ISA_H // the macro `ISA_H` is defined in CFLAGS
               // it will be expanded as "x86/x86.h", "mips/mips32.h", ...

#if defined(__ISA_X86__)
# define ysyxsoc_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_MIPS32__)
# define ysyxsoc_trap(code) asm volatile ("move $v0, %0; sdbbp" : :"r"(code))
#elif defined(__riscv)
# define ysyxsoc_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#elif defined(__ISA_LOONGARCH32R__)
# define ysyxsoc_trap(code) asm volatile("move $a0, %0; break 0" : :"r"(code))
#else
# error unsupported ISA __ISA__
#endif

// SoC Device
#define CLINT_ADDR            0x02000000  // ~ 0x0200ffff
#define SRAM_ADDR             0x0f000000  // ~ 0x0fffffff
#define UART_ADDR             0x10000000  // ~ 0x10000fff
#define SPI_ADDR              0x10001000  // ~ 0x10001fff
#define GPIO_ADDR             0x10002000  // ~ 0x1000200f
#define PS2_ADDR              0x10011000  // ~ 0x10011007
#define MROM_ADDR             0x20000000  // ~ 0x20000fff
#define VGA_ADDR              0x21000000  // ~ 0x211fffff
#define FLASH_ADDR            0x30000000  // ~ 0x3fffffff
#define CHIPLINK_MMIO_ADDR    0x40000000  // ~ 0x7fffffff
#define PSRAM_ADDR            0x80000000  // ~ 0x9fffffff
#define SDRAM_ADDR            0xa0000000  // ~ 0xbfffffff
#define CHIPLINK_MEM_ADDR     0xc0000000  // ~ 0xffffffff

#define SRAM_SIZE (8 * 1024)  // 8 KB
#define SRAM_END  (SRAM_ADDR + SRAM_SIZE)

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
