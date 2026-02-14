#include "klib-macros.h"
#include <am.h>
#include <nemu.h>
#include <stdint.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = 0, .height = 0,
    .vmemsz = 0
  };

  uint32_t screen_size = inl(VGACTL_ADDR);
  cfg->width = screen_size >> 16;
  cfg->height = screen_size & 0xffff;
  cfg->vmemsz = cfg->width * cfg->height * sizeof(uint32_t);
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (ctl->pixels) {
    int screen_w = inl(VGACTL_ADDR) >> 16;
    int screen_h = inl(VGACTL_ADDR) & 0xffff;
    panic_on(ctl->x > screen_w && ctl->y > screen_h, "FB draw out of screen\n");
    uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;

    for (int j = 0; j < ctl->h; j++)
      for (int i = 0; i < ctl->w; i++)
        fb[(ctl->y + j) * screen_w + (ctl->x + i)] = ((uint32_t *)ctl->pixels)[j * ctl->w + i];
  }
  
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
