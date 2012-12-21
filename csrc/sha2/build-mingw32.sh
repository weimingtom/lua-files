gcc sha2.c -I. -shared -o ../../bin/sha2.dll -O2 -DSHA2_USE_INTTYPES_H -DBYTE_ORDER -DLITTLE_ENDIAN
