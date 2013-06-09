gcc -shared -O3 -s -o ../../bin/fribidi.dll -I. -Icharset -Wall -ansi -DHAVE_CONFIG_H *.c charset/*.c
