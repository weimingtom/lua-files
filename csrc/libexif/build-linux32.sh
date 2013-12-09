gcc -s -O3 -shared -o ../../linux/bin/libexif.so -g -Wall libexif/*.c libexif/*/*.c -I. -D__WATCOMC__

cd ../.. && linux/bin/luajit libexif.lua
