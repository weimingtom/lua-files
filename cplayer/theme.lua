--cplayer theme-aware graphics api
local player = require'cplayer'
local glue = require'glue'
local color = require'color'

local default_font = 'MS Sans Serif,8'

--theme api / state

player.themes = {}

player.themes.dark = {
	window_bg     = '#000000',
	faint_bg      = '#ffffff33',
	normal_bg     = '#ffffff4c',
	normal_fg     = '#ffffff',
	normal_border = '#ffffff66',
	hot_bg        = '#ffffff99',
 	hot_fg        = '#000000',
	selected_bg   = '#ffffff',
	selected_fg   = '#000000',
	disabled_bg   = '#ffffff4c',
	disabled_fg   = '#999999',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
	default_font  = default_font,
}

player.themes.light = {
	window_bg     = '#ffffff',
	faint_bg      = '#00000033',
	normal_bg     = '#0000004c',
	normal_fg     = '#000000',
	normal_border = '#00000066',
	hot_bg        = '#00000099',
	hot_fg        = '#ffffff',
	selected_bg   = '#000000e5',
	selected_fg   = '#ffffff',
	disabled_bg   = '#0000004c',
	disabled_fg   = '#666666',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
	default_font  = default_font,
}

player.themes.red = glue.merge({
	normal_bg      = '#ff0000b2',
	normal_fg      = '#ffffff',
	normal_border  = '#ffffff66',
	hot_bg         = '#ff0000e5',
	hot_fg         = '#ffffff',
	selected_bg    = '#ffffff',
	selected_fg    = '#000000',
	disabled_bg    = '#ff0000b2',
	disabled_fg    = '#999999',
}, player.themes.dark)

function player:save_theme(theme)
	local old_theme = self.theme
	self.theme = theme or self.theme
	return old_theme
end

--theme api / colors

local function parse_color(c)
	if type(c) == 'string' then
		return color.string_to_rgba(c)
	elseif type(c) == 'table' then
		return unpack(c)
	end
end

function player:parse_color(c)
	return parse_color(c)
end

function player:setcolor(color)
	self.cr:set_source_rgba(parse_color(self.theme[color] or color))
end

--theme api / fonts

local fonts = setmetatable({}, {__mode = 'kv'})

local default_font_face = default_font:match'^(.-),'
local default_font_size = default_font:match',(.*)$'

function player:parse_font(font)
	if fonts[font] then
		return fonts[font]
	end
	if type(font) == 'string' then
		local face, size, slant = font:match'([^,]*),?([^,]*),?([^,]*)'
		local font_t = {
			face = face or default_font_face,
			size = tonumber(size) or default_font_size,
			slant = slant or 'normal',
		}
		fonts[font] = font_t --memoize for speed
		font = font_t
	elseif type(font) == 'number' then
		local font_t = {
			face = default_font_face,
			size = font,
			slant = 'normal'
		}
		fonts[font] = font_t --memoize for speed
		font = font_t
	end
	return font
end

function player:setfont(font)
	font = self:parse_font(self.theme[font] or font or self.theme.default_font)
	self.cr:select_font_face(font.face, 0, 0)
	self.cr:set_font_size(font.size)
	font.extents = font.extents or self.cr:font_extents()
	return font
end

--graphics api / colors

function player:fill(color)
	self:setcolor(color or 'normal_bg')
	self.cr:fill()
end

function player:stroke(color, line_width)
	self:setcolor(color or 'normal_fg')
	self.cr:set_line_width(line_width or 1)
	self.cr:stroke()
end

function player:fillstroke(fill_color, stroke_color, line_width)
	if fill_color and stroke_color then
		self:setcolor(fill_color)
		self.cr:fill_preserve()
		self:stroke(stroke_color, line_width)
	elseif fill_color then
		self:fill(fill_color)
	elseif stroke_color then
		self:stroke(stroke_color, line_width)
	else
		self:fill('normal_bg')
	end
end

--graphics api / color-filled & stroked shapes

function player:dot(x, y, r, ...)
	self:rect(x-r, y-r, 2*r, 2*r, ...)
end

function player:rect(x, y, w, h, ...)
	self.cr:rectangle(x, y, w, h)
	self:fillstroke(...)
end

function player:circle(x, y, r, ...)
	self.cr:circle(x, y, r)
	self:fillstroke(...)
end

function player:line(x1, y1, x2, y2, ...)
	self.cr:move_to(x1, y1)
	self.cr:line_to(x2, y2)
	self:stroke(...)
end

function player:curve(x1, y1, x2, y2, x3, y3, x4, y4, ...)
	self.cr:move_to(x1, y1)
	self.cr:curve_to(x2, y2, x3, y3, x4, y4)
	self:stroke(...)
end


if not ... then require'cplayer.widgets_demo' end

