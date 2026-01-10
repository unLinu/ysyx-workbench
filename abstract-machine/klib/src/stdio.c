#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  size_t len = 0;
  va_list ap;
  va_start(ap, fmt);

  while (*fmt != '\0') {
    if (*fmt == '%') {
      fmt++; // point to the character after '%'
      switch (*fmt++) {
      case 's': {
        char *s = va_arg(ap, char*);
        size_t slen = strlen(s);
        strncpy(out + len, s, slen);
        len += slen;
        break;
      }
      case 'd': {
        int num = va_arg(ap, int);
        char buf[10];
        size_t i, j;
        int num_len = 0;

        if (num == 0) {
          out[len++] = '0';
          break;
        }
        if (num < 0) {
          out[len++] = '-';
          num = -num;
        }
        
        j = 0;
        while (num != 0) { 
          buf[j++] = num % 10;
          num /= 10;
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
  va_end(ap);
  out[len] = '\0';
  return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
