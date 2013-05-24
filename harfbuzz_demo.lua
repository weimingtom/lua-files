local ffi = require'ffi'
local hb = ffi.load'harfbuzz'
require'harfbuzz_h'
local ft = require'freetype'
local cairo = require'cairo'
require'cairo_ft_h'

local player = require'cairo_player'

local texts = {
    "This is some english text",
    "هذه هي بعض النصوص العربي",
    "這是一些中文",
}

local text_directions = {
	hb.HB_DIRECTION_LTR,
	hb.HB_DIRECTION_RTL,
	hb.HB_DIRECTION_TTB,
}

local languages = {
	"en",
	"ar",
	"ch",
}

local scripts = {
	hb.HB_SCRIPT_LATIN,
	hb.HB_SCRIPT_ARABIC,
	hb.HB_SCRIPT_HAN,
}

local ENGLISH = 1
local ARABIC  = 2
local CHINESE = 3


-- Init freetype
local ft_library = ft.FT_Init_FreeType()

-- Load our fonts
local ft_face = {}
ft_face[ENGLISH] = ft_library:new_face"media/fonts/DejaVuSerif.ttf"
ft_face[ARABIC]  = ft_library:new_face"media/fonts/amiri-regular.ttf"
ft_face[CHINESE] = ft_library:new_face"media/fonts/fireflysung.ttf"


--Render loop
function player:on_render(cr)
	cr:set_source_rgba(0, 0, 0, 1)
	cr:paint()

	local ptSize      = 50
	local device_hdpi = 100
	local device_vdpi = 100
	local width       = self.window.client_w
	local height      = self.window.client_h

	for i=1,#ft_face do
		assert(ft.FT_Set_Char_Size(ft_face[i], 0, ptSize, device_hdpi, device_vdpi) == 0)
	end

	-- Get our cairo font structs
	local cairo_ft_face = {}
	for i=1,#ft_face do
		cairo_ft_face[i] = cairo.cairo_ft_font_face_create_for_ft_face(ft_face[i], 0)
	end

	-- Get our harfbuzz font/face structs
	local hb_ft_font = {}
	local hb_ft_face = {}
	for i=1,#ft_face do
		hb_ft_font[i] = hb.hb_ft_font_create(ft_face[i], nil)
		hb_ft_face[i] = hb.hb_ft_face_create(ft_face[i], nil)
	end

	local x = 0
	local y = 50

	for i=1,#ft_face do
		local buf = hb.hb_buffer_create()

		hb.hb_buffer_set_unicode_funcs(buf, hb.hb_ucdn_get_unicode_funcs())
		hb.hb_buffer_set_direction(buf, text_directions[i])  -- or LTR
      hb.hb_buffer_set_script(buf, scripts[i])  -- see hb-unicode.h
		hb.hb_buffer_set_language(buf, hb.hb_language_from_string(languages[i], #languages[i]))

		-- Layout the text
      hb.hb_buffer_add_utf8(buf, texts[i], #texts[i], 0, #texts[i])
		hb.hb_shape(hb_ft_font[i], buf, nil, 0)

		-- Hand the layout to cairo to render
		local glyph_count = ffi.new'uint32_t[1]'
		local glyph_info  = hb.hb_buffer_get_glyph_infos(buf, glyph_count)
		local glyph_pos   = hb.hb_buffer_get_glyph_positions(buf, glyph_count)
		glyph_count = glyph_count[0]
		local cairo_glyphs = ffi.new('cairo_glyph_t[?]', glyph_count)

		local string_width_in_pixels = 0
		for i=0,glyph_count-1 do
			string_width_in_pixels = string_width_in_pixels + glyph_pos[i].x_advance / 64 * ptSize
		end

		if i == ENGLISH then x = 20 end                                   -- left justify
		if i == ARABIC  then x = width - string_width_in_pixels - 20 end  -- right justify
		if i == CHINESE then x = width/2 - string_width_in_pixels/2 end   -- center

		for i=0,glyph_count-1 do
			 cairo_glyphs[i].index = glyph_info[i].codepoint
			 cairo_glyphs[i].x = x + (glyph_pos[i].x_offset / 64)
			 cairo_glyphs[i].y = y - (glyph_pos[i].y_offset / 64)
			 x = x + glyph_pos[i].x_advance / 64 * ptSize
			 y = y - glyph_pos[i].y_advance / 64 * ptSize
		end

		cr:set_source_rgba(0.7, 0.7, 0.7, 1.0)
		cr:set_font_face(cairo_ft_face[i])
		cr:set_font_size(ptSize)
		cr:show_glyphs(cairo_glyphs, glyph_count)
		cr:set_font_face(nil)

		hb.hb_buffer_destroy(buf)

		y = y + 75
	end

	for i=1,#ft_face do
		cairo_ft_face[i]:destroy()
		hb.hb_font_destroy(hb_ft_font[i])
		hb.hb_face_destroy(hb_ft_face[i])
	end
end

player:play()


--Cleanup
for i=1,#ft_face do
	ft_face[i]:free()
end
ft_library:free()

