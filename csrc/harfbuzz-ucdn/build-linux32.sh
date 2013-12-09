#TODO: remove the MINGW32 hack
gcc -shared -o ../../linux/bin/libucdn.so -s -O3 -D__MINGW32__ ucdn.c

cd ../.. && linux/bin/luajit ucdn.lua
