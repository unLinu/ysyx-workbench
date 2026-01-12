#include <../include/utils.h>
#include <elf.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <isa.h>
#include <debug.h>

FuncInfo *ftrace_table = NULL; // 全局函数表指针
static int ftrace_table_len = 0;
static int call_depth = 0;

FuncInfo* init_ftrace(const char *elf_file) {
  Assert(elf_file != NULL, "ELF file for ftrace is not specified.");

  int fd = open(elf_file, O_RDONLY);
  Assert(fd >= 0, "Open file %s failed", elf_file);

  struct stat st;
  fstat(fd, &st);

  void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  Assert(map != MAP_FAILED, "Mmap file %s failed", elf_file);

  // 创建 Elf 头指针
  Elf32_Ehdr *ehdr = (Elf32_Ehdr *)map;

  // 检查是否可执行文件
  Assert(ehdr->e_type == ET_EXEC, "File %s is not an executable file.", elf_file);

  // 获取节区头表
  Elf32_Shdr *shdr = (Elf32_Shdr *)((char *)map + ehdr->e_shoff);

  // 获取节头名字符串表
  char* shstrtab = (char *)map + shdr[ehdr->e_shstrndx].sh_offset;

  // 查找符号表和符号字符串表位置
  Elf32_Sym *symtab = NULL;
  char *strtab = NULL;
  uint32_t symtab_size = 0;
  for (size_t i = 0; i < ehdr->e_shnum; i++) {
    char *name = shstrtab + shdr[i].sh_name;
    if (strcmp(name, ".symtab") == 0) {
      symtab = (Elf32_Sym *)((char *)map + shdr[i].sh_offset);
      symtab_size = shdr[i].sh_size / sizeof(Elf32_Sym);
    }
    else if (strcmp(name, ".strtab") == 0)
      strtab = (char *)map + shdr[i].sh_offset;
  }
  Assert(symtab != NULL && strtab != NULL, "Failed to find .symtab or .strtab in %s", elf_file);

  // 建立 FUNC 类型的查找表
  FuncInfo *func_table = NULL;
  int func_count = 0;
  for (size_t i = 0; i < symtab_size; i++) {
    if (ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC) 
      func_count++;
  }
  func_table = (FuncInfo *)malloc(sizeof(FuncInfo) * func_count);
  ftrace_table_len = func_count;
  Assert(func_table != NULL, "Failed to allocate memory for func_table");
  for (size_t i = 0; i < symtab_size; i++) {
    if (ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC) {
      strcpy(func_table[--func_count].name, strtab + symtab[i].st_name);
      func_table[func_count].entry_addr = symtab[i].st_value;
      func_table[func_count].func_size = symtab[i].st_size;
      if (func_count == 0) break;
    }
  }
  
  close(fd);
  munmap(map, st.st_size);
  return func_table;
}

void free_ftrace(FuncInfo *table) {
  if (table != NULL) {
    free(table);
    table = NULL;
  }
}

void ftrace_log(uint32_t inst, uint32_t dnpc) {
  Assert(ftrace_table != NULL, "Ftrace table is not initialized.");
  // 提取 opcode rd rs1 字段
  uint8_t opcode = inst & 0x7f;
  uint8_t rd = (inst >> 7) & 0x1f;
  uint8_t rs1 = (inst >> 15) & 0x1f;
  // call
  size_t i;
  if ((opcode == 0x6f || opcode == 0x67) && rd == 1) {
    for (i = 0; i < ftrace_table_len; i++) {
      if (ftrace_table[i].entry_addr == dnpc) {
        Log("\t" FMT_WORD ": %*scall [%s@" FMT_WORD "]", cpu.pc, call_depth * 2, "", ftrace_table[i].name, ftrace_table[i].entry_addr);
        call_depth++;
        Assert(i < ftrace_table_len, "Cannot find function in ftrace table!");
        break;
      }
    }
  } 
  // ret
  else if (opcode == 0x67 && rs1 == 1 && rd == 0) {
    for (i = 0; i < ftrace_table_len; i++) {
      Elf32_Addr func_start = ftrace_table[i].entry_addr;
      Elf32_Addr func_end = func_start + ftrace_table[i].func_size;
      if (func_start <= cpu.pc && cpu.pc <= func_end) {
        call_depth--;
        Log("\t" FMT_WORD ": %*sret [%s]", cpu.pc, call_depth * 2, "", ftrace_table[i].name);
        Assert(i < ftrace_table_len, "Cannot find function in ftrace table!");
        break;
      }
    }
  }

  Assert(call_depth >= 0, "Ftrace call depth error!");
}
