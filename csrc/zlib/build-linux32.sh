gcc *.c -O3 -s -shared -o ../../linux/bin/libzlib.so -I.

cd ../..
linux/bin/luajit zlib_test.lua
