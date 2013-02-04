mkdir -p ../../bin/lanes
gcc *.c -O3 -s -o ../../bin/lanes/core.dll -shared -llua51 -L../../bin -I. -I../lua -DNDEBUG
