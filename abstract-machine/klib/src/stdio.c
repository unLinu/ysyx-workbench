#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define BUF_SIZE 256

int printf(const char *fmt, ...) {
  int ret = 0;
  char out[BUF_SIZE];
  va_list ap;
  va_start(ap, fmt);
  ret = vsprintf(out, fmt, ap);
  va_end(ap);
  putstr(out);
  return ret;
}

void fill_buf(char *out, size_t *len, int num, int width, int base) {
  unsigned long val = 0;
  if (num < 0 && base == 10) {out[(*len)++] = '-'; val = -(unsigned long)num;}
  else {val = num;}

  char buf[BUF_SIZE];
  int num_len = 0;
  do {
    buf[num_len++] = (val % base) + (val % base < 10 ? '0' : 'a' - 10);
    val /= base;
  } while (val > 0);

  if (width > num_len) {
    for (int i = 0; i < width - num_len; i++) {
      out[(*len)++] = '0';
    }
  }
  for (int k = 0; k < num_len; k++)
    out[(*len)++] = buf[num_len - 1 - k];
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  size_t len = 0;
  for (int i = 0; fmt[i]; i++) {
    if (fmt[i] == '%') {
      i++;
      if (fmt[i] == 'c') {
        out[len++] = (char)va_arg(ap, int);
      } 
      else if (fmt[i] == 's') {
        char *s = va_arg(ap, char *);
        for (int j = 0; s[j]; j++) 
          out[len++] = s[j];
      } 
      else if (fmt[i] == 'd') {
        int dec = va_arg(ap, int);
        fill_buf(out, &len, dec, 0, 10);
      }
      else if (fmt[i] == 'x') {
        int hex = va_arg(ap, int);
        fill_buf(out, &len, hex, 0, 16);
      }
      // %0nd, max n = 99
      else if (fmt[i] == '0') {
        int base = 0;
        int width = fmt[i+2] == 'd' || fmt[i+2] == 'x' ? fmt[i+1] - '0' : (fmt[i+1] - '0') * 10 + (fmt[i+2] - '0');
        if (width >= 10) {
          base = fmt[i+3] == 'd' ? 10 : 16;
          i += 3;
        }
        else {
          base = fmt[i+2] == 'd' ? 10 : 16;
          i += 2;
        }

        int num = va_arg(ap, int);
        fill_buf(out, &len, num, width, base);
      }
      // %nd, max n = 99
      else if (fmt[i] >= '1' && fmt[i] <= '9') {
        int base = 0;
        int width = fmt[i+1] == 'd' || fmt[i+1] == 'x' ? fmt[i] - '0' : (fmt[i] - '0') * 10 + (fmt[i+1] - '0');
        if (width >= 10) {
          base = fmt[i+2] == 'd' ? 10 : 16;
          i += 2;
        }
        else {
          base = fmt[i+1] == 'd' ? 10 : 16;
          i += 1;
        }

        int num = va_arg(ap, int);
        fill_buf(out, &len, num, width, base);
      }
      // %ld, %lx
      else if (fmt[i] == 'l') {
        int base = 0;
        i++;
        if (fmt[i] == 'd') {
          base = 10;
          long dec = va_arg(ap, long);
          fill_buf(out, &len, dec, 0, base);
        }
        else if (fmt[i] == 'x') {
          base = 16;
          unsigned long hex = va_arg(ap, unsigned long);
          fill_buf(out, &len, hex, 0, base);
        }
      }
      else {
        putstr("Unsupported format after %: ");
        putch(fmt[i]);
        putch('\n');
        panic("");
      }
    } 
    else {
      out[len++] = fmt[i];
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
