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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ,

  /* TODO: Add more token types */
  TK_INT_DEC, TK_MINUS
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},          // spaces
  {"\\+", '+'},               // plus
  {"==", TK_EQ},              // equal
  {"-", '-'},                 // minus
  {"\\*", '*'},               // multiply
  {"/", '/'},                 // divide
  {"\\(", '('},               // left parenthesis
  {"\\)", ')'},               // right parenthesis
  {"[0-9]+", TK_INT_DEC}      // decimal integer

};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[1000] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            // i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        if (nr_token >= ARRLEN(tokens)) {
          printf("Token buffer overflow.\n");
          return false;
        }

        switch (rules[i].token_type) {
          case TK_NOTYPE: break;  // 忽略空格，不记录
          case TK_INT_DEC: {
            tokens[nr_token].type = rules[i].token_type;
            if (substr_len > ARRLEN(tokens[0].str)) {
              printf("Token buffer overflow.\n");
              return false;
            }
            memcpy(&tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token++].str[substr_len] = '\0';
            break;
          }
          default: /* TODO(); */ {  // 其他的不需要记录内容，只需要类型
            tokens[nr_token++].type = rules[i].token_type;
            break;
          }
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

static bool eval_is_successful = true;

word_t eval(int tok_s, int tok_e);
bool check_parentheses(int tok_s, int tok_e); // 检查区间两端是否有匹配的括号

#define TK_IS_OP(p) (tokens[p].type == '+' || tokens[p].type == '-' || \
                     tokens[p].type == '*' || tokens[p].type == '/')

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  /* TODO(); */
  int tok_s = 0;
  int tok_e = nr_token - 1;
  eval_is_successful = true; // 设置默认值

  word_t result = eval(tok_s, tok_e);

  if (!eval_is_successful) {
    *success = false;
    return 0;
  }
  *success = true;
  return result;
}

word_t eval(int tok_s, int tok_e) {
  if (!eval_is_successful)  // 退出所有递归
    return 1;

  if (tok_s > tok_e) {
    eval_is_successful = false;
    return 1;
  }

  else if (tok_s == tok_e) {
    if (tokens[tok_e].type == TK_INT_DEC) {
      return (word_t)strtol(tokens[tok_e].str, NULL, 10);
    }
    else {
      eval_is_successful = false;
      return 1;
    }
  }

  else if (check_parentheses(tok_s, tok_e) == true) {
    return eval(tok_s + 1, tok_e - 1);
  }

  else {
    int op_ptr = -1;   // 主运算符位置
    int op_type = -1;
    int op_pri = 0;    // 主运算符查找优先级位置
    word_t val1 = 0;
    word_t val2 = 0;
    int top_ptr = -1;  // 括号匹配栈指针

    for (int i = tok_s; i <= tok_e; i++) {
      if (tokens[i].type == '(')
        top_ptr++;
      else if (tokens[i].type == ')')
        top_ptr--;

      // 括号错误处理
      if (top_ptr < -1 || (top_ptr != -1 && tok_s == tok_e)) {
        eval_is_successful = false;
        return 1;
      }

      // 查找主运算符位置
      if (top_ptr != -1)  // 忽略括号内部的运算符
        continue;

      if (tokens[i].type == '+' || tokens[i].type == '-') {
        // 判断当前是否为负号，如果之前没有主运算符判定，判定负号为主运算符
        if (tokens[i].type == '-' && (i == tok_s || TK_IS_OP(i-1))) {
          op_ptr = op_ptr == -1 ? i : op_ptr;
          op_type = op_type == -1 ? TK_MINUS : op_type;
        }
        else {
          op_ptr = i;
          op_type = tokens[i].type;
          op_pri = 1;
        }
      }
      else if (op_pri == 0 && (tokens[i].type == '*' || tokens[i].type == '/')) {
        op_ptr = i;
        op_type = tokens[i].type;
      }
    }

    // 错误处理（未找到主运算符）
    if (op_ptr == -1) {
      eval_is_successful = false;
      return 1;
    }

    if (op_type == TK_MINUS) 
      return -eval(op_ptr + 1, tok_e);

    val1 = eval(tok_s, op_ptr - 1);
    val2 = eval(op_ptr + 1, tok_e);

    switch (op_type) {
    case '+':
      return val1 + val2;
      break;
    case '-':
      return val1 - val2;
      break;
    case '*':
      return val1 * val2;
      break;
    case '/': {
      if (val2 == 0) {
        eval_is_successful = false;
        printf("Division by zero is not allowed.\n");
        return 1;
      }
      return (int32_t)val1 / (int32_t)val2;
    }
    default:
      panic("Operation type error.");
    }
  }
}

bool check_parentheses(int tok_s, int tok_e) {
  int top_ptr = -1;     // 初始化栈顶指针，这个栈不需要存数据，最后只需要判断指针是否回到起点

  if (tokens[tok_s].type != '(' || tokens[tok_e].type != ')')
    return false;
  
  while (tok_s <= tok_e) {
    if (tokens[tok_s].type == '(') {
      top_ptr++;
    }
    else if (tokens[tok_s].type == ')') {
      top_ptr--;
    }
    if (top_ptr == -1 && tok_s != tok_e)  // 处理提前匹配的情况
      return false;
    tok_s++;
  }

  return top_ptr == -1 ? true : false;
}
