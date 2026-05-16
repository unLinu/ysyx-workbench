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

#include "common.h"
#include "macro.h"
#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[MSIZE] PG_ALIGN = {};
#endif

const pmem_region_t pmem_table[] = {
  {"flash", FLASH_LEFT, FLASH_RIGHT, 0, false},
  {"sram", SRAM_LEFT, SRAM_RIGHT, CONFIG_FLASH_SIZE, true}, // NOTE: SRAM is for difftest
  {"psram", PSRAM_LEFT, PSRAM_RIGHT, CONFIG_FLASH_SIZE + CONFIG_SRAM_SIZE, true}
};

const pmem_region_t *find_pmem_region(paddr_t addr) {
  for (int i = 0; i < ARRLEN(pmem_table); i++) {
    if (addr >= pmem_table[i].start && addr <= pmem_table[i].end)
      return &pmem_table[i];
  }
  return NULL;
}

uint8_t* guest_to_host(paddr_t paddr) {
  const pmem_region_t *r = find_pmem_region(paddr);
  return pmem + r->offset + paddr - r->start;
}

paddr_t host_to_guest(uint8_t *haddr) {
  assert(0);
}

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem at pc = " FMT_WORD,
      addr, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), MSIZE));
  for (int i = 0; i < ARRLEN(pmem_table); i++) {
    Log("physical memory area %s [" FMT_PADDR ", " FMT_PADDR "]", pmem_table[i].name, pmem_table[i].start, pmem_table[i].end);
  }
}

word_t paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) {
    word_t rd_data = pmem_read(addr, len);
    IFDEF(CONFIG_MTRACE, MTRACE_FMT_PRINT("READ", cpu.pc, addr, rd_data, len));
    return rd_data; 
  } 

  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE, MTRACE_FMT_PRINT("WRITE", cpu.pc, addr, data, len));
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
