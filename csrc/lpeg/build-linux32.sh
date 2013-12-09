gcc lpeg.c -O3 -s -o ../../linux/bin/lpeg.so -shared -I. -I../lua -ansi \
	-Wall -Wextra -DNDEBUG

../../linux/bin/luajit lpeg_test.lua
