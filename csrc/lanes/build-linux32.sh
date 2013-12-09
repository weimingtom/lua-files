mkdir -p ../../linux/bin/lanes
gcc *.c -O3 -s -o ../../linux/bin/lanes/core.so -shared -I. -I../lua -DNDEBUG
