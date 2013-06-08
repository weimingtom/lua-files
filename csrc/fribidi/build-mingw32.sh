gcc -shared -O3 -s -o ../../bin/fribidi.dll -I. -Wall -ansi -DHAVE_CONFIG_H *.c

#note: FRIBIDI_CHARSETS = 0, DEBUG = 0
