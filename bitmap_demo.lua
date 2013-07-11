local player = require'cairo_player'
local glue = require'glue'
local stdio = require'stdio'
local ffi = require'ffi'
local bitmap = require'bitmap'

bitmap.dumpinfo()

local function load_bmp(filename)
	local bmp = stdio.readfile(filename)
	assert(ffi.string(bmp, 2) == 'BM')
	local function read(ctype, offset)
		return ffi.cast(ctype, bmp + offset)[0]
	end
	local data = bmp + read('uint32_t*', 0x0A)
	local w = read('int32_t*', 0x12)
	local h = read('int32_t*', 0x16)
	local stride = bitmap.aligned_stride(w * 3)
	local size = stride * h
	assert(size == ffi.sizeof(bmp) - (data - bmp))
	return {w = w, h = h, stride = stride, data = data, size = size, format = 'bgr8', bottom_up = true, bmp = bmp}
end

local function available(src_format, values)
	values = glue.index(values)
	local t = {}
	for k in pairs(values) do t[k] = false end
	for d in bitmap.conversions(src_format) do
		t[d] = values[d]
	end
	return t
end

function player:on_render(cr)

	local img = load_bmp'media/bmp/bg.bmp'
	--local img = load_bmp'media/bmp/parrot.bmp'

	--apply dithering

	self.method = self:mbutton{id = 'method', x = 10 + img.w + 10, y = 70, w = 190, h = 24,
										values = {'fs', 'ordered', 'none'}, selected = self.method or 'ordered'}

	if self.method == 'fs' then
		local oldrbits = self.rbits
		self.rbits = self:slider{id = 'rbits', x = 10 + img.w + 10, y = 100, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.rbits or 4, text = 'r bits'}
		if oldrbits ~= self.rbits then
			self.gbits = self.rbits
			self.bbits = self.rbits
			self.abits = self.rbits
		end
		self.gbits = self:slider{id = 'gbits', x = 10 + img.w + 10, y = 130, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.gbits or 4, text = 'g bits'}
		self.bbits = self:slider{id = 'bbits', x = 10 + img.w + 10, y = 160, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.bbits or 4, text = 'b bits'}
		self.abits = self:slider{id = 'abits', x = 10 + img.w + 10, y = 190, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.abits or 4, text = 'a bits'}

		bitmap.dither.fs(img, self.rbits, self.gbits, self.bbits, self.abits)

	elseif self.method == 'ordered' then
		self.map = self:mbutton{id = 'map', x = 10 + img.w + 10, y = 100, w = 190, h = 24,
											values = {2, 3, 4, 8}, selected = self.map or 4}

		bitmap.dither.ordered(img, self.map)
	end

	--clip the low bits

	self.bits = self:slider{id = 'bits', x = 10 + img.w + 10,
										y = self.method == 'fs' and 220 or self.method == 'ordered' and 130 or 100,
										w = 190, h = 24, i0 = 0, i1 = 8, step = 1, i = self.bits or 8, text = 'out bits'}

	if self.bits < 8 then
		local c = 0xff-(2^(8-self.bits)-1)

		bitmap.convert(img, img, function(r,g,b,a)
			return bit.band(r,c), bit.band(g,c), bit.band(b,c), bit.band(a,c)
		end)
	end

	--convert to dest. format

	self.format = self.format or 'rgba8'

	local v1 = {
		'rgb8', 'bgr8', 'rgb16', 'bgr16',
		'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'rgbx16', 'bgrx16', 'xrgb16', 'xbgr16',
		'rgba8', 'bgra8', 'argb8', 'abgr8',
		'rgba16', 'bgra16', 'argb16', 'abgr16',
	}
	local e1 = available(img.format, v1)
	local format1 = self:mbutton{id = 'format1', x = 10, y = 10, w = 990, h = 24,
						values = v1, enabled = e1, selected = self.format}
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
						values = v2, enabled = e2, selected = self.format}
	self.format = format2 ~= self.format and format2 or format1

	if img.format ~= self.format then
		img = bitmap.copy(img, self.format, false, true)
	end

	self:image{x = 10, y = 80, image = img}

	if self:keypressed'ctrl' then
		self:magnifier{id = 'mag', x = self.mousex - 200, y = self.mousey - 100, w = 400, h = 200, zoom_level = 4}
	end
end

player:play()

