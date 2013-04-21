--[[
	t1
		t2	tt
			t3
]]
local ffi = require'ffi'
local glue = require'glue'
local player = require'cairo_player'

--a buffer holds the contents of the file which is being edited, possibly by multiple editors.
local buffer = {}

function buffer:new()
	return glue.inherit({
		s = '',
	}, buffer)
end

function buffer:load_string(s)
	self.s = s
end

function buffer:load_file(filename)
	self:load_string(glue.readfile(filename))
end

--an editor is an interface for viewing and changing a buffer using (line-num, char-num) pairs called cursors.
local editor = {}

function editor:new(buffer, tabs, newline)
	local t = {}
	return glue.inherit({
		buffer = buffer,
		tabs = '\t',
		newline = '\n',
	}, editor)
end

--line iterator<linenum, i, j> where i, j are the start and end buffer indices of the line contents without the newline.
function editor:lines()
	local match = self.buffer.s:gmatch'()\r?\n()'
	local i = 1
	local lnum = 0
	return function()
		if not i then return end
		lnum = lnum + 1
		local j, nexti = match()
		if j then j = j - 1 else j, nexti = #s, nil end
		local reti = i
		i = nexti
		return lnum, reti, j
	end
end

--start and end buffer indices and adjusted line number for a certain line number.
function editor:linepos(lnum)
	if lnum < 1 then lnum = 1 end
	local n, i, j
	for n1, i1, j1 in self:lines() do
		n, i, j = n1, i1, j1
		if n == lnum then break end
	end
	return i, j, n
end

--count the tabs before the cursor.
function editor:tabs_before(lnum, cnum)
	local i, j, n = self:linepos(lnum)
	if n ~= lnum then return 0 end
	local n = 0
	j = i + math.min(j - i + 1, cnum) - 2
	while true do
		i = self.buffer.s:find('\t', i, true)
		if not i or i > j then break end
		i = i + 1
		n = n + 1
	end
	return n
end

--normalize string for newline and tab format.
function editor:normalize(s)
	s = s:gsub('\t', self.tabs)
	s = s:gsub('\r?\n', self.newline)
	return s
end

--character at cursor or closest to the cursor: return its buffer index, its actual cursor and its line buffer indices.
function editor:pos(lnum, cnum)
	local i, j, n = self:linepos(lnum)
	if cnum < 1 then cnum = 1 end
	if n < lnum then
		cnum = j - i + 1
	elseif n > lnum then
		cnum = 1
	else
		cnum = math.min(j - i + 2, cnum)
	end
	return i + cnum - 1, lnum, cnum, i, j
end

--insert text at cursor. if the cursor is outside editor space, the editor space is extended
--with newlines and spaces until it reaches the cursor.
function editor:insert(lnum, cnum, s)
	s = self:normalize(s)
	local i, n, c = self:pos(lnum, cnum)
	local pad = ''
	if n < lnum then pad = pad .. self.newline:rep(lnum - n); c = 1 end
 	if c < cnum then pad = pad .. (' '):rep(cnum - c) end
	self.buffer.s = self.buffer.s:sub(1, i - 1) .. pad .. s .. self.buffer.s:sub(i)
end

--remove the text between two cursors.
function editor:remove(lnum1, cnum1, lnum2, cnum2)
	local i = self:pos(lnum1, cnum1)
	local j = self:pos(lnum2, cnum2)
	self.buffer.s = self.buffer.s:sub(1, i - 1) .. self.buffer.s:sub(j + 1)
end

local caret = {
	--when on margin, keep the view in sync with the caret vertically, but not horizontally
	ystrict = true,
	xstrict = false,
	--caret "pushes" on the editor's top/bottom margins to scroll the view
--[[
caret.policy.yslop=1
caret.policy.lines=0
caret.policy.yjumps=0
# caret "pushes" on the editor's left/right margins - ~300px to scroll the view
caret.policy.xslop=1
caret.policy.width=100
caret.policy.xjumps=1
caret.policy.xeven=1
caret.policy.yeven=1
]]
}

