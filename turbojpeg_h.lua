--cpp of turbojpeg.h from libjpeg-turbo 1.2.1
--added JPEGBUF type defined as const so we can pass Lua strings (hope tj doesn't write to it)
local ffi = require'ffi'
ffi.cdef[[
enum TJSAMP
{
  TJSAMP_444=0,
  TJSAMP_422,
  TJSAMP_420,
  TJSAMP_GRAY,
  TJSAMP_440
};
enum TJPF
{
  TJPF_RGB=0,
  TJPF_BGR,
  TJPF_RGBX,
  TJPF_BGRX,
  TJPF_XBGR,
  TJPF_XRGB,
  TJPF_GRAY,
  TJPF_RGBA,
  TJPF_BGRA,
  TJPF_ABGR,
  TJPF_ARGB
};
enum TJXOP
{
  TJXOP_NONE=0,
  TJXOP_HFLIP,
  TJXOP_VFLIP,
  TJXOP_TRANSPOSE,
  TJXOP_TRANSVERSE,
  TJXOP_ROT90,
  TJXOP_ROT180,
  TJXOP_ROT270
};
enum
{
  TJ_NUMSAMP = 5,
  TJ_NUMPF = 11,
  TJFLAG_BOTTOMUP =        2,
  TJFLAG_FORCEMMX =        8,
  TJFLAG_FORCESSE =       16,
  TJFLAG_FORCESSE2 =      32,
  TJFLAG_FORCESSE3 =     128,
  TJFLAG_FASTUPSAMPLE =  256,
  TJFLAG_NOREALLOC =     1024,
  TJFLAG_FASTDCT =       2048,
  TJFLAG_ACCURATEDCT =   4096,
  TJ_NUMXOP = 8,
  TJXOPT_PERFECT =  1,
  TJXOPT_TRIM =     2,
  TJXOPT_CROP =     4,
  TJXOPT_GRAY =     8,
  TJXOPT_NOOUTPUT = 16,
};

typedef struct
{
  int num;
  int denom;
} tjscalingfactor;

typedef struct
{
  int x;
  int y;
  int w;
  int h;
} tjregion;

typedef struct tjtransform
{
  tjregion r;
  int op;
  int options;
  void *data;
  int (*customFilter)(short *coeffs, tjregion arrayRegion,
    tjregion planeRegion, int componentIndex, int transformIndex,
    struct tjtransform *transform);
} tjtransform;

typedef void* tjhandle;
typedef const unsigned char* JPEGBUF;

tjhandle tjInitCompress(void);

int tjCompress2(tjhandle handle, JPEGBUF srcBuf,
  int width, int pitch, int height, int pixelFormat, JPEGBUF* jpegBuf,
  unsigned long *jpegSize, int jpegSubsamp, int jpegQual, int flags);

unsigned long tjBufSize(int width, int height, int jpegSubsamp);

unsigned long tjBufSizeYUV(int width, int height, int subsamp);

int tjEncodeYUV2(tjhandle handle,
  JPEGBUF srcBuf, int width, int pitch, int height, int pixelFormat,
  unsigned char *dstBuf, int subsamp, int flags);

tjhandle tjInitDecompress(void);

int tjDecompressHeader2(tjhandle handle,
  JPEGBUF jpegBuf, unsigned long jpegSize, int *width, int *height,
  int *jpegSubsamp);

tjscalingfactor* tjGetScalingFactors(int *numscalingfactors);

int tjDecompress2(tjhandle handle,
  JPEGBUF jpegBuf, unsigned long jpegSize, unsigned char *dstBuf,
  int width, int pitch, int height, int pixelFormat, int flags);

int tjDecompressToYUV(tjhandle handle,
  JPEGBUF jpegBuf, unsigned long jpegSize, unsigned char *dstBuf,
  int flags);

tjhandle tjInitTransform(void);

int tjTransform(tjhandle handle, JPEGBUF jpegBuf,
  unsigned long jpegSize, int n, unsigned char **dstBufs,
  unsigned long *dstSizes, tjtransform *transforms, int flags);

int tjDestroy(tjhandle handle);

unsigned char* tjAlloc(int bytes);

void tjFree(unsigned char *buffer);

char* tjGetErrorStr(void);

unsigned long TJBUFSIZE(int width, int height);

unsigned long TJBUFSIZEYUV(int width, int height, int jpegSubsamp);

int tjCompress(tjhandle handle, JPEGBUF srcBuf,
  int width, int pitch, int height, int pixelSize, unsigned char *dstBuf,
  unsigned long *compressedSize, int jpegSubsamp, int jpegQual, int flags);

int tjEncodeYUV(tjhandle handle,
  JPEGBUF srcBuf, int width, int pitch, int height, int pixelSize,
  unsigned char *dstBuf, int subsamp, int flags);

int tjDecompressHeader(tjhandle handle,
  JPEGBUF jpegBuf, unsigned long jpegSize, int *width, int *height);

int tjDecompress(tjhandle handle,
  JPEGBUF jpegBuf, unsigned long jpegSize, unsigned char *dstBuf,
  int width, int pitch, int height, int pixelSize, int flags);

]]

--[[ unused constants and macros
local tjMCUWidth = {8, 16, 16, 8, 8}
local tjMCUHeight = {8, 8, 16, 8, 16}
local tjRedOffset = {0, 2, 0, 2, 3, 1, 0, 0, 2, 3, 1}
local tjGreenOffset = {1, 1, 1, 1, 2, 2, 0, 1, 1, 2, 2}
local tjBlueOffset = {2, 0, 2, 0, 1, 3, 0, 2, 0, 1, 3}
]]
