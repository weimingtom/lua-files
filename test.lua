local glue = require'glue'
local ffi = require'ffi'
local ft = require'freetype'
local player = require'cairo_player'
local cairo = require'cairo'
local hb = require'harfbuzz'

function player:render_glyph(face, glyph_index, x, y, load_flags, render_mode)

	local ox = x - math.floor(x)
	local oy = y - math.floor(y)
	face:set_transform(nil, ffi.new('FT_Vector', ox * 64, oy * 64))

	face:load_glyph(glyph_index, load_flags)
	local glyph = face.glyph

	if glyph.format ~= ft.FT_GLYPH_FORMAT_BITMAP then
		glyph:render(render_mode)
	end
	assert(glyph.format == ft.FT_GLYPH_FORMAT_BITMAP)

	local bitmap = glyph.bitmap

	if bitmap.width == 0 or bitmap.rows == 0 then
		return
	end

	if bitmap.pitch % 4 ~= 0 or bitmap.pixel_mode ~= ft.FT_PIXEL_MODE_GRAY then
		bitmap = glyph.library:new_bitmap()
		glyph.library:convert_bitmap(glyph.bitmap, bitmap, 4)
	end
	local cairo_format = cairo.CAIRO_FORMAT_A8
	local cairo_stride = cairo.cairo_format_stride_for_width(cairo_format, bitmap.width)

	assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)
	assert(bitmap.pitch == cairo_stride)

	local image = cairo.cairo_image_surface_create_for_data(
		bitmap.buffer,
		cairo_format,
		bitmap.width,
		bitmap.rows,
		cairo_stride)

	x = x + glyph.bitmap_left
	y = y - glyph.bitmap_top

	self:setcolor'normal_fg'
	self.cr:mask_surface(image, math.floor(x), math.floor(y))

	image:free()
	if glyph.bitmap ~= bitmap then
		glyph.library:free_bitmap(bitmap)
	end
end

local function glyphs(face, s)
	local t = {}
	for i=1,#s do
		t[i] = face:char_index(string.byte(s, i))
	end
	return t
end

local lib = ft:new()
local face = lib:new_face('media/fonts/DejaVuSerif.ttf')

player.no_hinting = true

function player:on_render(cr)

	self.no_hinting = self:togglebutton{id = 'no_hinting',
		x = 100, y = 10, w = 90, h = 24, text = 'no hinting', selected = self.no_hinting}
	self.force_autohint = self:togglebutton{id = 'force_autohint',
		x = 200, y = 10, w = 90, h = 24, text = 'force autohint', selected = self.force_autohint}
	self.no_autohint = self:togglebutton{id = 'no_autohint',
		x = 300, y = 10, w = 90, h = 24, text = 'no autohint', selected = self.no_autohint}
	self.render_light = self:togglebutton{id = 'render_light',
		x = 400, y = 10, w = 90, h = 24, text = 'render light', selected = self.render_light}
	self.fixed_grid = self:togglebutton{id = 'fixed_grid',
		x = 500, y = 10, w = 90, h = 24, text = 'fixed grid', selected = self.fixed_grid}

	local x, y = 100, 100
	for size=1,28 do
		self:rect(x, y, 500, size, nil, 'normal_fg', 0.1)
		face:set_char_size(size * 64)
		local t = glyphs(face, 'iiiiiiiiii W.T.Smith')
		for i,idx in ipairs(t) do
			self:render_glyph(face, idx, x, y,
				bit.bor(
					self.no_hinting and ft.FT_LOAD_NO_HINTING or 0,
					self.force_autohint and ft.FT_LOAD_FORCE_AUTOHINT or 0,
					self.no_autohint and ft.FT_LOAD_NO_AUTOHINT or 0,
					self.render_light and ft.FT_LOAD_TARGET_LIGHT or 0
				),
				bit.bor(
					self.render_light and ft.FT_RENDER_MODE_LIGHT or 0
				)
			)

			x = x + face.glyph.advance.x / 64
		end
		y = y + size
		x = 100
	end

	if self:keypressed'ctrl' then
		self:magnifier{id = 'mag', x = self.mousex - 300, y = self.mousey - 200, w = 600, h = 400, zoom_level = 6}
	end
end

player:play()
face:free()
lib:free()
