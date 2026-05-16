#include <am.h>

#define BOOT_MEMCPY(func_name, sec_name) \
  __attribute__((section(sec_name))) \
  void *func_name(void *out, const void *in, size_t n) { \
    size_t i; \
    unsigned char *dst = (unsigned char*)out; \
    unsigned char *src = (unsigned char*)in; \
    for (i = 0; i < n; i++) dst[i] = src[i]; \
    return out; \
  } \

#define BOOT_MEMSET(func_name, sec_name) \
  __attribute__((section(sec_name))) \
  void *func_name(void *s, int c, size_t n) { \
    size_t i; \
    unsigned char *p = (unsigned char*)s; \
    for (i = 0; i < n; i++) p[i] = (unsigned char)c; \
    return s; \
  } \

extern char _ssbl_start, _ssbl_end, _ssbl_load;
extern char _data_start, _data_end, _data_load;
extern char _bss_start, _bss_end;
extern char _text_start, _text_end, _text_load;
extern char _rodata_start, _rodata_end, _rodata_load;

BOOT_MEMCPY(fsbl_memcpy, ".boot.fsbl")
BOOT_MEMSET(ssbl_memset, ".boot.ssbl")
BOOT_MEMCPY(ssbl_memcpy, ".boot.ssbl")

__attribute__((section(".boot.fsbl")))
void _fsbl() {
  fsbl_memcpy(&_ssbl_start, &_ssbl_load, &_ssbl_end - &_ssbl_start);
}

__attribute__((section(".boot.ssbl")))
void _ssbl() {
  ssbl_memcpy(&_text_start, &_text_load, &_text_end - &_text_start);
  ssbl_memcpy(&_rodata_start, &_rodata_load, &_rodata_end - &_rodata_start);
  ssbl_memcpy(&_data_start, &_data_load, &_data_end - &_data_start);
  ssbl_memset(&_bss_start, 0, &_bss_end - &_bss_start);
}
