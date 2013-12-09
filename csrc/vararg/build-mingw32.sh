gcc vararg.c -O3 -s -o ../../bin/vararg.dll -shared -ansi -I../lua -L../../bin -llua51

../../bin/luajit vararg_test.lua
