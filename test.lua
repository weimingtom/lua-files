local glue = require'glue'
local ffi = require'ffi'
local ft = require'freetype'
local player = require'cairo_player'
local cairo = require'cairo'
local hb = require'harfbuzz'

function player:shape(s, hb_font, direction, script, language, features)
	direction = direction or hb.HB_DIRECTION_LTR
	script = script or hb.HB_SCRIPT_LATIN
	language = language or 'en'

	local buf = hb.hb_buffer_create()
	buf:set_direction(direction)
	buf:set_script(script)
	buf:set_language(language)
	buf:add_utf8(s)

	local feats, feats_count = nil, 0
	if features then
		for _ in pairs(features) do feats_count = feats_count + 1 end
		feats = ffi.new('hb_feature_t[?]', feats_count)
		local i = 0
		for k,v in pairs(features) do
			assert(hb.hb_feature_from_string(k, #k, feats[i]) == 1)
			feats[i].value = v
			i = i + 1
		end
	end

	buf:shape(hb_font, feats, feats_count)

	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()

	local x, y = 0, 0
	local idx, posx, posy = {}, {}, {}
	for i=0,glyph_count-1 do
		 idx[i+1] = glyph_info[i].codepoint
		 posx[i+1] = x + glyph_pos[i].x_offset / 64
		 posy[i+1] = y - glyph_pos[i].y_offset / 64
		 x = x + glyph_pos[i].x_advance / 64
		 y = y - glyph_pos[i].y_advance / 64
	end

	buf:destroy()

	return idx, posx, posy
end

function player:render_glyph(face, glyph_index, glyph_size, x, y, load_flags, render_mode)

	face:set_pixel_sizes(glyph_size)

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

	x = x - glyph.bitmap_left
	y = y - glyph.bitmap_top + glyph_size

	self:setcolor'normal_fg'
	self.cr:mask_surface(image, x, y)

	image:free()
	if glyph.bitmap ~= bitmap then
		glyph.library:free_bitmap(bitmap)
	end
end

function player:ft_shape(s, face)
	local idx, posx, posy = {}, {}, {}
	for i=1,#s do
		--
	end
	return idx, posx, posy
end

local lib = ft:new()
local face = lib:new_face('media/fonts/DejaVuSerif.ttf')
local hb_font = hb.hb_ft_font_create(face, nil)

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

	local idx, posx, posy = self:shape('The Quick Brown Fox Jumped Over The Lazy Dog', hb_font)
	--local idx, posx, posy = self:ft_shape('The Quick Brown Fox Jumped Over The Lazy Dog', face)

	local x, y = 0, 0
	for size=1,28 do
		for i=1,#idx do
			self:render_glyph(face, idx[i], size, 100 + x, 100 + y,
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
			local advance = posx[i]
			--print(advance, face.glyph.advance.x / 64)
			--local advance = face.glyph.advance.x / 64
			x = x + (self.fixed_grid and math.floor(advance) or advance)
		end
		y = y + size
		x = 0
	end

end

player:play()
hb_font:destroy()
face:free()
lib:free()
