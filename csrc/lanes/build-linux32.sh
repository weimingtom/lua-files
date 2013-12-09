mkdir -p ../../bin/lanes
gcc *.c -O3 -s -o ../../linux/bin/lanes/core.so -shared -lluajit -L../../linux/bin -I. -I../lua -DNDEBUG
