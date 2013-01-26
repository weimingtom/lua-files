gcc sha2.c -O3 -I. -shared -o ../../bin/sha2.dll -DSHA2_USE_INTTYPES_H -DBYTE_ORDER -DLITTLE_ENDIAN
