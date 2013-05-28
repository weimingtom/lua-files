local ffi = require'ffi'
local hb = require'harfbuzz'
local ft = require'freetype'
local cairo = require'cairo'
local stdio = require'stdio'
require'cairo_ft_h'

local player = require'cairo_player'

local ft_lib = ft.FT_Init_FreeType()

local fonts = {}
local function load_font(filename)
	if fonts[filename] then
		return
			fonts[filename].hb_font,
			fonts[filename].cairo_font
	end
	local ft_face = ft_lib:new_face(filename)
	local hb_font = hb.hb_ft_font_create(ft_face, nil)
	local cairo_font = cairo.cairo_ft_font_face_create_for_ft_face(ft_face, 0)
	fonts[filename] = {ft_face = ft_face, hb_font = hb_font, cairo_font = cairo_font}
	return hb_font, cairo_font
end

local function glyph_path(cr, x, y, s, font, size, direction, script, language, features)
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

	local hb_font, cairo_font = load_font(font)
	cr:set_font_face(cairo_font)
	cr:set_font_size(size)

	buf:shape(hb_font, feats, feats_count)

	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()
	local cairo_glyphs = ffi.new('cairo_glyph_t[?]', glyph_count)

	for i=0,glyph_count-1 do
		 cairo_glyphs[i].index = glyph_info[i].codepoint
		 cairo_glyphs[i].x = x + glyph_pos[i].x_offset / 64
		 cairo_glyphs[i].y = y - glyph_pos[i].y_offset / 64
		 x = x + glyph_pos[i].x_advance / 64
		 y = y - glyph_pos[i].y_advance / 64
	end

	buf:destroy()

	cr:glyph_path(cairo_glyphs, glyph_count)
end

--[[
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

local ptSize      = 50
local device_hdpi = 100
local device_vdpi = 100
local width       = self.window.client_w
local height      = self.window.client_h

--ft_library:new_face'media/fonts/amiri-regular.ttf'
--ft_library:new_face'media/fonts/fireflysung.ttf'
]]

--Render loop
function player:on_render(cr)
	cr:set_source_rgba(0, 0, 0, 1)
	--cr:paint()

	local font = 'media/fonts/DejaVuSerif.ttf'
	glyph_path(cr, 500, 200, 'Te W.', font, 50, 'ltr', nil, nil, {})
	cr:set_source_rgba(0.7, 0.7, 0.7, 1.0)
	cr:fill()
end

player:play()

for _,t in pairs(fonts) do
	t.hb_font:destroy()
	t.cairo_font:destroy()
	t.ft_face:free()
end

ft_lib:free()

