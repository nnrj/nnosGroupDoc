typedef char *va_list;

#define   _AUPBND        (sizeof (acpi_native_int) - 1)
#define   _ADNBND        (sizeof (acpi_native_int) - 1)
                    
#define _bnd(X, bnd) (((sizeof (X)) + (bnd)) & (~(bnd)))
#define va_arg(ap, T) (*(T *)(((ap) += (_bnd (T, _AUPBND))) - (_bnd (T,_ADNBND))))
#define va_end(ap)    (void) 0
#define va_start(ap, A) (void) ((ap) = (((char *) &(A)) + (_bnd (A,_AUPBND))))

//start.c
static char sprint_buf[1024];
int printf(char *fmt, ...)
{
va_list args;
int n;
va_start(args, fmt);
n = vsprintf(sprint_buf, fmt, args);
va_end(args);
write(stdout, sprint_buf, n);
return n;
}

 

 

int vsprintf(char *buf, const char *fmt, va_list args)
{
  int len;
  unsigned long num;
  int i, base;
  char *str;
  char *s;

  int flags;            // Flags to number()

  int field_width;    // Width of output field
  int precision;    // Min. # of digits for integers; max number of chars for from string
  int qualifier;    // 'h', 'l', or 'L' for integer fields

  for (str = buf; *fmt; fmt++)
  {
    if (*fmt != '%')
    {
      *str++ = *fmt;
      continue;
    }
         
    // Process flags
    flags = 0;
repeat:
    fmt++; // This also skips first '%'
    switch (*fmt)
    {
      case '-': flags |= LEFT; goto repeat;
      case '+': flags |= PLUS; goto repeat;
      case ' ': flags |= SPACE; goto repeat;
      case '#': flags |= SPECIAL; goto repeat;
      case '0': flags |= ZEROPAD; goto repeat;
    }
     
    // Get field width
    field_width = -1;
    if (is_digit(*fmt))
      field_width = skip_atoi(&fmt);
    else if (*fmt == '*')
    {
      fmt++;
      field_width = va_arg(args, int);
      if (field_width < 0)
      {
    field_width = -field_width;
    flags |= LEFT;
      }
    }

    // Get the precision
    precision = -1;
    if (*fmt == '.')
    {
      ++fmt;   
      if (is_digit(*fmt))
        precision = skip_atoi(&fmt);
      else if (*fmt == '*')
      {
        ++fmt;
        precision = va_arg(args, int);
      }
      if (precision < 0) precision = 0;
    }

    // Get the conversion qualifier
    qualifier = -1;
    if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L')
    {
      qualifier = *fmt;
      fmt++;
    }

    // Default base
    base = 10;

    switch (*fmt)
    {
      case 'c':
    if (!(flags & LEFT)) while (--field_width > 0) *str++ = ' ';
    *str++ = (unsigned char) va_arg(args, int);
    while (--field_width > 0) *str++ = ' ';
    continue;

      case 's':
    s = va_arg(args, char *);
    if (!s)    s = "<NULL>";
    len = strnlen(s, precision);
    if (!(flags & LEFT)) while (len < field_width--) *str++ = ' ';
    for (i = 0; i < len; ++i) *str++ = *s++;
    while (len < field_width--) *str++ = ' ';
    continue;

      case 'p':
    if (field_width == -1)
    {
      field_width = 2 * sizeof(void *);
      flags |= ZEROPAD;
    }
    str = number(str, (unsigned long) va_arg(args, void *), 16, field_width, precision, flags);
    continue;

      case 'n':
    if (qualifier == 'l')
    {
      long *ip = va_arg(args, long *);
      *ip = (str - buf);
    }
    else
    {
      int *ip = va_arg(args, int *);
      *ip = (str - buf);
    }
    continue;

      case 'A':
    flags |= LARGE;

      case 'a':
    if (qualifier == 'l')
      str = eaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
    else
      str = iaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
    continue;

      // Integer number formats - set up the flags and "break"
      case 'o':
    base = 8;
    break;

      case 'X':
    flags |= LARGE;

      case 'x':
    base = 16;
    break;

      case 'd':
      case 'i':
    flags |= SIGN;

      case 'u':
    break;

      case 'E':
      case 'G':
      case 'e':
      case 'f':
      case 'g':
        str = flt(str, va_arg(args, double), field_width, precision, *fmt, flags | SIGN);
    continue;

      default:
    if (*fmt != '%') *str++ = '%';
    if (*fmt)
      *str++ = *fmt;
    else
      --fmt;
    continue;
    }

    if (qualifier == 'l')
      num = va_arg(args, unsigned long);
    else if (qualifier == 'h')
    {
      if (flags & SIGN)
    num = va_arg(args, short);
      else
    num = va_arg(args, unsigned short);
    }
    else if (flags & SIGN)
      num = va_arg(args, int);
    else
      num = va_arg(args, unsigned int);

    str = number(str, num, base, field_width, precision, flags);
  }

  *str = '/0';
  return str - buf;
}