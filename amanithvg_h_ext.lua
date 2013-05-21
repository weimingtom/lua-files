--result of `cpp vgext.h` from AmanithVg/include/VG/vgext.h, file date 12/11/2010
local ffi = require'ffi'
require'openvg_h'

ffi.cdef[[
typedef enum {
  VG_MAX_AVERAGE_BLUR_DIMENSION_KHR = 0x116B,
  VG_AVERAGE_BLUR_DIMENSION_RESOLUTION_KHR = 0x116C,
  VG_MAX_AVERAGE_BLUR_ITERATIONS_KHR = 0x116D,
  VG_PARAM_TYPE_KHR_FORCE_SIZE = 0x7FFFFFFF
} VGParamTypeKHR;
typedef void* VGeglImageKHR;
VGImage vgCreateEGLImageTargetKHR(VGeglImageKHR image);
typedef VGImage (* PFNVGCREATEEGLIMAGETARGETKHRPROC) (VGeglImageKHR image);
void vgIterativeAverageBlurKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGTilingMode tilingMode);
typedef void (* PFNVGITERATIVEAVERAGEBLURKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGTilingMode tilingMode);
typedef enum {
  VG_BLEND_OVERLAY_KHR = 0x2010,
  VG_BLEND_HARDLIGHT_KHR = 0x2011,
  VG_BLEND_SOFTLIGHT_SVG_KHR = 0x2012,
  VG_BLEND_SOFTLIGHT_KHR = 0x2013,
  VG_BLEND_COLORDODGE_KHR = 0x2014,
  VG_BLEND_COLORBURN_KHR = 0x2015,
  VG_BLEND_DIFFERENCE_KHR = 0x2016,
  VG_BLEND_SUBTRACT_KHR = 0x2017,
  VG_BLEND_INVERT_KHR = 0x2018,
  VG_BLEND_EXCLUSION_KHR = 0x2019,
  VG_BLEND_LINEARDODGE_KHR = 0x201a,
  VG_BLEND_LINEARBURN_KHR = 0x201b,
  VG_BLEND_VIVIDLIGHT_KHR = 0x201c,
  VG_BLEND_LINEARLIGHT_KHR = 0x201d,
  VG_BLEND_PINLIGHT_KHR = 0x201e,
  VG_BLEND_HARDMIX_KHR = 0x201f,
  VG_BLEND_CLEAR_KHR = 0x2020,
  VG_BLEND_DST_KHR = 0x2021,
  VG_BLEND_SRC_OUT_KHR = 0x2022,
  VG_BLEND_DST_OUT_KHR = 0x2023,
  VG_BLEND_SRC_ATOP_KHR = 0x2024,
  VG_BLEND_DST_ATOP_KHR = 0x2025,
  VG_BLEND_XOR_KHR = 0x2026,
  VG_BLEND_MODE_KHR_FORCE_SIZE= 0x7FFFFFFF
} VGBlendModeKHR;
typedef enum {
  VG_PF_OBJECT_VISIBLE_FLAG_KHR = (1 << 0),
  VG_PF_KNOCKOUT_FLAG_KHR = (1 << 1),
  VG_PF_OUTER_FLAG_KHR = (1 << 2),
  VG_PF_INNER_FLAG_KHR = (1 << 3),
  VG_PF_TYPE_KHR_FORCE_SIZE = 0x7FFFFFFF
} VGPfTypeKHR;
typedef enum {
  VGU_IMAGE_IN_USE_ERROR = 0xF010,
  VGU_ERROR_CODE_KHR_FORCE_SIZE = 0x7FFFFFFF
} VGUErrorCodeKHR;
void vgParametricFilterKHR(VGImage dst,VGImage src,VGImage blur,VGfloat strength,VGfloat offsetX,VGfloat offsetY,VGbitfield filterFlags,VGPaint highlightPaint,VGPaint shadowPaint);
VGUErrorCode vguDropShadowKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint shadowColorRGBA);
VGUErrorCode vguGlowKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint glowColorRGBA);
VGUErrorCode vguBevelKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint highlightColorRGBA,VGuint shadowColorRGBA);
VGUErrorCode vguGradientGlowKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint stopsCount,const VGfloat* glowColorRampStops);
VGUErrorCode vguGradientBevelKHR(VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint stopsCount,const VGfloat* bevelColorRampStops);
typedef void (* PFNVGPARAMETRICFILTERKHRPROC) (VGImage dst,VGImage src,VGImage blur,VGfloat strength,VGfloat offsetX,VGfloat offsetY,VGbitfield filterFlags,VGPaint highlightPaint,VGPaint shadowPaint);
typedef VGUErrorCode (* PFNVGUDROPSHADOWKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint shadowColorRGBA);
typedef VGUErrorCode (* PFNVGUGLOWKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint glowColorRGBA);
typedef VGUErrorCode (* PFNVGUBEVELKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint highlightColorRGBA,VGuint shadowColorRGBA);
typedef VGUErrorCode (* PFNVGUGRADIENTGLOWKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint stopsCount,const VGfloat* glowColorRampStops);
typedef VGUErrorCode (* PFNVGUGRADIENTBEVELKHRPROC) (VGImage dst,VGImage src,VGfloat dimX,VGfloat dimY,VGuint iterative,VGfloat strength,VGfloat distance,VGfloat angle,VGbitfield filterFlags,VGbitfield allowedQuality,VGuint stopsCount,const VGfloat* bevelColorRampStops);
typedef enum {
  VG_PAINT_COLOR_RAMP_LINEAR_NDS = 0x1A10,
  VG_COLOR_MATRIX_NDS = 0x1A11,
  VG_PAINT_COLOR_TRANSFORM_LINEAR_NDS = 0x1A12,
  VG_PAINT_PARAM_TYPE_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGPaintParamTypeNds;
typedef enum {
  VG_DRAW_IMAGE_COLOR_MATRIX_NDS = 0x1F10,
  VG_IMAGE_MODE_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGImageModeNds;
typedef enum {
  VG_CLIP_MODE_NDS = 0x1180,
  VG_CLIP_LINES_NDS = 0x1181,
  VG_MAX_CLIP_LINES_NDS = 0x1182,
  VG_PARAM_TYPE_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGParamTypeNds;
typedef enum {
  VG_CLIPMODE_NONE_NDS = 0x3000,
  VG_CLIPMODE_CLIP_CLOSED_NDS = 0x3001,
  VG_CLIPMODE_CLIP_OPEN_NDS = 0x3002,
  VG_CLIPMODE_CULL_NDS = 0x3003,
  VG_CLIPMODE_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGClipModeNds;
typedef enum {
  VG_RQUAD_TO_NDS = ( 13 << 1 ),
  VG_RCUBIC_TO_NDS = ( 14 << 1 ),
  VG_PATH_SEGMENT_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGPathSegmentNds;
typedef enum {
  VG_RQUAD_TO_ABS_NDS = (VG_RQUAD_TO_NDS | VG_ABSOLUTE),
  VG_RQUAD_TO_REL_NDS = (VG_RQUAD_TO_NDS | VG_RELATIVE),
  VG_RCUBIC_TO_ABS_NDS = (VG_RCUBIC_TO_NDS | VG_ABSOLUTE),
  VG_RCUBIC_TO_REL_NDS = (VG_RCUBIC_TO_NDS | VG_RELATIVE),
  VG_PATH_COMMAND_NDS_FORCE_SIZE = 0x7FFFFFFF
} VGPathCommandNds;
void vgProjectiveMatrixNDS(VGboolean enable);
VGUErrorCode vguTransformClipLineNDS(const VGfloat Ain,const VGfloat Bin,const VGfloat Cin,const VGfloat* matrix,const VGboolean inverse,VGfloat* Aout,VGfloat* Bout,VGfloat* Cout);
typedef void (* PFNVGPROJECTIVEMATRIXNDSPROC) (VGboolean enable);
typedef VGUErrorCode (* PFNVGUTRANSFORMCLIPLINENDSPROC) (const VGfloat Ain,const VGfloat Bin,const VGfloat Cin,const VGfloat* matrix,const VGboolean inverse,VGfloat* Aout,VGfloat* Bout,VGfloat* Cout);
typedef enum {
    VG_STROKE_START_CAP_STYLE_MZT = 0x1192,
    VG_STROKE_END_CAP_STYLE_MZT = 0x1193,
    VG_PARAM_TYPE0_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGParamType0Mzt;
typedef enum {
    VG_STROKE_BLEND_MODE_MZT = 0x1190,
    VG_FILL_BLEND_MODE_MZT = 0x1191,
    VG_PARAM_TYPE1_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGParamType1Mzt;
typedef enum {
    VG_PAINT_COLOR_RAMP_INTERPOLATION_TYPE_MZT = 0x1A91,
    VG_PAINT_PARAM_TYPE0_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGPaintParamType0Mzt;
typedef enum {
    VG_COLOR_RAMP_INTERPOLATION_LINEAR_MZT = 0x1C90,
    VG_COLOR_RAMP_INTERPOLATION_SMOOTH_MZT = 0x1C91,
    VG_COLOR_RAMP_INTERPOLATION_TYPE_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGColorRampInterpolationTypeMzt;
typedef enum {
    VG_PAINT_CONICAL_GRADIENT_MZT = 0x1A90,
    VG_PAINT_PARAM_TYPE2_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGPaintParamType2Mzt;
typedef enum {
    VG_PAINT_TYPE_CONICAL_GRADIENT_MZT = 0x1B90,
    VG_PAINT_TYPE_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGPaintTypeMzt;
typedef enum {
    VG_BLEND_CLEAR_MZT = 0x2090,
    VG_BLEND_DST_MZT = 0x2091,
    VG_BLEND_SRC_OUT_MZT = 0x2092,
    VG_BLEND_DST_OUT_MZT = 0x2093,
    VG_BLEND_SRC_ATOP_MZT = 0x2094,
    VG_BLEND_DST_ATOP_MZT = 0x2095,
    VG_BLEND_XOR_MZT = 0x2096,
    VG_BLEND_OVERLAY_MZT = 0x2097,
    VG_BLEND_COLOR_DODGE_MZT = 0x2098,
    VG_BLEND_COLOR_BURN_MZT = 0x2099,
    VG_BLEND_HARD_LIGHT_MZT = 0x209A,
    VG_BLEND_SOFT_LIGHT_MZT = 0x209B,
    VG_BLEND_DIFFERENCE_MZT = 0x209C,
    VG_BLEND_EXCLUSION_MZT = 0x209D,
    VG_BLEND_MODE_MZT_FORCE_SIZE = 0x7FFFFFFF
} VGBlendModeMzt;
void* vgPrivContextCreateAM(void *_sharedContext);
void vgPrivContextDestroyAM(void *_context);
void* vgPrivSurfaceCreateAM(VGint width, VGint height, VGboolean linearColorSpace, VGboolean alphaMask);
void* vgPrivSurfaceCreateFromImageAM(VGImage image, VGboolean alphaMask);
VGboolean vgPrivSurfaceResizeAM(void *_surface, VGint width, VGint height);
void vgPrivSurfaceDestroyAM(void *_surface);
VGint vgPrivGetSurfaceWidthAM(const void *_surface);
VGint vgPrivGetSurfaceHeightAM(const void *_surface);
VGboolean vgPrivMakeCurrentAM(void *_context, void *_surface);
VGboolean vgInitContextAM(VGint surfaceWidth, VGint surfaceHeight, VGboolean surfaceLinearColorSpace);
void vgDestroyContextAM(void);
VGboolean vgResizeSurfaceAM(VGint surfaceWidth, VGint surfaceHeight);
VGint vgGetSurfaceWidthAM(void);
VGint vgGetSurfaceHeightAM(void);
VGImageFormat vgGetSurfaceFormatAM(void);
VGubyte* vgGetSurfacePixelsAM(void);
void vgPostSwapBuffersAM(void);
]]
