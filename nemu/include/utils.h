/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#ifndef __UTILS_H__
#define __UTILS_H__

#include <common.h>
#include <elf.h>

// ----------- state -----------

enum { NEMU_RUNNING, NEMU_STOP, NEMU_END, NEMU_ABORT, NEMU_QUIT };

typedef struct {
  int state;
  vaddr_t halt_pc;
  uint32_t halt_ret;
} NEMUState;

extern NEMUState nemu_state;

// ----------- timer -----------

uint64_t get_time();

// ----------- log -----------

#define ANSI_FG_BLACK   "\33[1;30m"
#define ANSI_FG_RED     "\33[1;31m"
#define ANSI_FG_GREEN   "\33[1;32m"
#define ANSI_FG_YELLOW  "\33[1;33m"
#define ANSI_FG_BLUE    "\33[1;34m"
#define ANSI_FG_MAGENTA "\33[1;35m"
#define ANSI_FG_CYAN    "\33[1;36m"
#define ANSI_FG_WHITE   "\33[1;37m"
#define ANSI_FG_GREY    "\33[1;90m"
#define ANSI_BG_BLACK   "\33[1;40m"
#define ANSI_BG_RED     "\33[1;41m"
#define ANSI_BG_GREEN   "\33[1;42m"
#define ANSI_BG_YELLOW  "\33[1;43m"
#define ANSI_BG_BLUE    "\33[1;44m"
#define ANSI_BG_MAGENTA "\33[1;45m"
#define ANSI_BG_CYAN    "\33[1;46m"
#define ANSI_BG_WHITE   "\33[1;47m"
#define ANSI_NONE       "\33[0m"

#define ANSI_FMT(str, fmt) fmt str ANSI_NONE

#define log_write(...) IFDEF(CONFIG_TARGET_NATIVE_ELF, \
  do { \
    extern FILE* log_fp; \
    extern bool log_enable(); \
    if (log_enable() && log_fp != NULL) { \
      fprintf(log_fp, __VA_ARGS__); \
      fflush(log_fp); \
    } \
  } while (0) \
)

#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
    log_write(__VA_ARGS__); \
  } while (0)

// ----------- trace -----------
#define REG_FMT_PRINT(reg) \
  printf(ANSI_FMT("%3s", ANSI_FG_CYAN) ": " FMT_WORD " ", reg, gpr(i));

#define FTRACE_FMT_PRINT(depth, type, func, addr, entry_addr) \
  do { \
    printf(ANSI_FMT("[ftrace] ", ANSI_FG_MAGENTA) FMT_PADDR ": ", addr); \
    for (int _k = 0; _k < (depth); _k++) { \
      printf(ANSI_FMT("|   ", ANSI_FG_GREY));\
    } \
    if (strcmp(type, "call") == 0) { \
      printf(ANSI_FMT("-> call", ANSI_FG_GREEN)); \
    } else { \
      printf(ANSI_FMT("<- ret ", ANSI_FG_YELLOW)); \
    } \
    printf(ANSI_FMT(" [%s @" FMT_WORD "]", ANSI_FG_CYAN) "\n", func, entry_addr); \
  } while (0)

#define MTRACE_FMT_PRINT(WR, pc, addr, data, len) \
  do { \
    if (addr >= CONFIG_MTRACE_START && addr <= CONFIG_MTRACE_END) { \
      printf(ANSI_FMT("[mtrace] ", ANSI_FG_MAGENTA) "PC: " FMT_WORD " ", pc); \
      if (strcmp(WR, "READ") == 0) { \
        printf(ANSI_FMT("READ ", ANSI_FG_GREEN)); \
      } else { \
        printf(ANSI_FMT("WRITE", ANSI_FG_YELLOW)); \
      } \
      printf(" Addr: " FMT_WORD " Data: " FMT_WORD " Len: %d\n", addr, data, len); \
    } \
  } while (0)

#define CHECK_DEVICE(name, ref) strcmp(name, ref) == 0
#define DTRACE_FMT_PRINT(dev) \
  do { \
    if (CHECK_DEVICE(dev->name, "serial")) { IFNDEF(CONFIG_DTRACE_SERIAL, break);} \
    else if (CHECK_DEVICE(dev->name, "rtc")) { IFNDEF(CONFIG_DTRACE_TIMER, break);} \
    else if (CHECK_DEVICE(dev->name, "vgactl") || CHECK_DEVICE(dev->name, "vmem")) { IFNDEF(CONFIG_DTRACE_VGA, break);} \
    else if (CHECK_DEVICE(dev->name, "keyboard")) { IFNDEF(CONFIG_DTRACE_KEYBOARD, break);} \
    else if (CHECK_DEVICE(dev->name, "audio") || CHECK_DEVICE(dev->name, "audio-sbuf")) { IFNDEF(CONFIG_DTRACE_AUDIO, break);} \
    else { break; } \
    printf(ANSI_FMT("[dtrace]", ANSI_FG_MAGENTA) " %s\t@ " FMT_PADDR " ~ " FMT_PADDR "\n", dev->name, dev->low, dev->high); \
  } while(0); 

#define ETRACE_FMT_PRINT(epc) \
  do { \
    printf(ANSI_FMT("[etrace]", ANSI_FG_MAGENTA) " EPC: " FMT_WORD "\n", epc); \
  } while(0)

#define IRINGBUF_SIZE 10 

typedef struct {
  char logbuf[128];
} IRingBuf;

typedef struct {
  char name[20];
  uint32_t entry_addr;
  uint32_t func_size;
} FuncInfo;

extern IRingBuf irbuf[IRINGBUF_SIZE];
extern FuncInfo *ftrace_table;

void init_iringbuf();
void iringbuf_add(char *log);
void iringbuf_display();

FuncInfo* init_ftrace(const char *elf_file);
void free_ftrace(FuncInfo *table);

#endif
