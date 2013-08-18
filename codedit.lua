--codedit: code editor engine by Cosmin Apreutesei.

local glue = require'glue'
local str = require'codedit_str'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

local editor = {
	--normalizing
	eol_spaces = 'remove', --leave, remove.
	eof_lines = 1, --leave, remove, ensure, or a number.
	--saving
	line_terminator = nil, --line terminator to use when saving. nil means autodetect.
	--tab expansion
	tabsize = 3,
	--metrics (assuming a monospace font and fixed line height)
	linesize = 1,
	charsize = 1,
	charvsize = 1,
	caret_width = 2,
	--scrolling
	smooth_vscroll = false,
	smooth_hscroll = true,
	margins = {left = 0, top = 0, right = 0, bottom = 0}, --invisible cursor margins, in pixels
	--line numbers
	line_numbers = true,
	--cursor class
	cursor = {
		insert_mode = true, --insert or overwrite when typing characters
		auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
		restrict_eol = true, --don't allow caret past end-of-line
		restrict_eof = false, --don't allow caret past end-of-file
		tabs = 'indent', --'never', 'indent', 'always'
		tab_align_list = true, --align to the next word on the above line; incompatible with tabs = 'always'
		tab_align_args = true, --align to the char after '(' on the above line; incompatible with tabs = 'always'
		color = nil, --custom color
		caret_width = nil, --custom width
	},
	--selection class
	selection = {
		block = false, --insert, block mode
		color = nil, --custom color
	},
	--input bindings
	commands = {}, --commands for key bindings; defined below
	key_bindings = {
		['ctrl+up']     = 'line_up',
		['ctrl+down']   = 'line_down',
		['left']        = 'move_left',
		['right']       = 'move_right',
		['up']          = 'move_up',
		['down']        = 'move_down',
		['shift+left']  = 'select_left',
		['shift+right'] = 'select_right',
		['shift+up']    = 'select_up',
		['shift+down']  = 'select_down',
		['ctrl+home']   = 'move_home',
		['ctrl+end']    = 'move_end',
		['home']        = 'move_bol',
		['end']         = 'move_eol',
		['pageup']      = 'page_up',
		['pagedown']    = 'page_down',
		['insert']      = 'toggle_insert_mode',
		['backspace']   = 'delete_before_cursor',
		['delete']      = 'delete_after_cursor',
		['return']      = 'newline',
		['ctrl+A']      = 'select_all',
		['ctrl+X']      = 'cut',
		['ctrl+C']      = 'copy',
		['ctrl+V']      = 'paste',
		['tab']         = 'indent',
		['shift+tab']   = 'outdent',
		['ctrl+S']      = 'save',
	},
}

function editor:new(options)
	self = glue.inherit(options or {}, self)
	local text = self.text or ''
	self.line_terminator = self.line_terminator or self:detect_line_terminator(text)
	self.lines = {''} --can't have zero lines
	self:insert_string(1, 1, text)
	self.changed = false
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
	self.cursors = {}
	self.selections = {}
	self.cursor = self.cursor:new(self)
	self.selection = self.selection:new(self)
	self.scroll_x = 0
	self.scroll_y = 0
	return self
end

--class method that returns the most common line terminator in a string, or '\n' if there are no terminators
function editor:detect_line_terminator(s)
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

function editor:last_col(line)
	return str.len(self.lines[line])
end

--undo/redo stack --------------------------------------------------------------------------------------------------------

function editor:start_undo_group()
	if self.undo_group then
		self:end_undo_group()
	end
	self.undo_group = {commands = {}}
end

function editor:end_undo_group()
	if #self.undo_group.commands > 0 then
		table.insert(self.undo_stack, self.undo_group)
	end
	self.undo_group = nil
end

function editor:undo_command(...)
	if not self.undo_group then return end
	table.insert(self.undo_group.commands, {...})
end

function editor:undo()
	local group = table.remove(self.undo_stack)
	self:start_undo_group()
	for i,t in ipairs(group.commands) do
		self[t[1]](self, unpack(t, 2))
	end
	self:end_undo_group()
	table.insert(self.redo_stack, table.remove(self.undo_stack))
