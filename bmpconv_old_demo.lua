local player = require'cairo_player'
local glue = require'glue'
local ffi = require'ffi'
local bmpconv = require'bmpconv'

local formats = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr', 'g', 'ga', 'ag', 'cmyk'}
local src_pixel = 'rgba'
local dst_pixels = {bgra = true}
local src_bottom_up = false
local src_padded = false
local dst_bottom_up = false
local dst_padded = false
local colors = {
	red   = 0,
	blue  = 0,
	green = 127,
	gray  = 32,
	alpha = 230,
	cyan    = 82,
	magenta = 82,
	yellow  = 113,
	black   = 255,
}

function player:on_render(cr)

	self.theme = self.themes.light

	src_pixel = self:mbutton{id = 'src_pixel', x = 10, y = 10, w = 380, h = 24, values = formats, selected = src_pixel}
	dst_pixels = self:mbutton{id = 'dst_pixel', x = 10, y = 40, w = 380, h = 24, values = formats, selected = dst_pixels}
	src_bottom_up = self:togglebutton{id = 'src_bottom_up', x = 400, y = 10, w = 90, h = 24, text = 'bottom_up', selected = src_bottom_up}
	dst_bottom_up = self:togglebutton{id = 'dst_bottom_up', x = 400, y = 40, w = 90, h = 24, text = 'bottom_up', selected = dst_bottom_up}
	src_padded = self:togglebutton{id = 'src_padded', x = 500, y = 10, w = 90, h = 24, text = 'padded', selected = src_padded}
	dst_padded = self:togglebutton{id = 'dst_padded', x = 500, y = 40, w = 90, h = 24, text = 'padded', selected = dst_padded}

	local y = 10
	for i,col in ipairs{'red','blue','green','alpha','gray','cyan','magenta','yellow','black'} do
		if col == 'cyan' or col == 'alpha' or col == 'gray' then y = y + 10 end
		colors[col] = self:slider{id = col, x = 600, y = y, w = 90, h = 24, text = col, i0=0, i1=255, i=colors[col]}
		y = y + 24
	end

	local img = {w = 580, h = 100, pixel = src_pixel}
	if src_padded then
		img.stride = bmpconv.pad_stride(#img.pixel * img.w)
	else
		img.stride = #img.pixel * img.w
	end
	img.bpc = 8
	img.size = img.stride * img.h
	img.data = ffi.new('uint8_t[?]', img.size)
	img.orientation = 'top_down'
	img.orientation = src_bottom_up and 'bottom_up' or 'top_down'

	local cols = {}
	local function setcolor(c, v)
		local i = img.pixel:find(c)
		if not i then return end
		cols[i] = v
	end
	if #img.pixel >= 3 then
		setcolor('r', colors.red)
		setcolor('g', colors.green)
		setcolor('b', colors.blue)
		setcolor('c', colors.cyan)
		setcolor('m', colors.magenta)
		setcolor('y', colors.yellow)
		setcolor('k', colors.black)
	else
		setcolor('g', colors.gray)
	end
	setcolor('a', colors.alpha)
	setcolor('x', 0xff)

	for i=0,img.h-1 do
		for j=0,img.w-1 do
			for k=0,#img.pixel-1 do
				img.data[i * img.stride + j * #img.pixel + k] = math.abs(i-j) < 10 and 255 or cols[k+1]
			end
		end
	end

	local ok, dimg = pcall(bmpconv.convert_best, img, glue.update({
		bottom_up = dst_bottom_up, top_down = not dst_bottom_up,
		padded = dst_padded,
	}, dst_pixels), {force_copy = true})
	if ok then
		self:image{x = 10, y = 70, image = img}
		self:image{x = 10, y = 70 + img.h + 10, image = dimg}

		local s = dimg.pixel
		self:text(s, 14, 'normal_fg', 'center', 'middle', 10, 70 + img.h + 10, img.w, img.h)
	else
		local err = string.format('%s', dimg:match(': ([^:]-)$'))
		self:text(err, 14, 'normal_fg', 'center', 'middle', 10, 70, img.w, img.h)
	end
end

player:play()
