gcc lpeg.c -O3 -s -o ../../bin/lpeg.dll -shared -I. -I../lua -ansi -L../../bin -llua51 \
	-Wall -Wextra -DNDEBUG
