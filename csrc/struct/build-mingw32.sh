gcc struct.c -O2 -s -o ../../bin/struct.dll -shared -I. -I../lua -ansi -L../../bin -llua51 \
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

../../bin/luajit.exe teststruct.lua
