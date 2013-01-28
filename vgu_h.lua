--result of `cpp vgu.h` from khronos.org/OpenVG 1.1 Utility Library Header File, October 29, 2008
local ffi = require'ffi'
require'openvg_h'

ffi.cdef[[
typedef enum {
  VGU_NO_ERROR = 0,
  VGU_BAD_HANDLE_ERROR = 0xF000,
  VGU_ILLEGAL_ARGUMENT_ERROR = 0xF001,
  VGU_OUT_OF_MEMORY_ERROR = 0xF002,
  VGU_PATH_CAPABILITY_ERROR = 0xF003,
  VGU_BAD_WARP_ERROR = 0xF004,
  VGU_ERROR_CODE_FORCE_SIZE = 0x7FFFFFFF
} VGUErrorCode;
typedef enum {
  VGU_ARC_OPEN = 0xF100,
  VGU_ARC_CHORD = 0xF101,
  VGU_ARC_PIE = 0xF102,
  VGU_ARC_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGUArcType;
VGUErrorCode vguLine(VGPath path,
                                  VGfloat x0, VGfloat y0,
                                  VGfloat x1, VGfloat y1);
VGUErrorCode vguPolygon(VGPath path,
                                     const VGfloat* points, VGint count,
                                     VGboolean closed);
VGUErrorCode vguRect(VGPath path,
                                  VGfloat x, VGfloat y,
                                  VGfloat width, VGfloat height);
VGUErrorCode vguRoundRect(VGPath path,
                                       VGfloat x, VGfloat y,
                                       VGfloat width, VGfloat height,
                                       VGfloat arcWidth, VGfloat arcHeight);
VGUErrorCode vguEllipse(VGPath path,
                                     VGfloat cx, VGfloat cy,
                                     VGfloat width, VGfloat height);
VGUErrorCode vguArc(VGPath path,
                                 VGfloat x, VGfloat y,
                                 VGfloat width, VGfloat height,
                                 VGfloat startAngle, VGfloat angleExtent,
                                 VGUArcType arcType);
VGUErrorCode vguComputeWarpQuadToSquare(VGfloat sx0, VGfloat sy0,
                                                     VGfloat sx1, VGfloat sy1,
                                                     VGfloat sx2, VGfloat sy2,
                                                     VGfloat sx3, VGfloat sy3,
                                                     VGfloat* matrix);
VGUErrorCode vguComputeWarpSquareToQuad(VGfloat dx0, VGfloat dy0,
                                                     VGfloat dx1, VGfloat dy1,
                                                     VGfloat dx2, VGfloat dy2,
                                                     VGfloat dx3, VGfloat dy3,
                                                     VGfloat* matrix);
VGUErrorCode vguComputeWarpQuadToQuad(VGfloat dx0, VGfloat dy0,
                                                   VGfloat dx1, VGfloat dy1,
                                                   VGfloat dx2, VGfloat dy2,
                                                   VGfloat dx3, VGfloat dy3,
                                                   VGfloat sx0, VGfloat sy0,
                                                   VGfloat sx1, VGfloat sy1,
                                                   VGfloat sx2, VGfloat sy2,
                                                   VGfloat sx3, VGfloat sy3,
                                                   VGfloat* matrix);
]]
