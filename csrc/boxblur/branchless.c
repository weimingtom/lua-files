//branchless min & max from http://hbfs.wordpress.com/2008/08/05/branchless-equivalents-of-simple-functions/

static inline int32_t sex(int32_t x) {
	union {
		int64_t w;
		struct { int32_t lo, hi; };
	} z = { .w = x };
	return z.hi;
}

static inline int32_t min(int32_t a, int32_t b) {
	return b + ((a-b) & sex(a-b));
}

static inline int32_t max(int32_t a, int32_t b) {
	return a + ((b-a) & ~sex(b-a));
}

