gcc -shared -O3 -s -o ../../linux/bin/chipmunk.so -Iinclude/chipmunk \
	-std=gnu99 -Wall -ffast-math -DNDEBUG -DCHIPMUNK_FFI \
	src/*.c src/constraints/*.c
