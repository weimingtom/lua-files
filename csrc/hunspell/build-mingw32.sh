cd hunspell &&
g++ -shared -O3 -s -static-libgcc -static-libstdc++ -o ../../../bin/hunspell.dll -I. \
	-DHAVE_CONFIG_H -fvisibility=hidden -DBUILDING_LIBHUNSPELL=1 \
	affentry.cxx \
	affixmgr.cxx \
	csutil.cxx \
	dictmgr.cxx \
	hashmgr.cxx \
	hunspell.cxx \
	suggestmgr.cxx \
	phonet.cxx \
	filemgr.cxx \
	hunzip.cxx \
	replist.cxx \
	../extras.cxx
