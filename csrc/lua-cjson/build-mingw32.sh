gcc strbuf.c lua_cjson.c fpconv.c -O3 -o ../../bin/cjson.dll \
	-Wall -pedantic -DNDEBUG -shared \
	-I../lua -L../../bin -llua51 \
	-DDISABLE_INVALID_NUMBERS
