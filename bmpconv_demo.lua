local player = require'cairo_player'
local glue = require'glue'
local stdio = require'stdio'
local ffi = require'ffi'
local bmpconv = require'bmpconv'

local function load_bmp(filename)
	local bmp = stdio.readfile(filename)
	assert(ffi.string(bmp, 2) == 'BM')
	local function read(ctype, offset)
		return ffi.cast(ctype, bmp + offset)[0]
	end
	local data = bmp + read('uint32_t*', 0x0A)
	local w = read('int32_t*', 0x12)
	local h = read('int32_t*', 0x16)
	assert(w * h * 4 == ffi.sizeof(bmp) - (data - bmp))
	return {w = w, h = h, data = data, format = 'rgbx8', orientation = 'bottom_up', bmp = bmp}
end

local format = 'rgb8'

local function available(src_format, values)
	values = glue.index(values)
	local t = {}
	for k in pairs(values) do t[k] = false end
	for d in bmpconv.conversions(src_format) do
		t[d] = values[d]
	end
	return t
end

function player:on_render(cr)
	local img = load_bmp'media/bmp/good/rgb32.bmp'

	local v1 = {
		'rgb8', 'bgr8', 'rgb16', 'bgr16',
		'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'rgbx16', 'bgrx16', 'xrgb16', 'xbgr16',
		'rgba8', 'bgra8', 'argb8', 'abgr8',
		'rgba16', 'bgra16', 'argb16', 'abgr16',
	}
	local e1 = available(img.format, v1)
	local format1 = self:mbutton{id = 'format1', x = 10, y = 10, w = 990, h = 24,
						values = v1, enabled = e1, selected = format}
	local v2 = {
		'rgb565', 'rgb555', 'rgb444', 'rgba4444', 'rgba5551',
		'g1', 'g2', 'g4', 'g8', 'g16',
		'ga8', 'ag8', 'ga16', 'ag16',
		'cmyk8',
		'ycc8',
		'ycck8',
	}
	local e2 = available(img.format, v2)
	local format2 = self:mbutton{id = 'format2', x = 10, y = 40, w = 990, h = 24,
						values = v2, enabled = e2, selected = format}
	format = format2 ~= format and format2 or format1

	local dst = bmpconv.new{w = img.w, h = img.h, orientation = img.orientation, format = format}
	bmpconv.convert(img, dst)
	self:image{x = 10, y = 80, image = dst}
end

player:play()

