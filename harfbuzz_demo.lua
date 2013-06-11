local ffi = require'ffi'
local hb = require'harfbuzz'
local ft = require'freetype'
local cairo = require'cairo'
local stdio = require'stdio'
require'cairo_ft'

local player = require'cairo_player'

local function shape_text(s, ft_face, hb_font, size, direction, script, language, features)
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

	ft_face:set_pixel_sizes(size, size)
	buf:shape(hb_font, feats, feats_count)
	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()
	local cairo_glyphs = ffi.new('cairo_glyph_t[?]', glyph_count)
	local x, y = 0, 0
	for i=0,glyph_count-1 do
		cairo_glyphs[i].index = glyph_info[i].codepoint
		cairo_glyphs[i].x = x + glyph_pos[i].x_offset / 64
		cairo_glyphs[i].y = y - glyph_pos[i].y_offset / 64
		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end
	buf:destroy()

	return cairo_glyphs, glyph_count
end

local function draw_glyphs(cr, x, y, cairo_glyphs, glyph_count, cairo_face, size)
	cr:set_font_face(cairo_face)
	cr:set_font_size(size)
	cr:translate(x, y)
	cr:glyph_path(cairo_glyphs, glyph_count)
	cr:translate(-x, -y)
	cr:set_source_rgba(0.7, 0.7, 0.7, 1.0)
	cr:fill()
	cr:set_font_face(nil)
end

local function draw_text(cr, x, y, s, font, size, direction, script, language, features)
	local glyphs, glyph_count = shape_text(s, font.ft_face, font.hb_font, size, direction, script, language, features)
	draw_glyphs(cr, x, y, glyphs, glyph_count, font.cairo_face, size)
end

local ft_lib = ft.FT_Init_FreeType()

local fonts = {}
local function font(filename)
	if not fonts[filename] then
		local ft_face = ft_lib:new_face(filename)
		local cairo_face = cairo.cairo_ft_font_face_create_for_ft_face(ft_face, 0)
		local hb_font = hb.hb_ft_font_create(ft_face, nil)
		fonts[filename] = {ft_face = ft_face, cairo_face = cairo_face, hb_font = hb_font}
	end
	return fonts[filename]
end

local amiri = font'media/fonts/amiri-regular.ttf'
local dejavu = font'media/fonts/DejaVuSerif.ttf'

local sub = 0
function player:on_render(cr)
	draw_text(cr, 100, 100, 'Te VA - This is Some English Text', dejavu, 20, 'ltr')
	draw_text(cr, 100, 150, "هذه هي بعض النصوص العربي", amiri, 40, 'rtl', hb.HB_SCRIPT_ARABIC)

	local y = 0
	for i=6,20 do
		draw_text(cr, 100 + sub, 200 + y + sub, 'Te VA - This is Some English Text', dejavu, i, 'ltr')
		y = y + i
	end
	sub = sub + 0.01
end

player:play()

for name,t in pairs(fonts) do
	t.hb_font:destroy()
	t.cairo_face:destroy()
	print(name, 'face refcoint', t.cairo_face:get_reference_count())
	ffi.gc(t.ft_face, nil) --can't free the face, cairo's cache references it
end
ffi.gc(ft_lib, nil)
--ft_lib:free()

