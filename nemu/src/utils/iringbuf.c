#include <../include/utils.h>
#include <debug.h>
#include <string.h>

IRingBuf irbuf[IRINGBUF_SIZE];
int latest_index = -1;

void init_iringbuf() {
  for (size_t i = 0; i < IRINGBUF_SIZE; i++) {
    irbuf[i].logbuf[0] = '\0';
  }
}

void iringbuf_add(char *log) {
  strcpy(irbuf[++latest_index % IRINGBUF_SIZE].logbuf, log);
}

void iringbuf_display() {
  int start = (latest_index + 1) % IRINGBUF_SIZE; // 从最旧的一条开始打印

  printf(ANSI_FMT("------ Recent Instruction Trace ------", ANSI_FG_GREY) "\n");
  for (size_t i = 0; i < IRINGBUF_SIZE; i++) {
    int cur_index = (start + i) % IRINGBUF_SIZE;
    if (irbuf[cur_index].logbuf[0] != '\0') {
      if (i == IRINGBUF_SIZE - 1)
        printf(ANSI_FMT("%s\t<--x", ANSI_FG_RED) "\n", irbuf[cur_index].logbuf);
      else
        printf("%s\n", irbuf[cur_index].logbuf);
    }
  }
  printf(ANSI_FMT("------ End of Instruction Trace ------", ANSI_FG_GREY) "\n");
}
