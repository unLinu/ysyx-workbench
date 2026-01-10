#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;
  while (*s != '\0') {
    s++;
    len++;
  }
  return len;
}

char *strcpy(char *dst, const char *src) {
  size_t i;
  for (i = 0; src[i] != '\0'; i++)
    dst[i] = src[i];
  dst[i] = '\0';

  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for (i = 0; i < n && src[i] != '\0'; i++)
    dst[i] = src[i];
  for ( ; i < n; i++)
    dst[i] = '\0';
  
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t dest_len = strlen(dst);
  size_t i;

  for (i = 0; src[i] != '\0'; i++)
    dst[dest_len + i] = src[i];
  dst[dest_len + i] = '\0';

  return dst;
}

int strcmp(const char *s1, const char *s2) {
  while (*s1 == *s2 && *s1 != '\0') {
    s1++;
    s2++;
  }

  return (unsigned char)*s1 - (unsigned char)*s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i;
  for (i = 0; i < n; i++) {
    if (s1[i] != s2[i])
      return (unsigned char)s1[i] - (unsigned char)s2[i];
    else if (s1[i] == '\0')
      return 0;
  }

  return 0;
}

void *memset(void *s, int c, size_t n) {
  size_t i;
  unsigned char *p = (unsigned char*)s;
  for (i = 0; i < n; i++)
    p[i] = (unsigned char)c;
  
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  size_t i;
  unsigned char *d = (unsigned char*)dst;
  unsigned char *s = (unsigned char*)src;

  if (d <= s) {
    for (i = 0; i < n; i++)
      d[i] = s[i];
  } else if (d > s) {
    for (i = 0; i < n; i++)
      d[n - 1 - i] = s[n - 1 - i];
  }

  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  size_t i;
  unsigned char *dst = (unsigned char*)out;
  unsigned char *src = (unsigned char*)in;
  for (i = 0; i < n; i++)
    dst[i] = src[i];

  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  size_t i;
  unsigned char *p1 = (unsigned char*)s1;
  unsigned char *p2 = (unsigned char*)s2;
  for (i = 0; i < n; i++) {
    if (p1[i] != p2[i])
      return (unsigned char)p1[i] - (unsigned char)p2[i];
  }

  return 0;
}

#endif
