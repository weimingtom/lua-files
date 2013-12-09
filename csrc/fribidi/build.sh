[[ "$(uname)" == *Linux* ]] && libfile=../../linux/bin/libfribidi.so
[[ "$(uname)" == *MINGW* ]] && libfile=../../bin/fribidi.dll

gcc -shared -O3 -s -o "$libfile" -Isrc -Isrc/charset -Wall -ansi -DHAVE_CONFIG_H src/*.c src/charset/*.c
