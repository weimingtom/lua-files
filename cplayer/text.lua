--cplayer text api
local player = require'cplayer'

--TODO: move string functions in a general-purpose string module and remove dependency on codedit_str
local str = require'codedit_str'
local line_count = str.line_count
local lines = str.lines
local next_line = str.next_line

local function half(x)
	return math.floor(x / 2 + 0.5)
end

local function text_args(self, s, font, color, line_spacing)
	s = tostring(s)
	font = self:setfont(font)
	self:setcolor(color or 'normal_fg')
	local line_h = font.extents.height * (line_spacing or 1)
	return s, font, line_h
end

local function draw_text(cr, x, y, s, align, line_h) --multi-line text
	for _, s in lines(s) do
		if align == 'right' then
			local extents = cr:text_extents(s)
			cr:move_to(x - extents.width, y)
		elseif align == 'center' then
			local extents = cr:text_extents(s)
			cr:move_to(x - half(extents.width), y)
		else
			cr:move_to(x, y)
		end
		cr:show_text(s)
		y = y + line_h
	end
end

function player:text(x, y, s, font, color, align, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)
	draw_text(self.cr, x, y, s, align, line_h)
end

function player:textbox(x, y, w, h, s, font, color, halign, valign, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)

	if halign == 'right' then
		x = x + w
	elseif halign == 'center' then
		x = x + half(w)
	end

	if valign == 'top' then
		y = y + font.extents.ascent
	else
		local lines_h = 0
		for _, s1 in lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = y + h - font.extents.descent
		elseif valign == 'center' then
			y = y + half(h + font.extents.ascent - font.extents.descent + lines_h)
		end
		y = y - lines_h
	end

	draw_text(self.cr, x, y, s, halign, line_h)
end


if not ... then require'cplayer.text_demo.lua' end

