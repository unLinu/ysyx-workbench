#include <am.h>
#include <nemu.h>
#include <stdint.h>

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  kbd->keydown = 0;
  kbd->keycode = AM_KEY_NONE;

  uint32_t am_scancode = inl(KBD_ADDR);
  kbd->keydown = (am_scancode & KEYDOWN_MASK) ? 1 : 0;
  kbd->keycode = am_scancode & (~KEYDOWN_MASK);
}
