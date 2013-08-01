--modular code editor with many features.
--TODO: multiple cursors per buffer: notify and adjust other cursors after buffer changes.

local glue = require'glue'
local str = require'codedit_str'

--helpers for dealing with tabs.
--real columns map 1:1 to char indices, while visual columns represent screen columns after tab expansion.

--how many spaces from a visual column to the next tabstop, for a specific tabsize.
local function tabstop_distance(vcol, tabsize)
	return math.floor((vcol + tabsize) / tabsize) * tabsize - vcol
end

--visual column coresponding to a real column for a specific tabsize.
--the real column can be past string's end, in which case vcol will expand to the same amount.
local function visual_col(s, col, tabsize)
	local col1 = 0
	local vcol = 1
	for i in str.indices(s) do
		col1 = col1 + 1
		if col1 >= col then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and tabstop_distance(vcol - 1, tabsize) or 1)
	end
	vcol = vcol + col - col1 - 1 --extend vcol past eol
	return vcol
end

--real column corresponding to a visual column for a specific tabsize.
--if the target vcol is between two possible vcols, return the vcol that is closer.
local function real_col(s, vcol, tabsize)
	local vcol1 = 1
	local col = 0
	for i in str.indices(s) do
		col = col + 1
		local vcol2 = vcol1 + (str.istab(s, i) and tabstop_distance(vcol1 - 1, tabsize) or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			return col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
		end
		vcol1 = vcol2
	end
	col = col + vcol - vcol1 + 1 --extend col past eol
	return col
end

--buffer object: holds the lines in a list, for displaying and changing

local buffer = {}

--class method that returns the most common line terminator in a string, or '\n' if there are no terminators
function buffer:detect_line_terminator(s)
	local rn = str.count(s, '\r\n') --win lines
	local r  = str.count(s, '\r') --mac lines
	local n  = str.count(s, '\n') --unix lines (default)
	if rn > n and rn > r then
		return '\r\n'
	elseif r > n then
		return '\r'
	else
		return '\n'
	end
end

function buffer:new(t)
	local s = t.string or ''
	local lines = {}
	local term = self:detect_line_terminator(s)
	for s in glue.gsplit(s, term) do
		lines[#lines + 1] = s
	end
	t = glue.update({
		eol_spaces = 'leave', --'leave', 'remove'
		eof_lines = 'leave', -- 'leave', 'remove', 'always'
		line_terminator = term,
	}, t)
	t.string = nil --release the ref. to the string
	t.lines = lines
	return glue.inherit(t, self)
end

function buffer:normalize()
	--remove spaces past eol
	if self.eol_spaces == 'remove' then
		for i,line in ipairs(self.lines) do
			self.lines[i] = str.rtrim(line)
		end
	end
	if self.eof_lines == 'always' then
		--add an empty line at eof if there is none
		if self.lines[#self.lines] ~= '' then
			table.insert(self.lines, '')
		end
	elseif self.eof_lines == 'remove' then
		--remove any empty lines at eof, except the last one
		while #self.lines > 1 and self.lines[#self.lines] == '' do
			self.lines[#self.lines] = nil
		end
	end
end

function buffer:save()
	self:normalize()
	return table.concat(self.lines, self.line_terminator)
end

function buffer:len(line)
	return str.len(assert(self.lines[line], 'invalid line'))
end

function buffer:restrict_line(line)
	return math.min(math.max(line, 1), #self.lines)
end

function buffer:restrict_col(line, col, over_min, over_max)
	return math.min(math.max(col, 1 - (over_min or 0)), self:len(line) + (over_max or 0))
end

--selection object: provides selection

local selection = {}

function selection:new(t)
	assert(t.buffer, 'buffer missing')
	t = glue.update({
		line1 = 1, line2 = 1, col1 = 1, col2 = 1,
	}, t)
	return glue.inherit(t, self)
end

function selection:isempty()
	return self.line2 == self.line1 and self.col2 == self.col1
end

function selection:reset(line, col)
	self.anchor_line = line
	self.anchor_col = col
	self.line1, self.col1 = line, col
	self.line2, self.col2 = line, col
end

function selection:move(line2, col2)
	local line1, col1 = self.anchor_line, self.anchor_col
	if line2 < line1 then
		line2, line1 = line1, line2
		col2, col1 = col1, col2
	elseif line2 == line1 then
		if col2 < col1 then
			col2, col1 = col1, col2
		end
	end
	self.line1, self.col1 = line1, col1
	self.line2, self.col2 = line2, col2
end

--[[
function selection:vcols(line, self.tabsize)
	local col1 = line == self.line1 and self.col1 or 1
	local col2 = line == self.line2 and self.col2 or str.len(s) + 1

	col1 = math.min(math.max(col, 1), str.len(s) + 1)
	local vcol = visual_col(s, col, self.tabsize)
]]

--cursor object: provides caret-based navigation and editing

local cursor = {}

function cursor:new(t)
	assert(t.buffer, 'buffer msising')
	assert(t.view, 'view missing')
	t = glue.update({
		--state
		line = 1,
		col = 1, --real column
		vcol = 1, --visual column (tabs expanded)
		wanted_vcol = 1, --unrestricted visual column
		selection = selection:new{buffer = t.buffer},
		--options
		insert_mode = true, --insert or overwrite when typing characters
		auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
		restrict_eol = true, --don't allow caret past end-of-line
		restrict_eof = true, --don't allow caret past end-of-file
	}, t)
	return glue.inherit(t, self)
end

function cursor:getline(line)
	return self.buffer.lines[line or self.line]
end

function cursor:setline(s, line)
	self.buffer.lines[line or self.line] = s
end

function cursor:insert_line(s, line)
	return table.insert(self.buffer.lines, line or self.line, s)
end

function cursor:remove_line(line)
	return table.remove(self.buffer.lines, line or self.line)
end

function cursor:last_line()
	return #self.buffer.lines
end

function cursor:last_col(line)
	return str.len(self:getline(line))
end

function cursor:indent_col() --return the column where the indented text starts
	return str.first_nonspace(self:getline())
end

--find and set the visual column at the beginning of the real (char) column, expanding any tabs.
function cursor:_setvcol()
	local s = self:getline()
	if s then
		self.vcol = visual_col(s, self.col, self.view.tabsize)
	else
		self.vcol = self.col --outside eof visual columns and real columns are the same
	end
end

--find and set the real (char) column that most closely matches the wanted visual column.
function cursor:_setcol()
	local s = self:getline()
	if s then
		self.col = real_col(s, self.vcol, self.view.tabsize)
		if self.restrict_eol then
			self.col = math.min(self.col, self:last_col() + 1)
		end
	else
		self.col = self.vcol --outside eof visual columns and real columns coincide
	end
end

function cursor:move_left(cols, selecting)
	cols = cols or 1
	self.col = self.col - cols
	if self.col == 0 then
		self.line = self.line - 1
		if self.line == 0 then
			self.line = 1
			self.col = 1
		else
			self.col = self:last_col() + 1
		end
	end
	self:_setvcol()
	self.wanted_vcol = self.vcol

	if selecting then
		self.selection:move(self.line, self.col)
	else
		self.selection:reset(self.line, self.col)
	end
end

function cursor:move_right(cols, selecting)
	cols = cols or 1

	self.col = self.col + cols
	if self.restrict_eol and self.col > self:last_col() + 1 then
		self.line = self.line + 1
		if self.line > self:last_line() then
			self.line = self:last_line()
			self.col = self:last_col() + 1
		else
			self.col = 1
		end
	end
	self:_setvcol()
	self.wanted_vcol = self.vcol

	if selecting then
		self.selection:move(self.line, self.col)
	else
		self.selection:reset(self.line, self.col)
	end
end

function cursor:move_up(lines, selecting)
	lines = lines or 1

	self.line = self.line - lines
	if self.line == 0 then
		self.line = 1
		if self.restrict_eol then
			self.col = 1
			self.vcol = 1
		end
	else
		self.vcol = self.wanted_vcol
		self:_setcol()
		self:_setvcol()
	end

	if selecting then
		self.selection:move(self.line, self.col)
	else
		self.selection:reset(self.line, self.col)
	end
end

function cursor:move_down(lines, selecting)
	lines = lines or 1
	self.line = self.line + lines
	if self.line > self:last_line() then
		if self.restrict_eof then
			self.line = self:last_line()
			self.col = self:last_col() + 1
		end
	else
		self.vcol = self.wanted_vcol
		self:_setcol()
	end
	self:_setvcol()

	if selecting then
		self.selection:move(self.line, self.col)
	else
		self.selection:reset(self.line, self.col)
	end
end

function cursor:move_left_word()
	self:move_left(self.col)
end

function cursor:move_right_word()
	local s = self:getline()
	local i = s:find('', self.col)
	self:move_right()
end

function cursor:newline()
	local s = self:getline()
	local indent_col, indent = 1, ''
	if self.auto_indent then
		indent_col = self:indent_col()
		indent = str.sub(s, 1, indent_col - 1)
	end
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = indent .. str.sub(s, self.col)
	self:setline(s1)
	self:insert_line(s2, self.line + 1)
	self.line = self.line + 1
	self.col = indent_col
	self:_setvcol()
end

function cursor:insert(c)
	local s = self:getline()
	s = str.sub(s, 1, self.col - 1) .. c .. str.sub(s, self.col + (self.insert_mode and 0 or 1))
	self:setline(s)
	self:move_right()
end

function cursor:delete_before()
	if self.col == 1 then
		if self.line > 1 then
			local s = self:remove_line()
			self.line = self.line - 1
			local s0 = self:getline()
			self:setline(s0 .. s)
			self.col = str.len(s0) + 1
			self:_setvcol()
		end
	else
		local s = self:getline()
		s = str.sub(s, 1, self.col - 2) .. str.sub(s, self.col)
		self:setline(s)
		self:move_left()
	end
end

function cursor:delete_after()
	if self.col > self:last_col() then
		if self.line < self:last_line() then
			self:setline(self:getline() .. self:remove_line(self.line + 1))
		end
		--self.col = math.min(self.col, #self.buffer.lines[self.line] + 1)
		--self:_setvcol()
	else
		local s = self:getline()
		self:setline(str.sub(s, 1, self.col - 1) .. str.sub(s, self.col + 1))
	end
end

function cursor:keypress(key, char, ctrl, shift)
	if key == 'left' then
		self:move_left(1, shift)
	elseif key == 'right' then
		self:move_right(1, shift)
	elseif key == 'up' then
		self:move_up(1, shift)
	elseif key == 'down' then
		self:move_down(1, shift)
	elseif key == 'insert' then
		self.insert_mode = not self.insert_mode
	elseif key == 'backspace' then
		self:delete_before()
	elseif key == 'delete' then
		self:delete_after()
	elseif key == 'return' then
		self:newline()
	elseif ctrl and key == 'S' then
		return self.buffer:save()
	elseif char then
		self:insert(char)
	end
end

--view: displaying the text and the cursor

local view = {}

function view:new(t)
	assert(t.id, 'id missing')
	assert(t.x, 'x missing')
	assert(t.y, 'y missing')
	assert(t.w, 'w missing')
	assert(t.h, 'h missing')
	t = glue.update({
		font_face = 'Fixedsys',
		tabsize = 3,
		linesize = 16,
		charsize = 8,
		charvsize = 10,
		caret_width = 2,
		eol_markers = true,
		smooth_scrolling = false,
	}, t)
	return glue.inherit(t, self)
end

function view:scroll(cx, cy)
	if not self.smooth_scrolling then
		local r = cy % self.linesize
		cy = cy - r + self.linesize * (r > self.linesize / 2 and 1 or 0)
	end
	self.cx = cx
	self.cy = cy
end

function view:expand_tabs(s)
	local ts = self.tabsize
	local ds = ''
	local col = 0
	for i in str.indices(s) do
		col = col + 1
		if str.istab(s, i) then
			ds = ds .. (' '):rep(tabstop_distance(#ds, self.tabsize))
		else
			ds = ds .. s:sub(col, col) --str.sub(s, col, col)
		end
	end
	return ds
end

function view:render_buffer(buffer, player)
	local cr = player.cr

	cr:save()

	cr:select_font_face(self.font_face, 0, 0)

	--find the maximum visual line length
	local maxlen = 0
	for i,line in ipairs(buffer.lines) do
		local len = visual_col(line, str.len(line), self.tabsize)
		if len > maxlen then
			maxlen = len
		end
	end

	local cw = self.charsize * maxlen
	local ch = self.linesize * #buffer.lines

	local cx, cy, x, y, w, h = player:scrollbox{id = self.id, x = self.x, y = self.y, w = self.w, h = self.h,
																cx = self.cx, cy = self.cy, cw = cw, ch = ch}

	self:scroll(cx, cy)

	cr:rectangle(x, y, w, h)
	cr:clip()
	cr:set_source_rgba(1, 1, 1, 0.15)
	cr:paint()

	local x = self.cx + self.x
	local y = self.cy + self.y + self.linesize - math.floor((self.linesize - self.charvsize) / 2)
	for i,s in ipairs(buffer.lines) do

		s = self:expand_tabs(s)
		cr:move_to(x, y)
		cr:set_source_rgba(1, 1, 1, 1)
		cr:show_text(s)

		if self.eol_markers then
			cr:rectangle(x + str.len(s) * self.charsize, y - self.linesize, 1, self.linesize)
			cr:set_source_rgba(1, 1, 1, 0.5)
			cr:fill()
		end

		y = y + self.linesize
	end

	cr:restore()
end

function view:coords(vcol, line)
	local x = (vcol - 1) * self.charsize
	local y = (line - 1) * self.linesize
	return x, y
end

function view:insert_caret_rect(cursor)
	local x, y = self:coords(cursor.vcol, cursor.line)
	local w = self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (cursor.vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	return x, y, w, h
end

function view:over_caret_rect(cursor)
	local x, y = self:coords(cursor.vcol, cursor.line)
	local w = self.charsize *
		(str.istab(cursor:getline(), cursor.col) and tabstop_distance(cursor.vcol - 1, self.tabsize) or 1)
	local h = self.caret_width
	y = y + self.linesize
	y = y - math.floor((self.linesize - self.charvsize) / 2) + 1
	return x, y, w, h
end

function view:caret_rect(cursor)
	if cursor.insert_mode then
		return self:insert_caret_rect(cursor)
	else
		return self:over_caret_rect(cursor)
	end
end

function view:render_cursor(cursor, player)
	local cr = player.cr

	cr:set_source_rgba(1, 1, 1, 1)
	local x, y, w, h = self:caret_rect(cursor)
	cr:rectangle(self.cx + self.x + x, self.cy + self.y + y, w, h)
	cr:fill()
end

function view:scroll_into_view(cursor)
	local x, y, w, h = self:caret_rect(cursor)
	--TODO
	self:scroll()
end

function view:selection_xcoord(s, col)
	col = math.min(math.max(col, 1), str.len(s) + 1.5)
	local vcol = visual_col(s, col, self.tabsize)
	return (vcol - 1) * self.charsize
end

function view:render_selection(sel, player)
	local cr = player.cr

	if sel:isempty() then return end

	cr:new_path()
	for line = sel.line1, sel.line2 do
		local s = sel.buffer.lines[line]
		local col1 = line == sel.line1 and sel.col1 or 1
		local col2 = line == sel.line2 and sel.col2 or str.len(s) + 1.5
		local x1 = self:selection_xcoord(s, col1)
		local x2 = self:selection_xcoord(s, col2)
		local y1 = (line - 1) * self.linesize
		local y2 = line * self.linesize
		cr:rectangle(self.x + x1, self.y + y1, x2 - x1, y2 - y1)
	end

	cr:set_source_rgba(1, 1, 1, 0.4)
	cr:fill()
end

if not ... then require'codedit_demo' end

return {
	str = str,
	buffer = buffer,
	selection = selection,
	cursor = cursor,
	view = view,
}

