/******************************************************************  ctype.h - character types**  February 1989*  Mike Westerfield**  Copyright 1989*  Byte Works, Inc.*****************************************************************/#ifndef __ctype__#define __ctype__extern char __ctype[],__ctype2[];#define __digit         0x01#define __upper         0x02#define __lower         0x04#define __control       0x08#define __punctuation   0x10#define __space         0x20#define __hex           0x40#define __print         0x80#define __csym          0x01#define __csymf         0x02#define __octal         0x04#define isalnum(c)      ((__ctype)[(c)+1] & (__upper|__lower|__digit))#define isalpha(c)      ((__ctype)[(c)+1] & (__upper|__lower))#define isascii(c)      ((unsigned)(c) < 0x0080)#define iscntrl(c)      ((__ctype)[(c)+1] & __control)#define iscsym(c)       ((__ctype2)[(c)+1] & __csym)#define iscsymf(c)      ((__ctype2)[(c)+1] & __csymf)#define isdigit(c)      ((__ctype)[(c)+1] & __digit)#define isgraph(c)      ((__ctype)[(c)+1] & (__upper|__lower|__digit|__punctuation))#define islower(c)      ((__ctype)[(c)+1] & __lower)#define isodigit(c)     ((__ctype2)[(c)+1] & __octal)#define isprint(c)      ((__ctype)[(c)+1] & __print)#define ispunct(c)      ((__ctype)[(c)+1] & __punctuation)#define isspace(c)      ((__ctype)[(c)+1] & __space)#define isupper(c)      ((__ctype)[(c)+1] & __upper)#define isxdigit(c)     ((__ctype)[(c)+1] & __hex)#define toascii(c)      ((c) & 0x7F)int                     toint(char);int                     tolower(char);int                     toupper(char);#define _tolower(c)     ((c) | 0x20)#define _toupper(c)     ((c) & 0x5F)#endif