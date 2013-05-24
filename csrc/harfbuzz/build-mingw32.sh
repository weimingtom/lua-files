# harfbuzz build with opentype, ucdn, freetype

for f in `ls *.rl`; do
	if [ ! -f "${f%.*}.hh" ]; then
		ragel "$f" -e -F1 -o "${f%.*}.hh"
	fi
done

gcc \
	hb-blob.cc \
	hb-buffer.cc \
	hb-common.cc \
	hb-set.cc \
	hb-ft.cc \
	hb-font.cc \
	hb-ot*.cc \
	hb-fallback-shape.cc \
	hb-shape-plan.cc \
	hb-shape.cc \
	hb-shaper.cc \
	hb-tt-font.cc \
	hb-unicode.cc \
	hb-warning.cc \
	hb-ucdn.cc \
	hb-ucdn/ucdn.c \
	\
	-I. \
	-Ihb-ucdn \
	-DHAVE_OT \
	-DHAVE_UCDN \
	-I../freetype \
	-L../../bin \
	-lfreetype-6 \
	-fno-exceptions -fno-rtti \
	-O3 -s -shared -o ../../bin/harfbuzz.dll
