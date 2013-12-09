gcc *.c -O3 -s -I. -shared -o ../../bin/b64.dll -Wall

cd ../..
bin/luajit libb64_test.lua

