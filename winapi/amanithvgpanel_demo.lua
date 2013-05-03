local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.messageloop'
require'winapi.amanithvgpanel'
local gl = require'winapi.gl11'
local vg = require'amanithvg'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	title = 'AmanithVGPanel test'
}

local panel = winapi.AmanithVGPanel{
	anchors = {left = true, top = true, right = true, bottom = true},
	visible = false,
}

function main:init()
	panel.w = self.client_w
	panel.h = self.client_h
	panel.parent = self
	panel.visible = true
	self.visible = true
	panel:settimer(1/60, panel.invalidate)
end

function panel:set_viewport()
	--set default viewport
	local w, h = self.client_w, self.client_h
	gl.glViewport(0, 0, w, h)
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
	gl.glScaled(1, w/h, 1)
end

r = 1
function panel:on_render()
	r = r + 1

	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_SRC_ALPHA)
	gl.glDisable(gl.GL_DEPTH_TEST)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glDisable(gl.GL_LIGHTING)

	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()

	gl.glTranslated(0,0,-1)
	--gl.glRotated(r,1,0,0)
	--gl.glTranslated(-5500,-5500,-r)

	vg.vgSeti(vg.VG_RENDERING_QUALITY, vg.VG_RENDERING_QUALITY_BETTER)
	vg.vgSeti(vg.VG_BLEND_MODE, vg.VG_BLEND_SRC)
	vg.vgClear(0, 0, self.client_w, self.client_h)
	vg.vgSeti(vg.VG_MATRIX_MODE, vg.VG_MATRIX_PATH_USER_TO_SURFACE)
	vg.vgLoadIdentity()

	---------------------------------------------------------------------------
	--TODO: make some demos from here: http://www.amanithvg.com/testsuite/amanithvg_gle/tests/

	local ffi = require'ffi'
	local bit = require'bit'

	local starSegments = ffi.new('VGubyte[?]', 6,
     vg.VG_MOVE_TO_ABS,
     vg.VG_LINE_TO_REL,
     vg.VG_LINE_TO_REL,
     vg.VG_LINE_TO_REL,
     vg.VG_LINE_TO_REL,
     vg.VG_CLOSE_PATH)

	local starCoords = ffi.new('VGfloat[?]', 10,
     110, 35,
     50, 160,
     -130, -100,
     160, 0,
     -130, 100)

	local path = vg.vgCreatePath(vg.VG_PATH_FORMAT_STANDARD,
							  vg.VG_PATH_DATATYPE_F,
							  1.0,  -- scale
							  0.0,  -- bias
							  6,    -- segmentCapacityHint
							  10,   -- coordCapacityHint
							  vg.VG_PATH_CAPABILITY_ALL)
	vg.vgAppendPathData(path, ffi.sizeof(starSegments), starSegments, starCoords)

	local col = ffi.new('VGfloat[?]', 4, 1, 1, 1, 1)
	vg.vgSetfv(vg.VG_CLEAR_COLOR, 4, col)
	vg.vgSeti(vg.VG_BLEND_MODE, vg.VG_BLEND_SRC_OVER)
	vg.vgSeti(vg.VG_MASKING, vg.VG_FALSE)

	local col = ffi.new('VGfloat[?]', 4, 0, 0, 0, 1)
	local strokePaint = vg.vgCreatePaint()
	vg.vgSetParameteri(strokePaint, vg.VG_PAINT_TYPE, vg.VG_PAINT_TYPE_COLOR)
	vg.vgSetParameterfv(strokePaint, vg.VG_PAINT_COLOR, 4, col)
	vg.vgSetPaint(strokePaint, vg.VG_STROKE_PATH)

	vg.vgClear(0, 0, 256, 256)
	vg.vgDrawPath(path, bit.bor(vg.VG_FILL_PATH, vg.VG_STROKE_PATH))

end

main:init()

os.exit(winapi.MessageLoop())

