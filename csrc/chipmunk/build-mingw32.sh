# NOTE: pass -DNDEBUG to disable runtime assertions
gcc -shared -O3 -s -o ../../bin/chipmunk.dll -Iinclude/chipmunk -std=gnu99 -Wall -ffast-math src/*.c src/constraints/*.c
