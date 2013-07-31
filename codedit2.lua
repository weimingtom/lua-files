local glue = require'glue'

local editor = {}

--given a string and an index where a line begins, return that index plus the index of the last character in that line,
--excluding the line terminator, plus the index where the next line begins.
local function nextline(s, i)
	i = i or 1
	if i > #s then return end
	local j, nexti = s:find('\r?\n', i)
	if j then
		return nexti + 1, i, j - 1
	else
		return #s + 1, i, #s
	end
end

local function count_patt(s, patt)
	local n = 0
	for _ in s:gmatch(patt) do
		n = n + 1
	end
	return n
end

local function detect_line_terminator(s)
	local rn = count_patt(s, '\r\n')
	local nr = count_patt(s, '\n\r')
	local n  = count_patt(s, '\n')
	if nr > rn and nr > n then
		return '\n\r'
	elseif rn > nr and rn > n then
		return '\r\n'
	else
		return '\n'
	end
end

function editor:new(s)
	local lines = {}
	for _, i, j in nextline, s do
		lines[#lines + 1] = s:sub(i, j)
	end
	if #lines == 0 then lines[1] = '' end
	return glue.inherit({
		lines = lines,
		line_terminator = detect_line_terminator(s),

	}, self)
end

function editor:save()
	return table.concat(self.lines, self.line_terminator)
end

local cursor = {}

function cursor:new(editor, view)
	return glue.inherit({
		editor = editor,
		view = view,
		line = 1,
		col = 1,
		vcol = 1,
		wanted_vcol = 1,
		insert_mode = true,
	}, self)
end

function cursor:setvcol()
	local s = self.editor.lines[self.line]
	self.vcol = 1
	for i=1,#s do
		if i >= self.col then break end
		self.vcol = self.vcol + (s:byte(i) == 9 and self.view.tabsize or 1)
	end
end

function cursor:setcol()
	local s = self.editor.lines[self.line]
	local vcol = self.vcol
	local vcol1 = 1
	local col = 0
	for i = 1, #s do
		col = col + 1
		local vcol2 = vcol1 + (s:byte(i) == 9 and self.view.tabsize or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			self.col = col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
			return
		end
		vcol1 = vcol2
	end
	self.col = col + vcol - vcol1 + 1
end

function cursor:move_left()
	self.col = self.col - 1
	if self.col == 0 then
		self.line = self.line - 1
		if self.line == 0 then
			self.line = 1
			self.col = 1
		else
			self.col = #self.editor.lines[self.line] + 1
		end
	end
	self:setvcol()
	self.wanted_vcol = self.vcol
end

function cursor:move_right()
	self.col = self.col + 1
	if self.col > #self.editor.lines[self.line] + 1 then
		self.line = self.line + 1
		if self.line > #self.editor.lines then
			self.line = #self.editor.lines
			self.col = #self.editor.lines[self.line] + 1
		else
			self.col = 1
		end
	end
	self:setvcol()
	self.wanted_vcol = self.vcol
end

function cursor:move_up()
	self.line = self.line - 1
	if self.line == 0 then
		self.line = 1
		self.col = 1
		self.vcol = 1
	else
		self.vcol = self.wanted_vcol
		self:setcol()
		self.col = math.min(self.col, #self.editor.lines[self.line] + 1)
		self:setvcol()
	end
end

function cursor:move_down()
	self.line = self.line + 1
	if self.line > #self.editor.lines then
		self.line = #self.editor.lines
		self.col = #self.editor.lines[self.line] + 1
	else
		self.vcol = self.wanted_vcol
		self:setcol()
		self.col = math.min(self.col, #self.editor.lines[self.line] + 1)
	end
	self:setvcol()
end

function cursor:insert(c)
	if c == '\r' then
		local s = self.editor.lines[self.line]
		local s1 = s:sub(1, self.col - 1)
		local s2 = s:sub(self.col)
		self.editor.lines[self.line] = s1
		table.insert(self.editor.lines, self.line + 1, s2)
		self.line = self.line + 1
		self.col = 1
		self.vcol = 1
	else
		local s = self.editor.lines[self.line]
		s = s:sub(1, self.col - 1) .. c .. s:sub(self.col + (self.insert_mode and 0 or #c))
		self.editor.lines[self.line] = s
		self:move_right()
	end
end

function cursor:delete_before()
	if self.col == 1 then
		if self.line > 1 then
			local s = table.remove(self.editor.lines, self.line)
			self.line = self.line - 1
			local s0 = self.editor.lines[self.line]
			self.editor.lines[self.line] = s0 .. s
			self.col = #s0 + 1
			self:setvcol()
		end
	else
		local s = self.editor.lines[self.line]
		s = s:sub(1, self.col - 2) .. s:sub(self.col)
		self.editor.lines[self.line] = s
		self:move_left()
	end
end

function cursor:delete_after()
	local s = self.editor.lines[self.line]
	if self.col > #s then
		if self.line < #self.editor.lines then
			self.editor.lines[self.line] = s .. table.remove(self.editor.lines, self.line + 1)
		end
		--self.col = math.min(self.col, #self.editor.lines[self.line] + 1)
		--self:setvcol()
	else
		s = s:sub(1, self.col - 1) .. s:sub(self.col + 1)
		self.editor.lines[self.line] = s
	end
end

local view = {}

function view:new(x, y, w, h)
	return glue.inherit({
		x = x,
		y = y,
		w = w,
		h = h,
		font_face = 'Fixedsys',
		tabsize = 3,
		linesize = 16,
		charsize = 8,
		caret_width = 2,
	}, self)
end

local function expand_tabs(s, tabsize)
	return (s:gsub('\t', (' '):rep(tabsize)))
end

function view:render_editor(editor, cr)
	cr:save()

	cr:select_font_face(self.font_face, 0, 0)
	cr:rectangle(self.x, self.y, self.w, self.h)
	cr:clip()
	cr:set_source_rgba(1, 1, 1, 0.15)
	cr:paint()

	local x, y = self.x, self.y + self.linesize
	for i,s in ipairs(editor.lines) do
		cr:move_to(x, y)
		cr:set_source_rgba(1, 1, 1, 1)
		cr:show_text(expand_tabs(s, self.tabsize))
		y = y + self.linesize
	end

	cr:restore()
end

function view:text_coords(cursor)
	local x = (cursor.vcol - 1) * self.charsize
	local y = (cursor.line - 1) * self.linesize
	return x, y
end

function view:insert_caret_rect(cursor)
	local x, y = self:text_coords(cursor)
	local w = self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (cursor.vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	y = y + 4
	h = h - 2
	return x, y, w, h
end

function view:over_caret_rect(cursor)
	local x, y = self:text_coords(cursor)
	local w = self.charsize
	local h = self.caret_width
	y = y + self.linesize
	y = y + 1
	return x, y, w, h
end

function view:caret_rect(cursor)
	if cursor.insert_mode then
		return self:insert_caret_rect(cursor)
	else
		return self:over_caret_rect(cursor)
	end
end

function view:render_cursor(cursor, cr)
	cr:set_source_rgba(1, 1, 1, 1)
	local x, y, w, h = self:caret_rect(cursor)
	cr:rectangle(self.x + x, self.y + y, w, h)
	cr:fill()
end



local player = require'cairo_player'

local s = [[
function lines.pos(s, lnum)
	if lnum < 1 then return end
	local n = 0
	for _, i, j in lines.lines(s) do
		n = n + 1
		if n == lnum then return i, j end
	end
end
]]

local v = view:new(10, 10, 500, 300)
local e = editor:new(s)
local c = cursor:new(e, v)

function player:on_render(cr)

	if self.key == 'left' then
		c:move_left()
	elseif self.key == 'right' then
		c:move_right()
	elseif self.key == 'up' then
		c:move_up()
	elseif self.key == 'down' then
		c:move_down()
	elseif self.key == 'insert' then
		c.insert_mode = not c.insert_mode
	elseif self.key == 'backspace' then
		c:delete_before()
	elseif self.key == 'delete' then
		c:delete_after()
	elseif self.char then
		c:insert(self.char)
	end

	v:render_editor(e, cr)
	v:render_cursor(c, cr)

end

player:play()

