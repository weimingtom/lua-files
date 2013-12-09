gcc *.c -O3 -s -shared -o ../../bin/zlib.dll -I.

cd ../.. && bin/luajit zlib_test.lua
