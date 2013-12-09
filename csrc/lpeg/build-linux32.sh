gcc lpeg.c -O3 -s -o ../../linux/bin/lpeg.so -shared -I. -I../lua -ansi -L../../linux/bin \
	-Wall -Wextra -DNDEBUG
