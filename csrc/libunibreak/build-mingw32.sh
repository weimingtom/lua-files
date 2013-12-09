gcc -O3 -s -o ../../bin/libunibreak.dll -shared *.c

cd ../.. && linux/bin/luajit libunibreak_demo.lua
