#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  int ret = 0;
  char out[1024];
  va_list ap;
  va_start(ap, fmt);
  ret = vsprintf(out, fmt, ap);
  va_end(ap);
  putstr(out);
  return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  size_t len = 0;
  while (*fmt != '\0') {
    if (*fmt == '%') {
      fmt++; // point to the character after '%'
      switch (*fmt++) {
      case 's': {
        char *s = va_arg(ap, char *);
        size_t slen = strlen(s);
        strncpy(out + len, s, slen);
        len += slen;
        break;
      }
      case 'd': {
        int num = va_arg(ap, int);
        char buf[1024];
        size_t i, j;
        int num_len = 0;

        if (num == 0) {
          out[len++] = '0';
          break;
        }
        unsigned int val = (unsigned int)num;
        if (num < 0) {
          out[len++] = '-';
          val = -(unsigned int)(num);  // 防止溢出
        }

        j = 0;
        while (val != 0) {
          buf[j++] = val % 10;
          val /= 10;
          num_len++;
        }

        for (i = 0; i < num_len; i++) {
          out[len++] = buf[--j] + '0';
        }
        break;
      }
      default:
        panic("Invalid argument.");
        break;
      }
    } else {
      out[len++] = *fmt++;
    }
  }
  out[len] = '\0';

  return len;
}

int sprintf(char *out, const char *fmt, ...) {
  int ret = 0;
  va_list ap;
  va_start(ap, fmt);
  ret = vsprintf(out, fmt, ap);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
