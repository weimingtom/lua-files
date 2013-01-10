gcc strbuf.c lua_cjson.c fpconv.c -o ../../bin/cjson.dll \
	-O3 -Wall -pedantic -DNDEBUG -shared \
	-I../lua -L../../bin -llua51 \
	-DDISABLE_INVALID_NUMBERS
