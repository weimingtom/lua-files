#log: changed force_inline to inline in pixman-combine-float.c
#log: removed stdint.h to allow the gcc one

gcc -shared -o ../../bin/pixman.dll -Wall -O2 -I. \
	-mmmx -msse2 -mfpmath=sse -DUSE_X86_MMX -DUSE_SSE2 \
	-DPACKAGE=pixman -DPACKAGE_VERSION=HEAD \
	pixman.c			\
	pixman-access.c			\
	pixman-access-accessors.c	\
	pixman-bits-image.c		\
	pixman-combine32.c		\
	pixman-combine-float.c		\
	pixman-conical-gradient.c	\
	pixman-x86.c			\
	pixman-arm.c			\
	pixman-ppc.c			\
	pixman-mips.c			\
	pixman-edge.c			\
	pixman-edge-accessors.c		\
	pixman-fast-path.c		\
	pixman-glyph.c			\
	pixman-general.c		\
	pixman-gradient-walker.c	\
	pixman-image.c			\
	pixman-implementation.c		\
	pixman-linear-gradient.c	\
	pixman-matrix.c			\
	pixman-noop.c			\
	pixman-radial-gradient.c	\
	pixman-region16.c		\
	pixman-region32.c		\
	pixman-solid-fill.c		\
	pixman-timer.c			\
	pixman-trap.c			\
	pixman-utils.c			\
	pixman-mmx.c \
	pixman-sse2.c