end

function editor:redo()
	local group = table.remove(self.redo_stack)
	self:start_undo_group()
	for i,t in ipairs(group.commands) do
		self[t[1]](self, unpack(t, 2))
	end
	self:end_undo_group()
	table.insert(self.undo_stack, table.remove(self.redo_stack))
end

--changing lines ---------------------------------------------------------------------------------------------------------

function editor:insert_line(line, s)
	table.insert(self.lines, line, s)
	self:undo_command('remove_line', line)
	self.changed = true
end

function editor:remove_line(line)
	local s = table.remove(self.lines, line)
	self:undo_command('insert_line', line, s)
	self.changed = true
	return s
end

function editor:setline(line, s)
	self:undo_command('setline', line, self.lines[line])
	self.lines[line] = s
	self.changed = true
end

--changing text ----------------------------------------------------------------------------------------------------------

--insert a multiline string at a specific position in the text, returning the position after the last character.
function editor:insert_string(line, col, s)
	local s0 = self.lines[line]
	local s1 = str.sub(s0, 1, col - 1)
	local s2 = str.sub(s0, col)
	s = s1 .. s .. s2
	local first_line = line
	for _,s in str.lines(s) do
		if line == first_line then
			self:setline(line, s)
		else
			self:insert_line(line, s)
		end
		line = line + 1
	end
	line = line - 1
	return line, self:last_col(line) - #s2 + 1
end

--remove the string between two positions in the text, returning the position after the last character.
function editor:remove_string(line1, col1, line2, col2)
	local s1 = str.sub(self.lines[line1], 1, col1 - 1)
	local s2 = str.sub(self.lines[line2], col2)
	for line = line2, line1 + 1, -1 do
		self:remove_line(line)
	end
	self:setline(line1, s1 .. s2)
	return line2, col2
end

--normalization and saving -----------------------------------------------------------------------------------------------

function editor:remove_eol_spaces() --remove any spaces past eol
	for i,line in ipairs(self.lines) do
		self.lines[i] = str.rtrim(line)
	end
end

