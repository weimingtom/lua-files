gcc *.c -O3 -s -o ../../bin/socket_core.dll -shared -I. -I../lua -L../../bin -llua51 -lwsock32
