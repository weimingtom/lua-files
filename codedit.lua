--modular code editor with many features.

local glue = require'glue'
local str = require'codedit_str'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

--buffer object: holds the lines in a list, for displaying, changing and saving

local buffer = {
	eol_spaces = 'remove', --leave, remove.
	eof_lines = 'leave', --leave, remove, always.
	line_terminator = nil, --line terminator to use for loading and saving. nil means autodetect.
	tabs = 'leave', --leave, never, indent, always - to use for saving. nil means autodetect.
	tabsize = nil, --number to use for saving. nil means autodetect.
}

function buffer:new(t)
	self = glue.inherit(t or {}, self)
	self:load('')
	return self
end

function buffer:insert_line(line, s)
	table.insert(self.lines, line, s)
	self.changed = true
end

function buffer:remove_line(line)
	local s = table.remove(self.lines, line)
	self.changed = true
	return s
end

function buffer:setline(line, s)
	self.lines[line] = s
	self.changed = true
end

function buffer:insert_lines(line, s)
	local i = 1
	while i <= #s do
		local rni = s:find('\r\n', i, true) or #s + 1
		local ni = s:find('\n', i, true) or #s + 1
		local ri = s:find('\r', i, true) or #s + 1
		local j = math.min(rni, ni, ri) - 1
		self:insert_line(line, s:sub(i, j))
		line = line + 1
		i = math.min(rni + 2, ni + 1, ri + 1 + (ri == rni and 1 or 0))
	end
end

function buffer:load(s)
	self.lines = {}
	self:insert_lines(1, s)
	self.changed = false
	self.line_terminator = self.line_terminator or self:detect_line_terminator(s)
	self.tabs = self.tabs or self:detect_tabs()
	self.tabsize = self.tabsize or self:detect_tabsize(self.tabs)
end

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

--TODO: detect never, indent, always tabs modes.
function buffer:detect_tabs()
	for i,line in ipairs(self.lines) do
		local indent_size = str.first_nonspace(line) - 1
		if indent_size > 0 then
			if str.find(line, '\t') then
				return 'indent'
			end
		end
	end
	return 'never'
end

--autodetect tabsize for a given tabs mode
function buffer:detect_tabsize(tabs)
	if tabs == 'never' then
		--TODO
	elseif tabs == 'indent' then
		--TODO
	elseif tabs == 'always' then
		--TODO
	end
end

function buffer:convert_tabs_to_spaces(tabsize)
	local spaces = string.rep(' ', tabsize)
	for i,line in ipairs(self.lines) do
		self.lines[i] = str.replace(line, '\t', spaces)
	end
end

function buffer:convert_indent_spaces_to_tabs(tabsize)
	--TODO
end

function buffer:convert_spaces_to_tabs(tabsize)
	--TODO
end

function buffer:remove_eol_spaces() --remove any spaces past eol
	for i,line in ipairs(self.lines) do
		self.lines[i] = str.rtrim(line)
	end
end

