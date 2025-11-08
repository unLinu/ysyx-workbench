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

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
//
#include <memory/vaddr.h>

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT; // 实现优美的退出
  return -1;
}

static int cmd_si(char *args) {
  uint64_t exec_num = 0;
  char *args_end;
  if (args == NULL)
    exec_num = 1;
  else {
    exec_num = (uint64_t)strtol(args, &args_end, 10); // 输入负数会被强转为一个很大的整数，等效持续执行
    if (*args_end != '\0') {
      printf("Invalid argument.\n");
      return 1;
    }
  }
  
  cpu_exec(exec_num);
  return 0;
}

static int cmd_info(char *args) {
  if (args == NULL) {
    printf("Need argument r or w.\n");
    return 1;
  }

  if (strcmp(args, "r") == 0)
    isa_reg_display();
  else if (strcmp(args, "w") == 0) {
    wp_info_display();
  }
  else {
    printf("Invalid argument (must be r or w).\n");
    return 1;
  }
  return 0;
}

static int cmd_x(char *args) {
  int N = 0;          // 扫描单元数
  vaddr_t vaddr = 0;  // 起始虚拟地址
  char *args1, *args2;
  char *args1_end, *args2_end;
  if (args == NULL) {
    printf("Need two arguments.\n");
    return 1;
  }

  args1 = strtok(args, " ");
  args2 = strtok(NULL, " ");
  if (args1 == NULL || args2 == NULL) {
    printf("Need two arguments.\n");
    return 1;
  }

  N = strtol(args1, &args1_end, 10);
  vaddr = strtol(args2, &args2_end, 0);
  if (*args1_end != '\0' || *args2_end != '\0' || N < 0) {  // 检查是否包含非法字符
    printf("Invalid arguments.\n");
    return 1;
  }

  printf(FMT_PADDR ":\t", vaddr);
  for (int i = 0; i < N; i++) {
    word_t data = vaddr_read(vaddr + 4 * i, 4);
    printf(FMT_WORD "\t", data);
  }
  printf("\n");
  return 0;
}

static int cmd_p(char *args) {
  bool success = 0;
  word_t result = 0;
  if (args == NULL) {
    printf("Need expression.\n");
    return 1;
  }
  result = expr(args, &success);
  if (!success) {
    printf("Invalid expression, please check.\n");
    return 1;
  }
  printf("%d\n", (int)result);
  return 0;
}

static int cmd_test(char *args) {
  int ret = system("cd $NEMU_HOME/tools/gen-expr && make > /dev/null");
  if (ret != 0) {
    printf("gen-expr.c make error.\n");
    return 1;
  }
  ret = system("cd $NEMU_HOME/tools/gen-expr && ./build/gen-expr 500");
  if (ret != 0) {
    printf("Generate test file error.\n");
    return 1;
  }

  FILE *fp = fopen("/tmp/input.txt", "r");
  bool success = false;
  word_t result = 0;
  word_t std_res = 0;
  unsigned pass = 0, fail = 0, cur_line = 0;

  char line[65536 + 33];
  char exp[65536];

  if (fp == NULL) {
    printf("Failed to open /tmp/input.txt.\n");
    return 1;
  }
  while (fgets(line, sizeof(line), fp) != NULL) {
    cur_line++;
    if (sscanf(line, "%u %[^\n]\n", &std_res, exp) != 2) {
      printf("Fail to read line %d.\n", cur_line);
      fail++;
      continue;
    }

    result = expr(exp, &success);
    if (!success || result != std_res) {
      printf("Fail at line %d in input.txt.\n", cur_line);
      fail++;
    }
    else
      pass++;
  }

  fclose(fp);
  printf("Test over. %d passed, %d failed.\n", pass, fail);

  return 0;
}

static int cmd_w(char *args) {
  if (args == NULL) {
    printf("Need expression.\n");
    return 1;
  }
  bool success = false;
  word_t wat_val = expr(args, &success);
  if (!success) {
    printf("Invalid expression.\n");
    return 1;
  }

  WP *new = new_wp();
  if (strlen(args) >= ARRLEN(new->expr)) {
    printf("Expression too long.\n");
    free_wp(new);
    return 1;
  }

  strcpy(new->expr, args);
  new->value = wat_val;
  new->hit = 0;
  printf("Watchpoint %d: %s\n", new->NO, new->expr);

  return 0;
}

static int cmd_d(char *args) {
  if (args == NULL) {
    printf("Watchpoint number required.\n");
    return 1;
  }

  char *args_end;
  int NO = (int)strtol(args, &args_end, 10);

  if (*args_end != '\0') {
    printf("Invalid watchpoint number.\n");
    return 1;
  }

  WP *wp = find_wp(NO);
  if (wp == NULL)
    return 1;
 
  free_wp(wp);

  return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */
  {"si", "Pause program execution after single-stepping N instructions. if N is not specified, the default value is 1.", cmd_si},
  {"info", "Print register state(info r). Print watchpoint information(info w).", cmd_info},
  {"x", "Calculate the value of the expression EXPR, use the result as the starting memory address, and output N consecutive 4-byte values in hexadecimal format.", cmd_x},
  {"p", "Calculate the value of the expression.", cmd_p},
  {"test", "Run expression evaluation tests", cmd_test},
  {"w", "Set watchpoint.", cmd_w},
  {"d", "Delete watchpoint.", cmd_d}
};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
