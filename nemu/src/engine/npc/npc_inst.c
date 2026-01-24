#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/ifetch.h>
#include <assert.h>
#include <dlfcn.h>
#include <stdint.h>
#include <utils.h>

void (*npc_init) (int argc, char **argv) = NULL;
void (*npc_reset) () = NULL;
void (*npc_exec_once) (uint32_t inst, uint32_t *snpc, uint32_t *dnpc) = NULL;
void (*npc_delete) () = NULL;
void (*npc_update_reg) (uint32_t *regs) = NULL;
int  (*npc_get_trap_flag) () = NULL;

void init_engine(char *npc_so_file) {
  assert(npc_so_file != NULL);

  void *handle;
  handle = dlopen(npc_so_file, RTLD_LAZY | RTLD_DEEPBIND);
  assert(handle);

  npc_init = dlsym(handle, "npc_init");
  assert(npc_init);

  npc_reset = dlsym(handle, "npc_reset");
  assert(npc_reset);

  npc_exec_once = dlsym(handle, "npc_exec_once");
  assert(npc_exec_once);

  npc_delete = dlsym(handle, "npc_delete");
  assert(npc_delete);

  npc_update_reg = dlsym(handle, "npc_update_reg");
  assert(npc_update_reg);

  npc_get_trap_flag = dlsym(handle, "npc_get_trap_flag");
  assert(npc_get_trap_flag);

  npc_init(0, NULL);
  npc_reset();
  printf(ANSI_FMT("NPC engine loaded successfully: %s\n", ANSI_FG_GREEN), npc_so_file);
}

int isa_exec_once(Decode *s) {
  s->isa.inst = vaddr_ifetch(s->snpc, 4);
  npc_exec_once(s->isa.inst, &s->snpc, &s->dnpc);
  npc_update_reg(cpu.gpr);
  if (npc_get_trap_flag())
    NEMUTRAP(s->pc,0);
  return 0;
}
