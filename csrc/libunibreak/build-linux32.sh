gcc -O3 -s -o ../../linux/bin/libunibreak.so -shared *.c

cd ../.. && linux/bin/luajit libunibreak_demo.lua
