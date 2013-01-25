//go@ gcc boxblur.c -O3 -o ../../bin/boxblur.dll -shared
//Box Blur Algorithm by Mario Klingemann http://incubator.quasimondo.com

#include <stdint.h>
#include <stdlib.h>
#include "branchless.c"

void box_blur_argb32(uint8_t *pix, int32_t w, int32_t h, int32_t radius) {
	if (radius < 1) return;

	int32_t rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;

	uint8_t* r = malloc(w * h);
	uint8_t* g = malloc(w * h);
	uint8_t* b = malloc(w * h);
	int32_t *vmin = malloc(max(w,h) * 4);
	int32_t *vmax = malloc(max(w,h) * 4);

	int32_t div = 2*radius+1;
	uint8_t* dv = malloc(256*div);
	for (i=0; i<256*div; i++)
		dv[i] = (i/div);

	yw = yi = 0;

	for (x=0; x<w; x++) {
		vmin[x] = min(x+radius+1,w-1);
		vmax[x] = max(x-radius,0);
	}

	for (y=0; y<h; y++) {
		rsum = gsum = bsum = 0;

		for(i=-radius; i<=radius; i++) {
			p = (yi + min(w-1, max(i,0))) * 4;
			rsum += pix[p];
			gsum += pix[p+1];
			bsum += pix[p+2];
		}

		for (x=0; x<w; x++) {
			r[yi] = dv[rsum];
			g[yi] = dv[gsum];
			b[yi] = dv[bsum];

			p1 = (yw+vmin[x])*4;
			p2 = (yw+vmax[x])*4;

			rsum += pix[p1] - pix[p2];
			gsum += pix[p1+1] - pix[p2+1];
			bsum += pix[p1+2] - pix[p2+2];

			yi++;
		}
		yw += w;
	}

	for (y=0; y<h; y++) {
		vmin[y] = min(y+radius+1,h-1)*w;
		vmax[y] = max(y-radius,0)*w;
	}

	for (x=0; x<w; x++) {
		rsum = gsum = bsum = 0;
		yp = -radius*w;

		for(i=-radius; i<=radius; i++) {
			yi = max(0,yp)+x;
			rsum += r[yi];
			gsum += g[yi];
			bsum += b[yi];
			yp += w;
		}
		yi = x;

		for (y=0; y<h; y++) {
			pix[yi*4 + 0] = dv[rsum];
			pix[yi*4 + 1] = dv[gsum];
			pix[yi*4 + 2] = dv[bsum];

			p1 = x+vmin[y];
			p2 = x+vmax[y];

			rsum += r[p1]-r[p2];
			gsum += g[p1]-g[p2];
			bsum += b[p1]-b[p2];

			yi += w;
		}
	}

	free(r);
	free(g);
	free(b);
	free(vmin);
	free(vmax);
	free(dv);
}
