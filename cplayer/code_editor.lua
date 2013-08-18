--code editor based on codedit.
local codedit = require'codedit'
local str = require'codedit_str'
local glue = require'glue'
local player = require'cairo_player'

local editor = glue.inherit({
	--font metrics
	font_face = 'Fixedsys',
	linesize = 16,
	charsize = 8,
	charvsize = 12,
	--scrollbox options
	vscroll = 'always',
	hscroll = 'auto',
	vscroll_w = nil, --use default
	hscroll_h = nil, --use default
	scroll_page_size = nil,
	--colors
	colors = {
		background = '#333333',
		selection_background = '#999999',
		selection_text = '#333333',
		cursor = '#ffffff',
		text = '#ffffff',
		line_number = '#66ffff',
		line_number_background = '#111111',
	},
	eol_markers = true,
}, codedit)

function editor:draw_scrollbox()
	local x, y, w, h = self.player:getbox(self)
	local cx, cy, cw, ch = self:view_rect()
	local scroll_x, scroll_y, clip_x, clip_y, clip_w, clip_h = self.player:scrollbox{
		id = self.id..'_scrollbox',
		x = self.x,
		y = self.y,
		w = self.w,
		h = self.h,
		cx = cx,
		cy = cy,
		cw = cw,
		ch = ch,
		vscroll = self.vscroll,
		hscroll = self.hscroll,
		vscroll_w = self.vscroll_w,
		hscroll_h = self.hscroll_h,
		page_size = self.scroll_page_size}

	self.player.cr:save()

	self.player.cr:translate(self.x, self.y)
	self.player.cr:rectangle(0, 0, clip_w, clip_h)
	self.player.cr:clip()
	self.player.cr:translate(scroll_x, scroll_y)
	self.player.cr:translate(self:line_numbers_width(), 0)

	return scroll_x, scroll_y, clip_x, clip_y, clip_w, clip_h
end

function editor:draw_line_numbers()
	codedit.draw_line_numbers(self)
end

function editor:draw_rect(x, y, w, h, color)
	self.player:rect(x, y, w, h, self.colors[color])
end

function editor:draw_char(x, y, s, i, color)
	self.player:setcolor(self.colors[color])
	self.player.cr:select_font_face(self.font_face, 0, 0)
	self.player.cr:move_to(x, y)
	--TODO: prevent string creation by using show_glyphs, and use harfbuzz for shaping anyway
	self.player.cr:show_text(s:sub(i, (str.next(s, i) or #s + 1) - 1))
end

--draw a reverse pilcrow at eol
function editor:render_eol_marker(line)
	local x, y = self:text_coords(line, self:visual_col(line, self:last_col(line) + 1))
	local x = x + 2.5
	local y = y - self.linesize + 3.5
	local cr = self.player.cr
	cr:new_path()
	cr:move_to(x, y)
	cr:rel_line_to(0, self.linesize - 0.5)
	cr:move_to(x + 3, y)
	cr:rel_line_to(0, self.linesize - 0.5)
	cr:move_to(x - 2.5, y)
	cr:line_to(x + 3.5, y)
	self.player:stroke('#ffffff66')
	cr:arc(x + 2.5, y + 3.5, 4, - math.pi / 2 + 0.2, - 3 * math.pi / 2 - 0.2)
	cr:close_path()
	self.player:fill('#ffffff66')
	cr:fill()
end

function editor:render()
	codedit.render(self)
	if self.eol_markers then
		local line1, line2 = self:visible_lines()
		for line = line1, line2 do
			self:render_eol_marker(line)
		end
	end
	self.player.cr:restore()
end

function editor:setactive(active)
	--
end

function player:code_editor(t)
	local id = assert(t.id, 'id missing')
	local ed = t.lines and t or editor:new(t)
	ed.player = self
	ed:key_pressed(
		true, --self.focused == ed.id,
		self.key,
		self.char,
		self.ctrl,
		self.shift,
		self.alt)
	ed:mouse_input(
		self.active == ed.id,
		self.mousex - ed.x - ed.scroll_x,
		self.mousey - ed.y - ed.scroll_y,
		self.lbutton,
		self.rbutton,
		self.wheel)
	ed:render()
	return ed
end

if not ... then assert(loadfile('../codedit_demo.lua'))() end

