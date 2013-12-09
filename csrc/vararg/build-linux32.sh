gcc vararg.c -O3 -s -o ../../linux/bin/vararg.so -shared -ansi -I../lua -L../../bin

../../linux/bin/luajit vararg_test.lua
