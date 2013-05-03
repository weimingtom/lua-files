--result of `cpp stdlib.h` from mingw
local ffi = require'ffi'

ffi.cdef[[
int _argc;
char** _argv;
int* __p___argc(void);
char*** __p___argv(void);
wchar_t*** __p___wargv(void);
int __mb_cur_max;
int* _errno(void);
int* __doserrno(void);
char *** __p__environ(void);
wchar_t *** __p__wenviron(void);
int _sys_nerr;
char* _sys_errlist[];
unsigned int* __p__osver(void);
unsigned int* __p__winver(void);
unsigned int* __p__winmajor(void);
unsigned int* __p__winminor(void);
unsigned int _osver;
unsigned int _winver;
unsigned int _winmajor;
unsigned int _winminor;
char** __p__pgmptr(void);
wchar_t** __p__wpgmptr(void);
int _fmode;
double atof (const char*);
int atoi (const char*);
long atol (const char*);
double _wtof (const wchar_t *);
int _wtoi (const wchar_t *);
long _wtol (const wchar_t *);
double __strtod (const char*, char**);
double strtod (const char* __restrict__ __nptr, char** __restrict__ __endptr);
float strtof (const char * __restrict__, char ** __restrict__);
long double strtold (const char * __restrict__, char ** __restrict__);
long strtol (const char*, char**, int);
unsigned long strtoul (const char*, char**, int);
long wcstol (const wchar_t*, wchar_t**, int);
unsigned long wcstoul (const wchar_t*, wchar_t**, int);
double wcstod (const wchar_t*, wchar_t**);
float wcstof( const wchar_t * __restrict__, wchar_t ** __restrict__);
long double wcstold (const wchar_t * __restrict__, wchar_t ** __restrict__);
wchar_t* _wgetenv(const wchar_t*);
int _wputenv(const wchar_t*);
void _wsearchenv(const wchar_t*, const wchar_t*, wchar_t*);
int _wsystem(const wchar_t*);
void _wmakepath(wchar_t*, const wchar_t*, const wchar_t*, const wchar_t*, const wchar_t*);
void _wsplitpath (const wchar_t*, wchar_t*, wchar_t*, wchar_t*, wchar_t*);
wchar_t* _wfullpath (wchar_t*, const wchar_t*, size_t);
size_t wcstombs (char*, const wchar_t*, size_t);
int wctomb (char*, wchar_t);
int mblen (const char*, size_t);
size_t mbstowcs (wchar_t*, const char*, size_t);
int mbtowc (wchar_t*, const char*, size_t);
int rand (void);
void srand (unsigned int);
void* calloc (size_t, size_t);
void* malloc (size_t);
void* realloc (void*, size_t);
void free (void*);
void abort (void);
void exit (int);
int atexit (void (*)(void));
int system (const char*);
char* getenv (const char*);
void* bsearch (const void*, const void*, size_t, size_t, int (*)(const void*, const void*));
void qsort(void*, size_t, size_t, int (*)(const void*, const void*));
int abs (int);
long labs (long);
typedef struct { int quot, rem; } div_t;
typedef struct { long quot, rem; } ldiv_t;
div_t div (int, int);
ldiv_t ldiv (long, long);
void _beep (unsigned int, unsigned int);
void _seterrormode (int);
void _sleep (unsigned long);
void _exit (int);
typedef int (* _onexit_t)(void);
_onexit_t _onexit( _onexit_t );
int _putenv (const char*);
void _searchenv (const char*, const char*, char*);
char* _ecvt (double, int, int*, int*);
char* _fcvt (double, int, int*, int*);
char* _gcvt (double, int, char*);
void _makepath (char*, const char*, const char*, const char*, const char*);
void _splitpath (const char*, char*, char*, char*, char*);
char* _fullpath (char*, const char*, size_t);
char* _itoa (int, char*, int);
char* _ltoa (long, char*, int);
char* _ultoa(unsigned long, char*, int);
wchar_t* _itow (int, wchar_t*, int);
wchar_t* _ltow (long, wchar_t*, int);
wchar_t* _ultow (unsigned long, wchar_t*, int);
long long _atoi64(const char *);
char* _i64toa(long long, char *, int);
char* _ui64toa(unsigned long long, char *, int);
long long _wtoi64(const wchar_t *);
wchar_t* _i64tow(long long, wchar_t *, int);
wchar_t* _ui64tow(unsigned long long, wchar_t *, int);
unsigned int (_rotl)(unsigned int, int);
unsigned int (_rotr)(unsigned int, int);
unsigned long (_lrotl)(unsigned long, int);
unsigned long (_lrotr)(unsigned long, int);
int _set_error_mode (int);
int putenv (const char*);
void searchenv (const char*, const char*, char*);
char* itoa (int, char*, int);
char* ltoa (long, char*, int);
char* ecvt (double, int, int*, int*);
char* fcvt (double, int, int*, int*);
char* gcvt (double, int, char*);
void _Exit(int);
typedef struct { long long quot, rem; } lldiv_t;
lldiv_t lldiv (long long, long long);
long long llabs(long long);
long long strtoll (const char* __restrict__, char** __restrict, int);
unsigned long long strtoull (const char* __restrict__, char** __restrict__, int);
long long atoll (const char *);
long long wtoll (const wchar_t *);
char* lltoa (long long, char *, int);
char* ulltoa (unsigned long long , char *, int);
wchar_t* lltow (long long, wchar_t *, int);
wchar_t* ulltow (unsigned long long, wchar_t *, int);
]]