function buffer:add_eof_line() --add an empty line at eof if there is none
	if self.lines[#self.lines] ~= '' then
		self:insert_line(self.lines, '')
	end
end

function buffer:remove_eof_lines() --remove any empty lines at eof, except line 1
	while #self.lines > 1 and self.lines[#self.lines] == '' do
		self.lines[#self.lines] = nil
	end
end

function buffer:normalize()
	if self.eol_spaces == 'remove' then
		self:remove_eol_spaces()
	end
	if self.eof_lines == 'always' then
		self:add_eof_line()
	elseif self.eof_lines == 'remove' then
		self:remove_eof_lines()
	end
	if self.tabs == 'never' then
		self:convert_tabs_to_spaces(self.tabsize)
	elseif self.tabs == 'indent' then
		self:convert_indent_spaces_to_tabs(self.tabsize)
	elseif self.tabs == 'always' then
		self:convert_spaces_to_tabs(self.tabsize)
	end
end

function buffer:save()
	self:normalize()
	return table.concat(self.lines, self.line_terminator)
end

--selection object: selecting text between two line,col pairs.
--line1,col1 is the first selected char and line2,col2 is the char after the last selected char.

local selection = {}

function selection:new(t)
	assert(t.buffer, 'buffer missing')
	self = glue.inherit(t, self)
	self:move(1, 1)
	return self
end

function selection:isempty()
	return self.line2 == self.line1 and self.col2 == self.col1
end

function selection:move(line, col, selecting)
	if selecting then
		local line1, col1 = self.anchor_line, self.anchor_col
		local line2, col2 = line, col
		--switch cursors if the end cursor is before the start cursor
		if line2 < line1 then
			line2, line1 = line1, line2
			col2, col1 = col1, col2
		elseif line2 == line1 and col2 < col1 then
			col2, col1 = col1, col2
		end
		--restrict selection to the available buffer
		self.line1 = clamp(line1, 1, #self.buffer.lines)
		self.line2 = clamp(line2, 1, #self.buffer.lines)
		self.col1 = clamp(col1, 1, str.len(self.buffer.lines[self.line1]) + 1)
		self.col2 = clamp(col2, 1, str.len(self.buffer.lines[self.line2]) + 1)
	else
		--reset and re-anchor the selection
		self.anchor_line = line
		self.anchor_col = col
		self.line1, self.col1 = line, col
		self.line2, self.col2 = line, col
	end
end

function selection:cols(line)
	assert(line >= self.line1 and line <= self.line2, 'out of range')
	local col1, col2 = self.col1, self.col2
	if not self.block then
		col1 = line == self.line1 and col1 or 1
		col2 = line == self.line2 and col2 or str.len(self.buffer.lines[line]) + 1
	end
	--restrict selection to the available buffer
	local maxcol = str.len(self.buffer.lines[line])
	col1 = clamp(col1, 1, maxcol + 1)
	col2 = clamp(col2, 1, maxcol + 1)
	return col1, col2
end

function selection:copy()
	local t = {}
	for line = self.line1, self.line2 do
		local col1, col2 = self:cols(line)
		t[#t+1] = str.sub(self.buffer.lines[line], col1, col2 - 1)
	end
	return table.concat(t, self.buffer.line_terminator)
end

function selection:remove()
	if self.block then
		for line = self.line1, self.line2 do
			local col1, col2 = self:cols(line)
			local s1 = str.sub(self.buffer.lines[line], 1, col1 - 1)
			local s2 = str.sub(self.buffer.lines[line], col2)
			self.buffer:setline(line, s1 .. s2)
		end
	else
		local s1 = str.sub(self.buffer.lines[self.line1], 1, self.col1 - 1)
		local s2 = str.sub(self.buffer.lines[self.line2], self.col2)
		for line = self.line1, self.line2 - 1 do
			self.buffer:remove_line(self.line1)
		end
		self.buffer:setline(line, s1 .. s2)
	end
	self:move(self.line1, self.col1)
end

function selection:replace(s)
	self:remove()
	--TODO: insert, see cursor:insert()
end

--cursor object: caret-based navigation and editing

local cursor = {
	insert_mode = true, --insert or overwrite when typing characters
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = true, --don't allow caret past end-of-file
	tabs = 'indent', --'never', 'indent', 'always'
	tab_align_list = true, --align to the next word on the above line; incompatible with tabs = 'always'
	tab_align_args = true, --align to the char after '(' on the above line; incompatible with tabs = 'always'
}

function cursor:new(t)
	assert(t.buffer, 'buffer missing') --for access to lines
	assert(t.view, 'view missing') --for visual_col(), real_col() and expand_tabs()
	self = glue.inherit(t, self)
	self.line = 1
	self.col = 1 --real column
	self.vcol = 1 --unrestricted visual column
	return self
end

--cursor-buffer connection

function cursor:last_col()
	return str.len(self.buffer.lines[self.line])
end

function cursor:getline()
	return self.buffer.lines[self.line]
end

function cursor:setline(s)
	self.buffer:setline(self.line, s)
end

function cursor:insert_line(s)
	self.buffer:insert_line(self.line, s)
end

function cursor:remove_line(line)
	return self.buffer:remove_line(line or self.line)
end

function cursor:indent_col() --return the column where the indented text starts
	return str.first_nonspace(self:getline())
end

--cursor-view connection

function cursor:visual_col()
	return self.view:visual_col(self.buffer, self.line, self.col)
end

function cursor:real_col()
	local col = self.view:real_col(self.buffer, self.line, self.vcol)
	if self:getline() and self.restrict_eol then
		return clamp(col, 1, self:last_col() + 1)
	end
end

--navigation state helpers

--store the current visual column to be restored on key up/down
function cursor:store_vcol()
	self.vcol = self:visual_col()
end

--set real column based on the stored visual column
function cursor:restore_vcol()
	self.col = self:real_col()
end

--navigation

function cursor:move_left(cols, selecting)
	cols = cols or 1
	self.col = self.col - cols
	if self.col < 1 then
		self.line = self.line - 1
		if self.line == 0 then
			self.line = 1
			self.col = 1
		else
			self.col = self:last_col() + 1
		end
	end
	self:store_vcol()
end

function cursor:move_right(cols, selecting)
	cols = cols or 1
	self.col = self.col + cols
	if self.restrict_eol and self.col > self:last_col() + 1 then
		self.line = self.line + 1
		if self.line > #self.buffer.lines then
			self.line = #self.buffer.lines
			self.col = self:last_col() + 1
		else
			self.col = 1
		end
	end
	self:store_vcol()
end

function cursor:move_up(lines, selecting)
	lines = lines or 1
	self.line = self.line - lines
	if self.line == 0 then
		self.line = 1
		if self.restrict_eol then
			self.col = 1
		end
	else
		self:restore_vcol()
	end
end

function cursor:move_down(lines, selecting)
	lines = lines or 1
	self.line = self.line + lines
	if self.line > #self.buffer.lines then
		if self.restrict_eof then
			self.line = #self.buffer.lines
			self.col = self:last_col() + 1
		end
	else
		self:restore_vcol()
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

--editing

function cursor:newline()
	local s = self:getline()
	local landing_col, indent = 1, ''
	if self.auto_indent then
		landing_col = self:indent_col()
		indent = str.sub(s, 1, landing_col - 1)
	end
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = indent .. str.sub(s, self.col)
	self:setline(s1)
	self.line = self.line + 1
	self:insert_line(s2)
	self.col = landing_col
	self:store_vcol()
end

function cursor:insert(c)
	local s = self:getline()
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = str.sub(s, self.col + (self.insert_mode and 0 or 1))

	if self.autoalign_list or self.autoalign_args then
		--look in the line above for the vcol of the first non-space char after at least one space or '(', starting at vcol
		if str.first_nonspace(s1) < #s1 then
			local vcol = self:visual_col()
			local col1 = self.view:real_col(self.buffer, self.line-1, vcol)
			local stage = 0
			local s0 = self.buffer.lines[self.line-1]
			for i in str.indices(s0) do
				if i >= col1 then
					if stage == 0 and (str.isspace(s0, i) or str.ischar(s0, i, '(')) then
						stage = 1
					elseif stage == 1 and not str.isspace(s0, i) then
						stage = 2
						break
					end
					col1 = col1 + 1
				end
			end
			if stage == 2 then
				local vcol1 = self.view:visual_col(self.buffer, self.line-1, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = self.view:expand_tabs(c)
			end
		end
	elseif self.tabs == 'never' then
		c = self.view:expand_tabs(c)
	elseif self.tabs == 'indent' then
		if str.first_nonspace(s1) <= #s1 then
			c = self.view:expand_tabs(c)
		end
	end

	self:setline(s1 .. c .. s2)
	self:move_right(str.len(c))
end

function cursor:delete_before()
	if self.col == 1 then
		if self.line > 1 then
			local s = self:remove_line()
			self.line = self.line - 1
			local s0 = self:getline()
			self:setline(s0 .. s)
			self.col = str.len(s0) + 1
			self:store_vcol()
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
		if self.line < #self.buffer.lines then
			self:setline(self:getline() .. self:remove_line(self.line + 1))
		end
		--self.col = math.min(self.col, #self.buffer.lines[self.line] + 1)
		--self:store_vcol()
	else
		local s = self:getline()
		self:setline(str.sub(s, 1, self.col - 1) .. str.sub(s, self.col + 1))
	end
end

--view: centralises visual options and methods for measuring and displaying buffers, cursors and selections.

local view = {
	--tab metrics
	tabsize = 3,
	--font metrics
	linesize = 1,
	charsize = 1,
	charvsize = 1,
	--caret metrics
	caret_width = 2,
	--scrolling state
	cx = 0,
	cy = 0,
	--scrolling options
	smooth_vscroll = false,
	smooth_hscroll = true,
	padding = {left = 1, top = 1, right = 1, bottom = 1},
}

function view:new(t)
	return glue.inherit(t, self)
end

--helpers to translate between visual columns and real columns based on a specified tabsize.
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

function view:expand_tabs(s)
	return str.replace(s, '\t', string.rep(' ', self.tabsize))
end

function view:tabstop_distance(vcol)
	return tabstop_distance(vcol, self.tabsize)
end

function view:visual_col(buffer, line, col)
	local s = buffer.lines[line]
	if s then
		return visual_col(s, col, self.tabsize)
	else
		return col --outside eof visual columns and real columns are the same
	end
end

function view:real_col(buffer, line, vcol)
	local s = buffer.lines[line]
	if s then
		return real_col(s, vcol, self.tabsize)
	else
		return vcol --outside eof visual columns and real columns are the same
	end
end

--find the maximum visual line length of a buffer
function view:max_visual_col(buffer)
	local maxlen = 0
	for i,line in ipairs(buffer.lines) do
		local len = self:visual_col(buffer, line, str.len(line))
		if len > maxlen then
			maxlen = len
		end
	end
	return maxlen
end

--helpers to translate between cursor space and screen space, i.e. (line,vcol) <-> (x,y)

function view:cursor_coords(line, vcol)
	local x = (vcol - 1) * self.charsize
	local y = (line - 1) * self.linesize
	return x, y
end

function view:cursor_at(x, y)
	local line = math.floor(y / self.linesize) + 1
	local vcol = math.floor((x + self.charsize / 2) / self.charsize) + 1
	return line, vcol
end

--computing the caret rectangle of a cursor

function view:insert_caret_rect(cursor)
	local vcol = cursor:visual_col()
	local x, y = self:cursor_coords(cursor.line, vcol)
	local w = self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	return x, y, w, h
end

function view:over_caret_rect(cursor)
	local vcol = cursor:visual_col()
	local x, y = self:cursor_coords(cursor.line, vcol)
	local w = self.charsize
	if str.istab(cursor:getline(), cursor.col) then --make cursor as wide as the tabspace
		w = self:tabstop_distance(vcol - 1)
	end
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

--computing the selection rectangles

function view:selection_rect(sel, line)
	local col1, col2 = sel:cols(line)
	local vcol1 = self:visual_col(sel.buffer, line, col1)
	local vcol2 = self:visual_col(sel.buffer, line, col2)
	local x1 = (vcol1 - 1) * self.charsize
	local x2 = (vcol2 - 1) * self.charsize
	if line < sel.line2 then
		x2 = x2 + 0.5 --show eol as half space
	end
	local y1 = (line - 1) * self.linesize
	local y2 = line * self.linesize
	return x1, y1, x2 - x1, y2 - y1
end

--scrolling the view by screen coordinates

function view:scroll(cx, cy)
	if not self.smooth_vscroll then
		--snap vertical offset to linesize
		local r = cy % self.linesize
		cy = cy - r + self.linesize * (r > self.linesize / 2 and 1 or 0)
	end
	if not self.smooth_hscroll then
		--snap horiz. offset to charsize
		local r = cx % self.charsize
		cx = cx - r + self.charsize * (r > self.charsize / 2 and 1 or 0)
	end
	self.cx = cx
	self.cy = cy
end

--scrolling the view to make the cursor visible

function view:scroll_to(line, vcol)
	local x, y = self:cursor_coords(line, vcol)
	local w = x + self.charsize
	local h = y + self.linesize
	x = x - self.charsize * self.padding.left
	y = y - self.linesize * self.padding.top
	w = w + self.charsize * self.padding.right
	h = h + self.linesize * self.padding.bottom
	local cx = clamp(self.cx, x + w - self.cw, x)
	local cy = clamp(self.cy, y + h - self.ch, y)
	self:scroll(cx, cy)
end


if not ... then require'codedit_demo' end

return {
	str = str,
	buffer = buffer,
	selection = selection,
	cursor = cursor,
	view = view,
}

