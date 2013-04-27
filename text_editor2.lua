--[[
composable text editor featuring:

- tabs and indentation:
	- tabsize - expand tabs when positioning the text and jump through tabs when moving the caret.
	- smart tabs - write tabs for indentation, but write spaces for alignment (inside the line).
	- space tabs - always write spaces when pressing tab.
	* smart space tabs - the number of spaces is such that the caret aligns to the closest upper/lower text.
	* jump through spaces - jump left/right through spaces as if they were tabs or smart space tabs.
	- preserve indentation - pressing enter moves caret down at the same indentation as current line.
- carets:
	- multiple carets - display and move secondary carets.
	- jump through words - ctrl+left/right jumps to the beginning of the next/prev. word.
	- EOL restrict - don't allow caret past EOL but remember the vert. pos for when moving up/down to a longer line.
	- EOF restrict - don't allow caret past EOF. move to the start of the next line when moving past EOL.
	- EOL free - allow caret past EOL - pad with spaces if inserting text at caret.
	- EOF free - allow caret past EOF - pad with lines if inserting text at caret.
	- scroll view - pressing ctrl+up/down scrolls the view without moving the caret.
	- scroll margins - moving the caret outside the view minus some margin scrolls the view in that direction.
	- smart right scroll - scroll right as if the view is springed on the left (i.e. scroll back when moving left).
- normalization:
	* autodetect newline format on opening
	* autodetect tabsize and space tabs on opening
	* force newline format on all lines on saving
	* convert spaces to tabs or tabs to spaces everywhere on saving
	* remove whitespace at EOL on saving
	* remove whitespace/empty lines at EOF on saving
	* new file created with newline format and tab options of current file
- rendering:
	- monospace fonts only
	- single-function API renderer: text(x, y, s)
	* syntax highlighting with embedded lexers (js and css in html etc.)
	- autodetect lexer to use based on file extension
- sessions:
	* save and restore all open buffers along with view, caret and selection state.
	- per-project sessions.
- customization:
	- global, local (per-project), per-filetype, per-user config files (like scite).
	- reload config on the fly on saving the config file.
	- custom key bindings.

]]

local glue = require'glue'

local function next_line(s, i)
	i = i or 1
	if i > #s then return end
	local j, nexti = s:find('\r?\n', i)
	if j then
		return nexti + 1, i, j - 1
	else
		return #s + 1, i, #s
	end
	return nexti, i, j
end

--line iterator<next_i, i, j> where i, j are the start and end buffer indices of the line contents without the newline.
local function line_split(s, i)
	return next_line, s, 1
end

--start and end buffer indices for a line number. nil for invalid line numbers.
local function line_pos(s, lnum)
	if lnum < 1 then return end
	local n = 0
	for _, i, j in line_split(s) do
		n = n + 1
		if n == lnum then return i, j end
	end
end

--closest valid line number and line_pos() of that line.
local function closest_line(s, lnum)
	if lnum < 1 then lnum = 1 end
	local n = 0
	local i, j
	for _, i1, j1 in line_split(s) do
		n = n + 1
		i, j = i1, j1
		if n == lnum then break end
	end
	return n, i, j
end

local function fit_cnum(i, j, cnum)
	return i + math.min(j - i + 1, math.max(cnum, 1)) - 1
end

local function count_tabs(s, i, j)
	local n = 0
	while i <= j do
		i = s:find('\t', i, true)
		if not i then break end
		n = n + 1
		i = i + 1
	end
	return n
end

--given a physical cnum and tabsize, return the corresponding visual cnum.
local function view_cnum(s, i, j, cnum, tabsize)
	local before_cnum = fit_cnum(i, j, cnum - 1)
	return count_tabs(s, i, before_cnum) * (tabsize - 1) + cnum
end

--given a visual cnum and tabsize, return the corresponding physical cnum.
--if the visual cnum is over an expanded tab character, return the position on or after the tab, whichever is closer.
local function file_cnum(s, i, j, cnum, tabsize)
	local p = i + cnum - 1 --target view position
	local q = i
	for i = i, j do
		if s:byte(i) == 9 then --tab check without string creation
			if p >= q and p <= q + tabsize then
				return i + (p > q + tabsize / 2 and 1 or 0)
			end
			q = q + tabsize
		else
			if p == q then return i end
			q = q + 1
		end
	end
end

--normalize string for newline and tab format.
local function normalize(s, tabs, newline)
	s = s:gsub('\t', tabs)
	s = s:gsub('\r?\n', newline)
	return s
