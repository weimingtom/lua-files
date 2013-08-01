local glue = require'glue'

--string module that can be reimplemented to support unicode

local str = {}

function str.next(s, i)
	i = i and i + 1 or 1
	if i > #s then return end
	return i
end

function str.indices(s) --iterate codepoints
	return str.next, s
end

function str.len(s) --number of codepoints in string
	return #s
end

function str.sub(s, ...) --substring based on char indices
	return s:sub(...)
end

function str.istab(s, i) --check if the character at index i is a tab
	return s:byte(i) == 9
end

function str.isspace(s, i) --check if the character at index i is a space
	return s:byte(i) == 32
end

function str.rtrim(s)
	return (s:gsub('%s+$', ''))
end

--helpers for dealing with tabs

--how many spaces from a visual column to the next tabstop, for a specific tabsize
local function tabstop_distance(vcol, tabsize)
	return math.floor((vcol + tabsize) / tabsize) * tabsize - vcol
end

--visual column coresponding to real (char-based) column for a specific tabsize
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

--real (char-based) column that most closely matches a visual column for a specific tabsize
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

--buffer object: holds the line buffers for displaying and changing

local buffer = {}

local function count_patt(s, patt)
	local n = 0
	for _ in s:gmatch(patt) do
		n = n + 1
	end
	return n
end

function buffer:detect_line_terminator(s) --class method
	local rn = count_patt(s, '\r\n') --win lines
	local r  = count_patt(s, '\r') --mac lines
	local n  = count_patt(s, '\n') --unix lines (default)
	if rn > n and rn > r then
		return '\r\n'
	elseif r > n then
		return '\r'
	else
		return '\n'
	end
end

function buffer:new(s)
	s = s or ''
	local lines = {}
	local term = self:detect_line_terminator(s)
	for s in glue.gsplit(s, term) do
		lines[#lines + 1] = s
	end
	return glue.inherit({
		lines = lines,
		line_terminator = term,
		space_past_eol = false,
		force_empty_line = true,
	}, self)
end

function buffer:normalize()
	--remove spaces past eol
	for i,line in ipairs(self.lines) do
		if not self.space_past_eol then
			line = str.rtrim(line)
		end
		self.lines[i] = line
	end
	--add an empty line at eof if necessary
	if self.force_empty_line and self.lines[#self.lines] ~= '' then
		table.insert(self.lines, '')
	end
end

function buffer:save(line_terminator, no_space_past_eol)
	self:normalize()
	return table.concat(self.lines, line_terminator or self.line_terminator)
end

function buffer:find_largest_line() --largest line number
	local len = 0
	local n
	for i, line in ipairs(self.lines) do
		if #line > len then
			n = i
			len = #line
		end
	end
	return n
end

--cursor object: provides caret-based navigation and editing
--TODO: multiple cursors per buffer: notify and adjust other cursors after buffer changes

local cursor = {}

function cursor:new(buffer, view)
	return glue.inherit({
		buffer = buffer,
		view = view, --for tabsize
		line = 1,
		col = 1, --real column
		vcol = 1, --visual column (tabs expanded)
		wanted_vcol = 1, --unrestricted visual column
		insert_mode = true, --insert or overwrite when typing characters
		auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
		restrict_eol = true, --don't allow caret past end-of-line
		restrict_eof = true, --don't allow caret past end-of-file
	}, self)
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
	local s = self:getline()
	local col = 0
	for i in str.indices(s) do
		col = col + 1
		if not str.istab(s, i) and not str.isspace(s, i) then
			break
		end
	end
	return col
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

function cursor:move_left(cols)
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
end

function cursor:move_right(cols)
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
end

function cursor:move_up()
	self.line = self.line - 1
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
end

function cursor:move_down()
	self.line = self.line + 1
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
		self:move_left()
	elseif key == 'right' then
		self:move_right()
	elseif key == 'up' then
		self:move_up()
	elseif key == 'down' then
		self:move_down()
	elseif key == 'insert' then
		c.insert_mode = not c.insert_mode
	elseif key == 'backspace' then
		self:delete_before()
	elseif key == 'delete' then
		self:delete_after()
	elseif key == 'return' then
		self:newline()
	elseif ctrl and key == 'S' then
		self.buffer:save()
	elseif char then
		self:insert(char)
	end
end

--view: displaying the text and the cursor

local view = {}

function view:new(id, x, y, w, h)
	return glue.inherit({
		id = id,
		x = x,
		y = y,
		w = w,
		h = h,
		font_face = 'Fixedsys',
		tabsize = 3,
		linesize = 16,
		charsize = 8,
		caret_width = 2,
		eol_markers = true,
	}, self)
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
			ds = ds .. str.sub(s, col, col)
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
	self.cx, self.cy = cx, cy

	cr:rectangle(x, y, w, h)
	cr:clip()
	cr:set_source_rgba(1, 1, 1, 0.15)
	cr:paint()

	local x = self.cx + self.x
	local y = self.cy + self.y + self.linesize
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

function view:render_cursor(cursor, player)
	local cr = player.cr

	cr:set_source_rgba(1, 1, 1, 1)
	local x, y, w, h = self:caret_rect(cursor)
	cr:rectangle(self.cx + self.x + x, self.cy + self.y + y, w, h)
	cr:fill()
end



local player = require'cairo_player'

local s = [[
A	BB	C
AA	B	C
AAA	BB	C
function lines.pos(s, lnum)
	if lnum < 1 then return end
	local n = 0
	for _, i, j in lines.lines(s) do
		n = n + 1
		if n == lnum then return i, j end
	end
end
]]

local v = view:new('view', 200, 10, 300, 100)
local e = buffer:new(s)
local c = cursor:new(e, v)

function player:on_render(cr)

	--c.restrict_eol = false
	--c.restrict_eof = false

	v.tabsize = self:slider{id = 'tabsize', x = 10, y = 10, w = 80, h = 24, i0 = 1, i1 = 8, i = v.tabsize}
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	e.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = e.line_terminator}

	c:keypress(self.key, self.char, self.ctrl, self.shift)

	v:render_buffer(e, self)
	v:render_cursor(c, self)

end

player:play()