function editor:ensure_eof_line() --add an empty line at eof if there is none
	if self.lines[#self.lines] ~= '' then
		self:insert_line(#self.lines + 1, '')
	end
end

function editor:remove_eof_lines() --remove any empty lines at eof, except the first line
	while #self.lines > 1 and str.first_nonspace(self.lines[#self.lines]) > #self.lines[#self.lines] do
		self.lines[#self.lines] = nil
	end
end

function editor:normalize()
	if self.eol_spaces == 'remove' then
		self:remove_eol_spaces()
	end
	if self.eof_lines == 'ensure' then
		self:ensure_eof_line()
	elseif self.eof_lines == 'remove' then
		self:remove_eof_lines()
	elseif type(self.eof_lines) == 'number' then
		self:remove_eof_lines()
		for i = 1, self.eof_lines do
			self:insert_line(#self.lines + 1, '')
		end
	end
end

function editor:contents()
	self:normalize()
	return table.concat(self.lines, self.line_terminator)
end

--tab expansion ----------------------------------------------------------------------------------------------------------

--translating between visual columns and real columns based on a fixed tabsize.
--real columns map 1:1 to char indices, while visual columns represent screen columns after tab expansion.

--how many spaces from a visual column to the next tabstop, for a specific tabsize.
local function tabstop_distance(vcol, tabsize)
	return math.floor((vcol + tabsize) / tabsize) * tabsize - vcol
end

--real column -> visual column, for a fixed tabsize.
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

--visual column -> real column, for a fixed tabsize.
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

function editor:expand_tab()
	return string.rep(' ', self.tabsize)
end

function editor:tabstop_distance(vcol)
	return tabstop_distance(vcol, self.tabsize)
end

function editor:visual_col(line, col)
	local s = self.lines[line]
	if s then
		return visual_col(s, col, self.tabsize)
	else
		return col --outside eof visual columns and real columns are the same
	end
end

function editor:real_col(line, vcol)
	local s = self.lines[line]
	if s then
		return real_col(s, vcol, self.tabsize)
	else
		return vcol --outside eof visual columns and real columns are the same
	end
end

function editor:max_visual_col()
	local vcol = 0
	for line in ipairs(self.lines) do
		local vcol1 = self:visual_col(line, self:last_col(line))
		if vcol1 > vcol then
			vcol = vcol1
		end
	end
	return vcol
end

function editor:indent_line(line, tabs)
	local s = self.editor.lines[line]
	str.first_indent_ (self.tabsize)
	self.editor:setline(line, s)
end

--selection --------------------------------------------------------------------------------------------------------------

--selecting text between two line,col pairs, in block or line mode.
--line1,col1 is the first selected char and line2,col2 is the char after the last selected char.

local selection = editor.selection

function selection:new(editor)
	self = glue.inherit({editor = editor}, self)
	self:move(1, 1)
	self.editor.selections[self] = true
	return self
end

function selection:free()
	assert(next(next(self.editor.selections))) --at least one selection is needed
	self.editor.selections[self] = nil
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
		--restrict selection to the available editor
		self.line1 = clamp(line1, 1, #self.editor.lines)
		self.line2 = clamp(line2, 1, #self.editor.lines)
		self.col1 = clamp(col1, 1, self.editor:last_col(self.line1) + 1)
		self.col2 = clamp(col2, 1, self.editor:last_col(self.line2) + 1)
	else
		--reset and re-anchor the selection
		self.anchor_line = line
		self.anchor_col = col
		self.line1, self.col1 = line, col
		self.line2, self.col2 = line, col
	end
end

function selection:cols(line)
	local col1, col2
	if self.block then
		col1 = self.editor:real_col(line, self.editor:visual_col(self.line1, self.col1))
		col2 = self.editor:real_col(line, self.editor:visual_col(self.line2, self.col2))
		if col1 > col2 then
			col1, col2 = col2, col1
		end
	else
		col1 = line == self.line1 and self.col1 or 1
		col2 = line == self.line2 and self.col2 or self.editor:last_col(line) + 1
	end
	--restrict selection to the available text
	local last_col = self.editor:last_col(line)
	col1 = clamp(col1, 1, last_col + 1)
	col2 = clamp(col2, 1, last_col + 1)
	return col1, col2
end

function selection:next_line(line)
	line = line and line + 1 or self.line1
	if line > self.line2 then
		return
	end
	return line, self:cols(line)
end

function selection:lines()
	return self.next_line, self
end

function selection:contents()
	local t = {}
	for line, col1, col2 in self:lines() do
		t[#t+1] = str.sub(self.editor.lines[line], col1, col2 - 1)
	end
	return table.concat(t, self.editor.line_terminator)
end

function selection:remove()
	if self:isempty() then return end
	if self.block then
		for line, col1, col2 in self:lines() do
			local s1 = str.sub(self.editor.lines[line], 1, col1 - 1)
			local s2 = str.sub(self.editor.lines[line], col2)
			self.editor:setline(line, s1 .. s2)
		end
	else
		self.editor:remove_string(self.line1, self.col1, self.line2, self.col2)
	end
	self:move(self.line1, self.col1)
end

function selection:indent(tabs)
	for line = self.line1, self.line2 do
		self:indent_line(tabs)
	end
end

--cursor: caret-based navigation and editing -----------------------------------------------------------------------------

local cursor = editor.cursor

function cursor:new(editor)
	self = glue.inherit({
		editor = editor,
		line = 1,
		col = 1, --current real col
		vcol = 1, --wanted visual col, when navigating up/down
	}, self)
	self.editor.cursors[self] = true
	return self
end

function cursor:free()
	assert(next(next(self.editor.cursors))) --at least one cursor is needed
	self.editor.cursors[self] = nil
end

--cursor vocabulary

function cursor:last_col()        return self.editor:last_col(self.line) end
function cursor:getline()         return self.editor.lines[self.line] end
function cursor:setline(s)        self.editor:setline(self.line, s) end
function cursor:insert_line(s)    self.editor:insert_line(self.line, s) end
function cursor:remove_line(line) return self.editor:remove_line(line or self.line) end
function cursor:indent_col()      return str.first_nonspace(self:getline()) end --column where the indented text starts

function cursor:visual_col()
	return self.editor:visual_col(self.line, self.col)
end

function cursor:real_col()
	local col = self.editor:real_col(self.line, self.vcol)
	if self.restrict_eol and self:getline() then
		col = clamp(col, 1, self:last_col() + 1)
	end
	return col
end

function cursor:make_visible()
	self.editor:make_visible(self.line, self:visual_col())
end

--store the current visual column to be restored on key up/down
function cursor:store_vcol()
	self.vcol = self:visual_col()
end

--set real column based on the stored visual column
function cursor:restore_vcol()
	self.col = self:real_col()
end

--navigation

function cursor:move(line, col)
	self.line = line
	self.col = col
	if self.restrict_eof and not self:getline() then
		self.line = clamp(self.line, 1, #self.editor.lines)
	end
	if self.restrict_eol and self:getline() then
		self.col = clamp(self.col, 1, self:last_col() + 1)
	end
	self:store_vcol()
	self:make_visible()
end

function cursor:move_left(cols)
	cols = cols or 1
	self.col = self.col - cols
	if self.col < 1 then
		self.line = self.line - 1
		if self.line == 0 then
			self.line = 1
			self.col = 1
		else
			self.col = self:getline() and self:last_col() + 1 or 1
		end
	end
	self:store_vcol()
	self:make_visible()
end

function cursor:move_right(cols)
	cols = cols or 1
	self.col = self.col + cols
	if self.restrict_eol and self:getline() and (self.col < 1 or self.col > self:last_col() + 1) then
		self.line = self.line + 1
		if self:getline() then
			self.col = 1
		elseif self.restrict_eof then
			self.line = #self.editor.lines
			self.col = self:last_col() + 1
		end
	end
	self:store_vcol()
	self:make_visible()
end

function cursor:move_up(lines)
	lines = lines or 1
	self.line = math.max(0, self.line - lines)
	if self.line == 0 then
		self.line = 1
		if self.restrict_eol then
			self.col = 1
		end
	else
		self:restore_vcol()
	end
	self:make_visible()
end

function cursor:move_down(lines)
	lines = lines or 1
	self.line = self.line + lines
	if self:getline() then
		self:restore_vcol()
	else
		if self.restrict_eof then
			self.line = #self.editor.lines
			self.col = self:last_col() + 1
		end
	end
	self:make_visible()
end

function cursor:move_left_word()
	self:move_left(self.col)
end

function cursor:move_right_word()
	local s = self:getline()
	local i = s:find('', self.col)
	self:move_right()
end

function cursor:move_home()
	self:move(1, 1)
end

function cursor:move_end()
	local line = #self.editor.lines
	self:move(line, self.editor:last_col(line) + 1)
end

--editing

--if cursor is over eof, add empty lines to reach it, and if it's over eol, extend the line to reach it.
function cursor:extend_buffer()
	if not self.restrict_eof then
		while self.line > #self.editor.lines do
			self.editor:insert_line(#self.editor.lines + 1, '')
		end
	end
	if not self.restrict_eol then
		local last_col = self:last_col()
		if self.col > last_col + 1 then
			--self.editor:insert_string(self.line, self:last_col() + 1, string.rep(' ', self.col - last_col - 1))
			self:setline(self:getline() .. string.rep(' ', self.col - last_col - 1))
		end
	end
end

--insert a string at cursor
function cursor:insert_string(s)
	self:extend_buffer()
	self.line, self.col = self.editor:insert_string(self.line, self.col, s)
	self:store_vcol()
	self:make_visible()
end

--pressing enter adds a new line, optionally copies the indent of the current line, and carries the cursor over.
function cursor:newline()
	self:extend_buffer()
	local s = self:getline()
	local landing_col, indent = 1, ''
	if self.auto_indent then
		landing_col = math.min(self.col, self:indent_col())
		indent = str.sub(s, 1, landing_col - 1)
	end
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = indent .. str.sub(s, self.col)
	self:setline(s1)
	self.line = self.line + 1
	self:insert_line(s2)
	self.col = landing_col
	self:store_vcol()
	self:make_visible()
end

--expand a tab character according to current tab mode.
function cursor:expand_tab()
	if false and (self.tab_align_list or self.tab_align_args) then
		--look in the line above for the vcol of the first non-space char after at least one space or '(', starting at vcol
		if str.first_nonspace(s1) < #s1 then
			local vcol = self:visual_col()
			local col1 = self.editor:real_col(self.line-1, vcol)
			local stage = 0
			local s0 = self.editor.lines[self.line-1]
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
				local vcol1 = self.editor:visual_col(self.line-1, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = self.editor:expand_tab()
			end
		end
	elseif self.tabs == 'never' then
		return self.editor:expand_tab()
	elseif self.tabs == 'indent' then
		local s = self:getline()
		local s1 = str.sub(s, 1, self.col - 1)
		if str.first_nonspace(s1) <= #s1 then --we're inside the line
			return self.editor:expand_tab()
		end
	end
	return '\t'
end

--insert tab at cursor
function cursor:insert_tab()
	self:insert_string(self:expand_tab())
end

--insert (or overstrike) a non-control char at cursor
function cursor:insert_char(c)
	assert(#c > 1 or c:byte(1) > 31)
	self:extend_buffer()
	local s = self:getline()
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = str.sub(s, self.col + (self.insert_mode and 0 or 1))
	self:setline(s1 .. c .. s2)
	self:move_right(str.len(c))
end

function cursor:delete_before()
	self:extend_buffer()
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
	self:extend_buffer()
	if self.col > self:last_col() then
		if self.line < #self.editor.lines then
			self:setline(self:getline() .. self:remove_line(self.line + 1))
		end
	else
		local s = self:getline()
		self:setline(str.sub(s, 1, self.col - 1) .. str.sub(s, self.col + 1))
	end
end

--measurements in the unclipped space ------------------------------------------------------------------------------------

local function digits(n) --number of base-10 digits of a number
	return math.floor(math.log10(n) + 1)
end

--width in pixels of the column representing line numbers
function editor:line_numbers_width()
	return self.line_numbers and (digits(#self.lines) + 1) * self.charsize or 0
end

--view dimensions (the view is the unclipped area)
function editor:view_dimensions()
	local maxvcol = self:max_visual_col()
	local maxline = #self.lines

	--unrestricted cursors can enlarge the view area
	for cur in pairs(self.cursors) do
		if not cur.restrict_eol then
			maxvcol = math.max(maxvcol, cur:visual_col())
		end
		if not cur.restrict_eof then
			maxline = math.max(maxline, cur.line)
		end
	end

	local w = self.charsize * maxvcol
	local h = self.linesize * maxline

	--line numbering can enlarge the view area
	w = w + self:line_numbers_width()

	return w, h
end

--cursor space -> view space
function editor:cursor_coords(line, vcol)
	local x = self.charsize * (vcol - 1)
	local y = self.linesize * (line - 1)
	return x, y
end

--view space -> cursor space
function editor:cursor_at(x, y)
	local line = math.floor(y / self.linesize) + 1
	local vcol = math.floor((x + self.charsize / 2) / self.charsize) + 1
	return line, vcol
end

--text space -> view space
function editor:text_coords(line, vcol) --y is at the baseline
	local x = self.charsize * (vcol - 1)
	local y = self.linesize * line - math.floor((self.linesize - self.charvsize) / 2)
	return x, y
end

function editor:caret_rect_insert_mode(cursor)
	local vcol = cursor:visual_col()
	local x, y = self:cursor_coords(cursor.line, vcol)
	local w = cursor.caret_width or self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	return x, y, w, h
end

function editor:caret_rect_over_mode(cursor)
	local vcol = cursor:visual_col()
	local x, y = self:text_coords(cursor.line, vcol)
	local w = 1
	if cursor:getline() and str.istab(cursor:getline(), cursor.col) then --make cursor as wide as the tabspace
		w = self:tabstop_distance(vcol - 1)
	end
	w = w * self.charsize
	local h = self.caret_width
	y = y + 1 --1 pixel under the baseline
	return x, y, w, h
end

function editor:caret_rect(cursor)
	if cursor.insert_mode then
		return self:caret_rect_insert_mode(cursor)
	else
		return self:caret_rect_over_mode(cursor)
	end
end

--selection rectangle for one selection line
function editor:selection_rect(sel, line)
	local col1, col2 = sel:cols(line)
	local vcol1 = self:visual_col(line, col1)
	local vcol2 = self:visual_col(line, col2)
	local x1 = (vcol1 - 1) * self.charsize
	local x2 = (vcol2 - 1) * self.charsize
	if line < sel.line2 then
		x2 = x2 + 0.5 --show eol as half space
	end
	local y1 = (line - 1) * self.linesize
	local y2 = line * self.linesize
	return x1, y1, x2 - x1, y2 - y1
end

--scrolling --------------------------------------------------------------------------------------------------------------

--how many lines are in the clipping rect
function editor:pagesize()
	return math.floor(self.clip_h / self.linesize)
end

--view rect from the pov. of the clip rect
function editor:view_rect()
	return self.scroll_x, self.scroll_y, self:view_dimensions()
end

--clip rect from the pov. of the view rect
function editor:clip_rect()
	return -self.scroll_x, -self.scroll_y, self.clip_w, self.clip_h
end

--scroll the editor to specific pixel coordinates
function editor:scroll(x, y)
	if not self.smooth_vscroll then
		--snap vertical offset to linesize
		local r = y % self.linesize
		y = y - r + self.linesize * (r > self.linesize / 2 and 1 or 0)
	end
	if not self.smooth_hscroll then
		--snap horiz. offset to charsize
		local r = x % self.charsize
		x = x - r + self.charsize * (r > self.charsize / 2 and 1 or 0)
	end
	self.scroll_x = x
	self.scroll_y = y
end

function editor:scroll_by(x, y)
	self:scroll(self.scroll_x + x, self.scroll_y + y)
end

--scroll the editor to make a specific character visible
function editor:make_visible(line, vcol)
	--find the cursor rectangle that needs to be completely in the editor rectangle
	local x, y = self:cursor_coords(line, vcol)
	local w = self.charsize
	local h = self.linesize
	--enlarge the cursor rectangle with margins
	x = x - self.margins.left
	y = y - self.margins.top
	w = w + self.margins.right
	h = h + self.margins.bottom
	--compute the scroll offset (client area coords)
	local scroll_x = -clamp(-self.scroll_x, x + w - self.clip_w, x)
	local scroll_y = -clamp(-self.scroll_y, y + h - self.clip_h, y)
	self:scroll(scroll_x, scroll_y)
end

--which editor lines are (partially or entirely) visibile given the current vertical scroll
function editor:visible_lines()
	local line1 = math.floor(-self.scroll_y / self.linesize) + 1
	local line2 = math.ceil((-self.scroll_y + self.clip_h) / self.linesize)
	line1 = clamp(line1, 1, #self.lines)
	line2 = clamp(line2, 1, #self.lines)
	return line1, line2
end

--which visual columns are (partially or entirely) visibile given the current horizontal scroll
function editor:visible_cols()
	local vcol1 = math.floor(-self.scroll_x / self.charsize) + 1
	local vcol2 = math.ceil((-self.scroll_x + self.clip_w) / self.charsize)
	return vcol1, vcol2
end

--rendering --------------------------------------------------------------------------------------------------------------

function editor:draw_char(x, y, s, i, color) end --stub
function editor:draw_rect(x, y, w, h, color) end --stub
function editor:draw_scrollbox() end --stub; returns scroll_x, scroll_y, clip_w, clip_h

function editor:draw_background()
	local color = self.background_color or 'background'
	local x, y, w, h = self:clip_rect()
	self:draw_rect(x, y, w, h, color)
end

function editor:draw_text(line, vcol, s, color, i, j)
	i = i or 1
	j = j or #s
	local x, y = self:text_coords(line, vcol)
	for i = i, j do
		self:draw_char(x, y, s, i, color)
		x = x + self.charsize
	end
end

function editor:draw_line_numbers_background()
	local color = self.line_numbers_background_color or 'line_number_background'
	local x, y, w, h = self:clip_rect()
	w = self:line_numbers_width()
	x = x - w
	self:draw_rect(x, y, w, h, color)
end

function editor:draw_line_numbers()
	local minline, maxline = self:visible_lines()
	for line = minline, maxline do
		local s = tostring(line)
		self:draw_text(line, -#s, s, 'line_number')
	end
end

function editor:draw_buffer(line1, vcol1, line2, vcol2, color)

	--clamp the text rectangle to the visible rectangle
	local minline, maxline = self:visible_lines()
	local minvcol, maxvcol = self:visible_cols()
	line1 = clamp(line1, minline, maxline+1)
	line2 = clamp(line2, minline-1, maxline)
	vcol1 = clamp(vcol1, minvcol, maxvcol+1)
	vcol2 = clamp(vcol2, minvcol-1, maxvcol)
	if vcol1 > vcol2 then
		return
	end

	for line = line1, line2 do
		local s = self.lines[line]
		local vcol = 1
		for i in str.indices(s) do
			if str.istab(s, i) then
				vcol = vcol + self:tabstop_distance(vcol - 1)
			else
				if vcol > vcol2 then
					break
				elseif vcol >= vcol1 then
					local x, y = self:text_coords(line, vcol)
					self:draw_char(x, y, s, i, color)
				end
				vcol = vcol + 1
			end
		end
	end
end

function editor:draw_visible_text()
	local color = self.text_color or 'text'
	self:draw_buffer(1, 1, 1/0, 1/0, color)
end

function editor:draw_selection_background(sel)
	if sel:isempty() then return end
	local color = sel.color or self.selection_color or 'selection_background'
	for line = sel.line1, sel.line2 do
		local x, y, w, h = self:selection_rect(sel, line)
		self:draw_rect(x, y, w, h, color)
	end
end

function editor:draw_selection_text(sel)
	if sel:isempty() then return end
	for line, col1, col2 in sel:lines() do
		local vcol1 = self:visual_col(line, col1)
		local vcol2 = self:visual_col(line, col2-1)
		self:draw_buffer(line, vcol1, line, vcol2, 'selection_text')
	end
end

function editor:draw_cursor(cursor)
	local x, y, w, h = self:caret_rect(cursor)
	local color = cursor.color or self.cursor_color or 'cursor'
	self:draw_rect(x, y, w, h, color)
end

function editor:render()
	self.scroll_x, self.scroll_y, self.clip_x, self.clip_y, self.clip_w, self.clip_h = self:draw_scrollbox()
	--self:scroll_by(0, 0)
	self:draw_background()
	self:draw_line_numbers_background()
	self:draw_line_numbers()
	self:draw_visible_text()
	for sel in pairs(self.selections) do
		self:draw_selection_background(sel)
		self:draw_selection_text(sel)
	end
	for cur in pairs(self.cursors) do
		self:draw_cursor(cur)
	end
end

--controller -------------------------------------------------------------------------------------------------------------

--saving API
function editor:save_file(s) end --stub

--clipboard API
local clipboard_contents = '' --global clipboard over all editor instances on the same Lua state

function editor:set_clipboard(s)
	clipboard_contents = s
end

function editor:get_clipboard()
	return clipboard_contents
end

--UI API
function editor:setactive(active) end --stub
function editor:focused() end --stub
function editor:focus() end --stub

--key commands -----------------------------------------------------------------------------------------------------------

local commands = editor.commands

function commands:line_up()
	self:scroll_by(0, self.linesize)
end

function commands:line_down()
	self:scroll_by(0, -self.linesize)
end

function commands:move_left()    self.cursor:move_left();  self.selection:move(self.cursor.line, self.cursor.col) end
function commands:move_right()   self.cursor:move_right(); self.selection:move(self.cursor.line, self.cursor.col) end
function commands:move_up()      self.cursor:move_up();    self.selection:move(self.cursor.line, self.cursor.col) end
function commands:move_down()    self.cursor:move_down();  self.selection:move(self.cursor.line, self.cursor.col) end

function commands:select_left()  self.cursor:move_left();  self.selection:move(self.cursor.line, self.cursor.col, true) end
function commands:select_right() self.cursor:move_right(); self.selection:move(self.cursor.line, self.cursor.col, true) end
function commands:select_up()    self.cursor:move_up();    self.selection:move(self.cursor.line, self.cursor.col, true) end
function commands:select_down()  self.cursor:move_down();  self.selection:move(self.cursor.line, self.cursor.col, true) end

function commands:move_home()    self.cursor:move_home() end
function commands:move_end()     self.cursor:move_end() end

function commands:move_bol()
	self.cursor:move(self.cursor.line, 1)
end

function commands:move_eol()
	if not self.cursor:getline() then return end
	self.cursor:move(self.cursor.line, self.cursor:last_col() + 1)
end

function commands:page_up()
	self:scroll_by(0, self:pagesize() * self.linesize)
	self.cursor:move_up(self:pagesize())
end

function commands:page_down()
	self:scroll_by(0, -self:pagesize() * self.linesize)
	self.cursor:move_down(self:pagesize())
end

function commands:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
end

function commands:delete_before_cursor()
	self.cursor:delete_before()
end

function commands:delete_after_cursor()
	if self.selection:isempty() then
		self.cursor:delete_after()
	else
		self.selection:remove()
	end
end

function commands:newline()
	self.cursor:newline()
end

function commands:select_all()
	self.selection:move(1, 1)
	self.selection:move(1/0, 1/0, true)
	self.cursor:move_end()
end

function commands:indent()
	if not self.selection:isempty() then
		self.selection:indent(1)
		self.cursor:move(self.selection.line2 + 1, 1)
	else
		self.cursor:insert_tab()
	end
end

function commands:outdent()
	if not self.selection:isempty() then
		self.selection:indent(-1)
		self.cursor:move(self.selection.line2 + 1, 1)
	else
		--TODO: outdent line
	end
end

function commands:cut()
	local s = self.selection:contents()
	self:set_clipboard(s)
	self.selection:remove()
end

function commands:copy()
	self:set_clipboard(self.selection:contents())
end

function commands:paste()
	local s = self:get_clipboard()
	self.selection:remove()
	self.cursor:insert_string(s)
end

function commands:save()
	self:save_file(self:contents())
end

--input ------------------------------------------------------------------------------------------------------------------

function editor:key_pressed(focused, key, char, ctrl, shift, alt)
	if not focused then return end
	local is_input_char = char and not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
	if is_input_char then
		self.cursor:insert_char(char)
	elseif key then
		--TODO: avoid string creation on key press (is it worth it? for PCs it ain't)
		local shortcut = (ctrl and 'ctrl+' or '') .. (alt and 'alt+' or '') .. (shift and 'shift+' or '') .. key
		local command = self.commands[self.key_bindings[shortcut]]
		if command then
			command(self)
		end
	end
end

function editor:mouse_input(active, mousex, mousey, lbutton, rbutton, wheel)
	if not active and lbutton
		and mousex >= -self.scroll_x
		and mousex <= -self.scroll_x + self.clip_w
		and mousey >= -self.scroll_y
		and mousey <= -self.scroll_y + self.clip_h
	then
		self:setactive(true)
		self.cursor.line, self.cursor.vcol = self:cursor_at(mousex, mousey)
		self.cursor:restore_vcol()
		self.selection:move(self.cursor.line, self.cursor.col)
	elseif active then
		if lbutton then
			local line, vcol = self:cursor_at(mousex, mousey)
			local col = self:real_col(self.cursor:getline(), vcol)
			self.selection:move(line, col, true)
			self.cursor.line = line
			self.cursor.col = col
		else
			self:setactive(false)
		end
	end
end


if not ... then require'codedit_demo' end

return editor

