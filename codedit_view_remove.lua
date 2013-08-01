local glue = require'glue'
local lines = require'codedit_lines'

local viewer = {}

local viewer = {
	x = 0,
	y = 0,
	w = 500,
	h = 300,
	font = 'Fixedsys',
	charsize = 8,
	linesize = 16,
	tabsize = 3,
	bgcolor = 0x30ffffff,
	caret_color = 0xffffffff,
	caret_width = 2,
	colors = {
	  comment = 0xff558817,
	  constant = 0xffa8660d,
	  escape = 0xff844631,
	  keyword = 0xff2239a8,
	  library = 0xff0e7c6b,
	  marker = 0xff512b1e,
	  number = 0xffa8660d,
	  operator = 0xff2239a8,
	},
	default_color = 0xffffffff,
}

function viewer:new(x, y, w, h, highlighter)
	return glue.inherit({
		x = x,
		y = y,
		w = w,
		h = h,
		highlighter = highlighter,
		lnum = 1,
		cnum = 1,
	}, viewer)
end

local bit = require'bit'
local function ccolor(n)
	return
		bit.band(bit.rshift(n,  0), 0xff) / 255,
		bit.band(bit.rshift(n,  8), 0xff) / 255,
		bit.band(bit.rshift(n, 16), 0xff) / 255,
		bit.band(bit.rshift(n, 24), 0xff) / 255
end

function viewer:text_coords(s, lnum, cnum)
	local i, j = lines.pos(s, lnum)
	local view_cnum = lines.view_cnum(s, i, j, cnum, self.tabsize)
	local x = (view_cnum - 1) * self.charsize
	local y = (lnum - 1) * self.linesize
	return x, y
end

function viewer:insert_caret_rect(s, lnum, cnum)
	local x, y = self:text_coords(s, lnum, cnum)
	local w = self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (cnum == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	y = y + 4
	h = h - 2
	return x, y, w, h
end

function viewer:over_caret_rect(s, lnum, cnum)
	local x, y = self:text_coords(s, lnum, cnum)
	local w = self.charsize
	local h = self.caret_width
	y = y + self.linesize
	y = y + 1
	return x, y, w, h
end

function viewer:caret_rect(s, lnum, cnum, insert_mode)
	if insert_mode then
		return self:insert_caret_rect(s, lnum, cnum)
	else
		return self:over_caret_rect(s, lnum, cnum)
	end
end

function viewer:render_text(cr, s)
	cr:save()

	cr:select_font_face(self.font, 0, 0)
	cr:rectangle(self.x, self.y, self.w, self.h)
	cr:clip()
	cr:set_source_rgba(ccolor(self.bgcolor))
	cr:paint()

	local x, y = self.x, self.y + self.linesize
	local spaces = (' '):rep(self.tabsize)
	for n, i, j in lines.lines(s) do
		cr:move_to(x, y)
		cr:set_source_rgba(ccolor(self.default_color))
		cr:show_text((s:sub(i, j):gsub('\t', spaces)))
		y = y + self.linesize
	end

	cr:restore()
end

--[[
function viewer:render_text(cr, s)

	cr:save()

	cr:select_font_face(self.font, 0, 0)
	cr:rectangle(self.x, self.y, self.w, self.h)
	cr:clip()
	cr:set_source_rgba(ccolor(self.bgcolor))
	cr:paint()

	local min_lnum = self.lnum
	local max_lnum = self.lnum + math.floor(self.h / self.linesize) - 2
	local min_cnum = self.cnum
	local max_cnum = self.cnum + math.floor(self.w / self.charsize) - 1

	local lnum1, tab1 = 0, 0
	for lnum, cnum, s, kind in tokens(s, 'lua') do

		for s in glue.gsplit(s, '\r?\n') do

			local tab = lnum1 == lnum and tab1 or 0
			for i in s:gmatch'()\t' do
				if i > cnum + 1 then break end
				tab = tab + 1
			end

			cnum = cnum + tab * (self.tabsize - 1)
			s = s:gsub('\t', ' ')
			if
				#s > 0
				and lnum >= min_lnum and lnum <= max_lnum
				and cnum + #s - 1 >= min_cnum and cnum <= max_cnum
			then
				local x = self.x + (cnum - min_cnum + 1) * self.charsize
				local y = self.y + (lnum - min_lnum + 1) * self.linesize
				local color = self.colors[kind] and self.colors[kind] or self.default_color

				cr:move_to(x, y)
				cr:set_source_rgba(ccolor(color))
				cr:show_text(s)
			end

			lnum1, tab1 = lnum, tab
			lnum, cnum = lnum + 1, 1
		end
	end

	cr:restore()
end
]]

function viewer:render_caret(cr, caret, editor, clock)
	caret.start_clock = caret.start_clock or caret.gettime()
	if (caret.gettime() - caret.start_clock) % 1000 < 500 then
		cr:set_source_rgba(ccolor(self.caret_color))
		local x, y, w, h = self:caret_rect(editor.s, caret.lnum, caret.cnum, caret.insert_mode)
		cr:rectangle(self.x + x, self.y + y, w, h)
		cr:fill()
	end
end

if not ... then require'codedit_demo' end

return viewer
