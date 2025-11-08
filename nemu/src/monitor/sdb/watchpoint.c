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

#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */

WP *new_wp(void) {
  if (free_ == NULL) 
    panic("No more watchpoints available.\n");
  
  WP *wp = free_;
  free_ = free_->next;  // 从空闲池取出结点
  wp->next = head;      // 接入
  head = wp;
  
  return wp;
}

void free_wp(WP *wp) {
  WP *node = head;
  if (node == wp) {
    head = wp->next;
  } 
  else {
    while (node->next != wp) { // 找到wp的前一个结点
      if (node->next == NULL)
        panic("Cannot find this watchpoint.\n");
      node = node->next;
    }
    node->next = wp->next; // 断开wp
  }
  wp->next = free_; // 接入空闲池
  free_ = wp;
}

void wp_info_display() {
  if (head == NULL) {
    printf("No watchpoints.\n");
    return;
  }

  printf("%-8s%-24s%-12s\n", "Num", "Expr", "Value");
  WP *wp = head;
  while (wp != NULL) {
    printf("%-8d%-24s%-12d\n", wp->NO, wp->expr, wp->value);
    if (wp->hit != 0)
      printf("%-8sbreakpoint already hit %d times.\n", " ", wp->hit);
    wp = wp->next;
  }
}

WP *find_wp(int NO) {
  if (head == NULL) {
    printf("No watchpoints.\n");
    return NULL;
  }

  WP *node = head;
  while (node->NO != NO) {
    node = node->next;
    if (node == NULL) {
      printf("Cannot find NO.%d.\n", NO);
      return NULL;
    }
  }

  return node;
}

int scan_wp(void) {
  if (head == NULL) {
    return 0;
  }

  WP *node = head;
  word_t new_val = 0;
  bool success;
  int wp_hit = 0;
  while (node != NULL) {
    new_val = expr(node->expr, &success);
    if (!success) panic("Scan watchpoint error.\n");
    if (node->value != new_val) {
      printf("Watchpoint %d: %s\n", node->NO, node->expr);
      printf("\n");
      printf("Old value = %d\n", node->value);
      printf("New value = %d\n", new_val);
      node->hit++;
      node->value = new_val;
      wp_hit++;
    }
    node = node->next;
  }

  return wp_hit;  // 返回命中的监视点总数
}
