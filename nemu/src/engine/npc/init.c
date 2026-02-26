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

#include <cpu/cpu.h>
#include <stdio.h>
#include <stdlib.h>

void sdb_mainloop();
void init_engine(char *npc_so_file);
extern void (*npc_delete)();

void engine_start() {
  char npc_so_file[256];
  char *NPC_HOME = getenv("NPC_HOME");
  if (NPC_HOME != NULL) { 
    snprintf(npc_so_file, sizeof(npc_so_file), "%s/build/obj_dir/libnpc.so", NPC_HOME); 
  }
  else { 
    panic("Can't find NPC_HOME environment variable"); 
  }

  init_engine(npc_so_file);
#ifdef CONFIG_TARGET_AM
  cpu_exec(-1);
#else
  /* Receive commands from user. */
  sdb_mainloop();
#endif
  npc_delete();
}
