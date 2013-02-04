gcc nanojpeg2.c -O3 -s -shared -o ../../bin/nanojpeg2.dll -DNJ_USE_LIBC \
	-std=c99 -Wall -Wextra -pedantic -Werror
