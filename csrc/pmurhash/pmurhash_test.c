//go@ gcc pmurhash_test.c -O5 -o pmurhash.exe -I../../csrc/pmurhash -L../../bin -lpmurhash

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include "PMurHash.h"

void main() {
	int sz = 1024 * 1024;
	int iter = 1024;
	void* key = malloc(sz);
	int h = 0;
	int i;
	unsigned int tick = GetTickCount();
	unsigned int tick2;
	for(i=1;i<=iter;i++) {
		PMurHash32(h, key, sz);
	}
	tick2 = GetTickCount();
	printf("%f MB/s\n", 1024.0 * 1000 / (tick2 - tick + 1));
}
