mkdir -p ../../bin/lanes
gcc *.c -o ../../bin/lanes/core.dll -shared -llua51 -L../../bin -I. -I../lua -O2 -DNDEBUG
