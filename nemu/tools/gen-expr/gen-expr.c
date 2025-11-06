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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

int buf_ptr = 0;
#define MAX_NUM RAND_MAX
#define BUF_SIZE 1000

static void gen_num();      
static void gen(char token);
static void gen_rand_op();
static void gen_rand_space();

static void gen_rand_expr() {
  switch (rand() % 3) {
  case 0:
    gen_num();
    break;
  case 1:
    gen('(');
    gen_rand_expr();
    gen(')');
    break;

  default:
    gen_rand_expr();
    gen_rand_op();
    gen_rand_expr();
    break;
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  FILE *fp_out = fopen("/tmp/input.txt", "w");
  for (i = 0; i < loop; i ++) {
    if (i % 10 == 0) {
      printf("Try to generate %d/%d lines of test data.\r", i, loop); // 显示进度
      fflush(stdout);
    }

    buf_ptr = 0;
    gen_rand_expr();
    buf[buf_ptr] = '\0';

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr -Werror=div-by-zero 2> /dev/null"); // 定义除0为错误
    if (ret != 0) continue;

    fp = popen("/tmp/.expr 2> /dev/null", "r"); // 丢弃错误输出
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    if (ret != -1)
      fprintf(fp_out, "%d %s\n", result, buf);
  }
  fclose(fp_out);
  printf("\r%*s\r", 50, " ");
  return 0;
}

static void gen(char token) { 
  if (buf_ptr > BUF_SIZE)
    return;
  buf[buf_ptr++] = token;

  gen_rand_space();
}

static void gen_num() {
  if (buf_ptr > BUF_SIZE)
    return;
  uint32_t num = rand() % MAX_NUM;
  char buf_temp[32];
  sprintf(buf_temp, "%d", num);
  if (buf_ptr + strlen(buf_temp) > BUF_SIZE)
    return;
  strcpy(&buf[buf_ptr], buf_temp);
  buf_ptr = buf_ptr + strlen(buf_temp);

  gen_rand_space();
}

static void gen_rand_op() {
  if (buf_ptr > BUF_SIZE)
    return;
  switch (rand() % 4) {
  case 0:
    buf[buf_ptr++] = '+';
    break;
  case 1:
    buf[buf_ptr++] = '-';
    break;
  case 2:
    buf[buf_ptr++] = '*';
    break;
  case 3:
    buf[buf_ptr++] = '/';
    break;
  default:
    buf[buf_ptr++] = '+';
    break;
  }

  gen_rand_space();
}

static void gen_rand_space() {
  if (buf_ptr > BUF_SIZE)
    return;
  if (rand() % 2 == 0) {
    int n = rand() % 3 + 1;
    for (int i = 0; i < n && buf_ptr < BUF_SIZE; i++)
    {
      buf[buf_ptr++] = ' ';
    }
  }
}
