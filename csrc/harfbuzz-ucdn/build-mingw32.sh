gcc -shared -o ../../bin/ucdn.dll -s -O3 ucdn.c

cd ../.. && linux/bin/luajit ucdn.lua
