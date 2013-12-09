# harfbuzz build with opentype, ucdn, freetype. dynamically links to ucdn and freetype.
# TODO: remove the __MINGW32__ hack

cd src || exit 1

for f in `ls *.rl`; do
	if [ ! -f "${f%.*}.hh" ]; then
		ragel "$f" -e -F1 -o "${f%.*}.hh"
	fi
done

gcc \
	hb-blob.cc \
	hb-buffer.cc \
	hb-buffer-serialize.cc \
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
	\
	-I. \
	-DHAVE_OT \
	-DHAVE_INTEL_ATOMIC_PRIMITIVES \
	-DHAVE_UCDN \
	-I../../freetype/include \
	-I../../harfbuzz-ucdn \
	-L../../../linux/bin \
	-lucdn \
	-D__MINGW32__ \
	-lfreetype \
	-fno-exceptions -fno-rtti \
	-O3 -s -shared -o ../../../linux/bin/libharfbuzz.so
