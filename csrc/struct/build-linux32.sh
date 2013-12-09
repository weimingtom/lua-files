gcc struct.c -O2 -s -o ../../linux/bin/struct.so -shared -I. -I../lua -ansi \
	-DSTRUCT_INT="long long" \
	-Wall \
	-W -pedantic \
	-Waggregate-return \
	-Wcast-align \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wpointer-arith \
	-Wshadow \
	-Wwrite-strings

../../linux/bin/luajit teststruct.lua