end

--[[
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
]]

local function move_right(s, lnum, cnum, restrict_right, restrict_down)
	cnum = cnum + 1
	local n, i, j = closest_line(s, lnum)
	if restrict_right and cnum - 1 > j - i + 1 then
		lnum = lnum + 1
		cnum = 1
	end
	if restrict_down and n < lnum then
		lnum = n
		cnum = j - i + 1
	end
	return lnum, cnum
end

local function move_left(s, lnum, cnum)
	cnum = cnum - 1
	if cnum < 1 then
		lnum = lnum - 1
		if lnum < 1 then lnum = 1 end
		local lnum, i, j = closest_line(s, lnum)
		cnum = j - i + 2
	end
	return lnum, cnum
end

local function move_up(s, lnum, cnum, wanted_cnum, tabsize)
	if lnum == 1 then return lnum, cnum end
	local n, i, j = closest_line(s, lnum)
	if n < lnum then
		return lnum - 1, cnum
	else
		local vcnum = view_cnum(s, i, j, cnum, tabsize)
		lnum, i, j = closest_line(s, lnum - 1)
		cnum = file_cnum(s, i, j, vcnum, tabsize)
		cnum = math.min(j - i + 2, wanted_cnum)
		return lnum, cnum
	end
end

local function move_down(s, lnum, cnum, wanted_cnum, tabsize, restrict_down)
	local n, i, j = closest_line(s, lnum)
	local view_cnum = view_cnum(s, i, j, cnum, tabsize)
	lnum = lnum + 1
	local _, i, j = next_line(s, i)
	local n, i, j = closest_line(s, lnum)
	if n < lnum then
		if restrict_down then
			return n, j - i + 2
		else
			return lnum + 1, cnum
		end
	else
		cnum = file_cnum(s, i, j, view_cnum, tabsize)
		cnum = math.min(j - i + 2, wanted_cnum)
		return lnum, cnum
	end
end



local editor = {}

function editor:new(s)
	return glue.inherit({
		s = s,
	}, editor)
end

local caret = {}

function caret:new(editor)
	return glue.inherit({
		editor = editor,
		lnum = 1,
		cnum = 1,
		wanted_cnum = 1,
		blink = 0,
		tabsize = 3,
		restrict_right = true,
	}, caret)
end

function caret:move_right()
	self.blink = 0
	self.lnum, self.cnum = move_right(self.editor.s, self.lnum, self.cnum, self.restrict_right, self.restrict_down)
	self.wanted_cnum = self.cnum
end

function caret:move_left()
	self.blink = 0
	self.lnum, self.cnum = move_left(self.editor.s, self.lnum, self.cnum)
	self.wanted_cnum = self.cnum
end

function caret:move_up()
	self.blink = 0
	self.lnum, self.cnum = move_up(self.editor.s, self.lnum, self.cnum, self.wanted_cnum, self.tabsize)
end

function caret:move_down()
	self.lnum, self.cnum = move_down(self.editor.s, self.lnum, self.cnum, self.wanted_cnum, self.tabsize, self.restrict_down)
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


function tokens(s, lexer)
	local lxsh = require'lxsh'
	lexer = lxsh.lexers[lexer]
	local match = lexer.gmatch((s:gsub('\t', '   ')))
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

local function text_coords(s, lnum, cnum, tabsize, linesize, charsize)
	local i, j = line_pos(s, lnum)
	local view_cnum = view_cnum(s, i, j, cnum, tabsize)
	local x = (view_cnum - 1) * charsize
	local y = (lnum - 1) * linesize
	return x, y
end

local function caret_rect(s, lnum, cnum, tabsize, linesize, charsize, caret_width)
	local x, y = text_coords(s, lnum, cnum, tabsize, linesize, charsize)
	return x - caret_width, y, caret_width, linesize - 2
end

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

function viewer:render_caret(cr, caret, editor)
	caret.blink = caret.blink or 0
	caret.blink = caret.blink + 1

	if caret.blink % 40 < 20 then
		cr:set_source_rgba(ccolor(self.caret_color))
		local x, y, w, h = caret_rect(editor.s, caret.lnum, caret.cnum, self.tabsize, self.linesize, self.charsize, 3)
		cr:rectangle(self.x + x, self.y + y, w, h)
		cr:fill()
	end
end



local player = require'cairo_player'

local ed = editor:new(glue.readfile'text_editor.lua')
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

	vwer:render_text(cr, ed.s)
	vwer:render_caret(cr, car, ed)

end

player:play()

