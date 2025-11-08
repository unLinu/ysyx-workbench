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

static int buf_ptr = 0;
static int depth = 0;
#define MAX_NUM RAND_MAX
#define BUF_SIZE 1000
#define MAX_DEPTH 100

static void gen_num(int fmt);      
static void gen(char token);
static void gen_rand_op();
static void gen_rand(char token, int num); // 50%概率随机生成1-{num}次的token

static void gen_rand_expr() {
  if (depth >= MAX_DEPTH || buf_ptr > BUF_SIZE) { // 限制递归深度
    gen_num(10);
    return;
  }
  depth++;
  switch (rand() % 3) {
  case 0:
    gen_rand('-', 1);
    gen_num(rand() % 2 ? 10 : 16);
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
    depth = 0;
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
    ret = fscanf(fp, "%u", &result);
    pclose(fp);

    if (ret != -1)
      fprintf(fp_out, "%u %s\n", result, buf);
  }
  fclose(fp_out);
  printf("\r%*s\r", 50, " ");
  return 0;
}

static void gen(char token) { 
  if (buf_ptr > BUF_SIZE)
    return;
  buf[buf_ptr++] = token;

  gen_rand(' ', 3);
}

static void gen_num(int fmt) {
  if (buf_ptr > BUF_SIZE)
    return;
  uint32_t num = rand() % MAX_NUM;
  char buf_temp[32];

  // 选择输出格式
  switch (fmt) {
  case 10:
    sprintf(buf_temp, "%d", num);
    break;
  case 16:
    sprintf(buf_temp, "0x%x", num);
    break;
  default:
    sprintf(buf_temp, "%d", num);
    break;
  }

  if (buf_ptr + strlen(buf_temp) > BUF_SIZE)
    return;
  strcpy(&buf[buf_ptr], buf_temp);
  buf_ptr = buf_ptr + strlen(buf_temp);

  gen_rand(' ', 3);
}

static void gen_rand_op() {
  if (buf_ptr > BUF_SIZE)
    return;
  switch (rand() % 13) {
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
  case 4:
    buf[buf_ptr++] = '|';
    buf[buf_ptr++] = '|';
    break;
  case 5:
    buf[buf_ptr++] = '&';
    buf[buf_ptr++] = '&';
    break;
  case 6:
    buf[buf_ptr++] = '=';
    buf[buf_ptr++] = '=';
    break;
  case 7:
    buf[buf_ptr++] = '!';
    buf[buf_ptr++] = '=';
    break;
  case 8:
    buf[buf_ptr++] = '<';
    break;
  case 9:
    buf[buf_ptr++] = '>';
    break;
  case 10:
    buf[buf_ptr++] = '<';
    break;
  case 11:
    buf[buf_ptr++] = '>';
    buf[buf_ptr++] = '=';
    break;
  case 12:
    buf[buf_ptr++] = '<';
    buf[buf_ptr++] = '=';
    break;
  default:
    buf[buf_ptr++] = '+';
    break;
  }

  gen_rand(' ', 3);
}

static void gen_rand(char token, int num) {
  if (buf_ptr > BUF_SIZE)
    return;
  if (rand() % 2 == 0) {
    int n = rand() % num + 1;
    for (int i = 0; i < n && buf_ptr < BUF_SIZE; i++)
    {
      buf[buf_ptr++] = token;
    }
  }
}
