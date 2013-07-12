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

	--apply dithering

	self.method = self:mbutton{id = 'method', x = 10, y = 70, w = 190, h = 24,
										values = {'fs', 'ordered', 'none'}, selected = self.method or 'ordered'}

	if self.method == 'fs' then
		local oldrbits = self.rbits
		self.rbits = self:slider{id = 'rbits', x = 10 , y = 100, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.rbits or 4, text = 'r bits'}
		if oldrbits ~= self.rbits then
			self.gbits = self.rbits
			self.bbits = self.rbits
			self.abits = self.rbits
		end
		self.gbits = self:slider{id = 'gbits', x = 10 , y = 130, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.gbits or 4, text = 'g bits'}
		self.bbits = self:slider{id = 'bbits', x = 10 , y = 160, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.bbits or 4, text = 'b bits'}
		self.abits = self:slider{id = 'abits', x = 10 , y = 190, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.abits or 4, text = 'a bits'}

	elseif self.method == 'ordered' then
		self.map = self:mbutton{id = 'map', x = 10 , y = 100, w = 190, h = 24,
											values = {2, 3, 4, 8}, selected = self.map or 4}

	end

	--clip the low bits

	self.bits = self:slider{id = 'bits', x = 10,
										y = self.method == 'fs' and 220 or self.method == 'ordered' and 130 or 100,
										w = 190, h = 24, i0 = 0, i1 = 8, step = 1, i = self.bits or 8, text = 'out bits'}

	--convert to dest. format

	self.format = self.format or 'rgba8'

	local v1 = {
		'rgb8', 'bgr8', 'rgb16', 'bgr16',
		'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'rgbx16', 'bgrx16', 'xrgb16', 'xbgr16',
		'rgba8', 'bgra8', 'argb8', 'abgr8',
		'rgba16', 'bgra16', 'argb16', 'abgr16',
	}
	local e1 = available('bgr8', v1)
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
	local e2 = available('bgr8', v2)
	local format2 = self:mbutton{id = 'format2', x = 10, y = 40, w = 990, h = 24,
						values = v2, enabled = e2, selected = self.format}
	self.format = format2 ~= self.format and format2 or format1

	--finally, perform the conversions and display up the images

	local cx, cy = 210, 70
	local function show(file)

		local img = load_bmp(file)

		if self.method == 'fs' then
			bitmap.dither.fs(img, self.rbits, self.gbits, self.bbits, self.abits)
		elseif self.method == 'ordered' then
			bitmap.dither.ordered(img, self.map)
		end

		if self.bits < 8 then
			local c = 0xff-(2^(8-self.bits)-1)
			local m = (0xff / c)
			bitmap.convert(img, img, function(r,g,b,a)
				return
					bit.band(r,c) * m,
					bit.band(g,c) * m,
					bit.band(b,c) * m,
					bit.band(a,c) * m
			end)
		end

		--[[
		local filter = {[0] =
			{[0] = -1, -1, -1},
			{[0] = 2, 2, 2},
			{[0] = -1, -1, -1}}

		local function clamp(x) return math.min(math.max(x,0),0xff) end
		local getpixel, setpixel = bitmap.pixel_interface(img)
		for y=0,img.h-1 do
			for x=0,img.w-1 do
				local r,g,b = 0,0,0
				for fy=0,#filter do
					for fx=0,#filter do
						local r0, g0, b0 = getpixel(
							(x-(#filter)/2 + fx + img.w) % img.w,
							(y-(#filter)/2 + fy + img.h) % img.h)
						local f = filter[fx][fy]
						r = r + r0 * f
						g = g + g0 * f
						b = b + b0 * f
					end
				end
				r,g,b=r/9,g/9,b/9
				setpixel(x,y,clamp(r),clamp(g),clamp(b))
			end
		end
		]]

		--self.move = (self.move or 0) + 1
		--img = bitmap.sub(img, self.move, self.move, 400, 400)

		if img.format ~= self.format then
			img = bitmap.copy(img, self.format, false, true)
		end

		self:image{x = cx, y = cy, image = img}
		cx = cx + img.w + 10
	end

	show'media/bmp/bg.bmp'
	show'media/bmp/parrot.bmp'
	show'media/bmp/rgb_3bit.bmp'
	show'media/bmp/rgb_24bit.bmp'

	if self:keypressed'ctrl' then
		self:magnifier{id = 'mag', x = self.mousex - 200, y = self.mousey - 100, w = 400, h = 200, zoom_level = 4}
	end
end

player:play()