function caret:new(editor, viewer)
	return glue.inherit({
		editor = editor,
		lnum = 1,
		cnum = 1,
		wanted_cnum = 1,
		blink = 0,
	}, caret)
end

function caret:move_right()
	self.blink = 0
	self.cnum = self.cnum + 1
	local i, j = self.editor:linepos(self.lnum)
	if self.cnum - 1 > j - i + 1 then
		self.lnum = self.lnum + 1
		self.cnum = 1
	end
	self.wanted_cnum = self.cnum
end

function caret:move_left()
	self.blink = 0
	self.cnum = self.cnum - 1
	if self.cnum < 1 then
		self.lnum = self.lnum - 1
		if self.lnum < 1 then self.lnum = 1 end
		local i, j = self.editor:linepos(self.lnum)
		self.cnum = j - i + 2
	end
	self.wanted_cnum = self.cnum
end

function caret:move_up()
	self.blink = 0
	local i, j, n = self.editor:linepos(self.lnum - 1)
	self.lnum = n
	self.cnum = math.min(j - i + 2, self.wanted_cnum)
end

function caret:move_down()
	self.blink = 0
	local i, j, n = self.editor:linepos(self.lnum + 1)
	self.lnum = n
	self.cnum = math.min(j - i + 2, self.wanted_cnum)
end

function caret:page_up()

end

function caret:page_down()

end

function caret:move_home()

end

function caret:move_end()

end

function caret:scroll_up()

end

function caret:scroll_down()

end


local highlighter = {}

function highlighter:new(lexer)
	lexer = lexer or 'lua'
	local lxsh = require'lxsh'
	return glue.inherit({
		lexer = lxsh.lexers[lexer],
	}, highlighter)
end

function highlighter:tokens(buffer)
	local match = self.lexer.gmatch((buffer.s:gsub('\t', '   ')))
	return function()
		local kind, s, lnum, cnum = match()
		return lnum, cnum, s, kind
	end
end

local viewer = {}

local viewer = {
	x = 0,
	y = 0,
	w = 500,
	h = 500,
	font = 'Fixedsys',
	charsize = 8,
	linesize = 16,
	tabsize = 3,
	bgcolor = 0xff040404,
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

function viewer:scroll(lnum, cnum)
	self.lnum = lnum
	self.cnum = cnum
end

function viewer:render_buffer(cr, buffer)

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
	for lnum, cnum, s, kind in self.highlighter:tokens(buffer) do

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

function viewer:render_caret(cr, caret, editor)
	caret.blink = caret.blink or 0
	caret.blink = caret.blink + 1

	if caret.blink % 40 < 20 then
		cr:set_source_rgba(ccolor(self.caret_color))
		cr:rectangle(
			self.x + (caret.cnum + editor:tabs_before(caret.lnum, caret.cnum) * (self.tabsize - 1)) * self.charsize - 3,
			self.y + (caret.lnum - 1) * self.linesize + 4,
			2,
			self.linesize - 2)
		cr:fill()
	end
end


local buffer = buffer:new()
buffer:load_file'text_editor.lua'
local hliter = highlighter:new('lua')
local ed = editor:new(buffer)
local vwer = viewer:new(100, 100, 800, 600, hliter)
local car = caret:new(ed)

local i=0
function player:on_render(cr)
	i=i+1
	cr:reset_clip()
	cr:set_source_rgba(0,0,0,1)
	cr:paint()

	local keys = {left = 37, right = 39, up = 38, down = 40}
	local vk = self.key_code
	if self.key_state == 'down' then
		if vk == keys.left then
			car:move_left()
		elseif vk == keys.right then
			car:move_right()
		elseif vk == keys.up then
			car:move_up()
		elseif vk == keys.down then
			car:move_down()
		end
	end

	vwer:render_buffer(cr, buffer)
	vwer:render_caret(cr, car, ed)

end

player:play()

