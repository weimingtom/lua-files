gcc nanojpeg2.c -O3 -s -shared -o ../../linux/bin/libnanojpeg2.so -DNJ_USE_LIBC \
	-std=c99 -Wall -Wextra -pedantic -Werror
