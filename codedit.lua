--modular code editor with many features.

local glue = require'glue'
local str = require'codedit_str'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

--buffer object: holds the lines in a list, for displaying, changing and saving

local buffer = {
	eol_spaces = 'remove', --'leave', 'remove'.
	eof_lines = 'leave', --'leave', 'remove', 'always'.
	line_terminator = nil, --line terminator to use for loading and saving. nil means autodetect.
	tabs = 'leave', --'leave', 'never', 'indent', 'always' to use for saving. nil means autodetect.
	tabsize = nil, --number to use for saving. nil means autodetect.
}

function buffer:new(t)
	self = glue.inherit(t or {}, self)
	self:load('')
	return self
end

function buffer:load(s)
	self.line_terminator = self.line_terminator or self:detect_line_terminator(s)

	self.lines = {}
	for s in glue.gsplit(s, self.line_terminator) do
		self.lines[#self.lines + 1] = s
	end

	self.changed = false
	setmetatable(self.lines, {__newindex = function(t, k, v)
		rawset(t, k, v)
		self.changed = true
	end})

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

--TODO: detect 'never', 'indent', 'always' tabs modes.
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
		table.insert(self.lines, '')
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
	assert(t.buffer, 'buffer missing')
	assert(t.view, 'view missing')
	self = glue.inherit(t, self)
	self.line = 1
	self.col = 1 --real columnself.
	self.vcol = 1 --unrestricted visual column
	return self
end

function cursor:last_col()
	return str.len(self.buffer.lines[self.line])
end

function cursor:getline()
	return self.buffer.lines[self.line]
end

function cursor:setline(s)
	self.buffer.lines[self.line] = s
end

function cursor:insert_line(s)
	table.insert(self.buffer.lines, self.line, s)
end

function cursor:remove_line(line)
	return table.remove(self.buffer.lines, line or self.line)
end

function cursor:indent_col() --return the column where the indented text starts
	return str.first_nonspace(self:getline())
end

--store the current visual column to be restored on key up/down
function cursor:store_vcol()
	local s = self:getline()
	if s then
		self.vcol = self.view:visual_col(s, self.col)
	else
		self.vcol = self.col --outside eof visual columns and real columns are the same
	end
end

--set real column based on the stored visual column
function cursor:restore_vcol()
	local s = self:getline()
	if s then
		self.col = self.view:real_col(s, self.vcol)
		if self.restrict_eol then
			self.col = clamp(self.col, 1, self:last_col() + 1)
		end
	else
		self.col = self.vcol --outside eof visual columns and real columns are the same
	end
end

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
			local vcol = self.view:visual_col(self:getline(), self.col)
			local s0 = self.buffer.lines[self.line-1]
			local col1 = self.view:real_col(s0, vcol)
			local stage = 0
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
				local vcol1 = self.view:visual_col(s0, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = str.replace(c, '\t', string.rep(' ', self.view.tabsize))
			end
		end
	elseif self.tabs == 'never' then
		c = str.replace(c, '\t', string.rep(' ', self.view.tabsize))
	elseif self.tabs == 'indent' then
		if str.first_nonspace(s1) <= #s1 then
			c = str.replace(c, '\t', string.rep(' ', self.view.tabsize))
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

--tabview: view base class that translates between visual columns and real columns.
--real columns map 1:1 to char indices, while visual columns represent screen columns after tab expansion.

local tabview = {
	tabsize = 3,
}

function tabview:new(t)
	return glue.inherit(t, self)
end

--how many spaces from a visual column to the next tabstop, for a specific tabsize.
function tabview:tabstop_distance(vcol)
	return math.floor((vcol + self.tabsize) / self.tabsize) * self.tabsize - vcol
end

--visual column coresponding to a real column for a specific tabsize.
--the real column can be past string's end, in which case vcol will expand to the same amount.
function tabview:visual_col(s, col)
	local col1 = 0
	local vcol = 1
	for i in str.indices(s) do
		col1 = col1 + 1
		if col1 >= col then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and self:tabstop_distance(vcol - 1) or 1)
	end
	vcol = vcol + col - col1 - 1 --extend vcol past eol
	return vcol
end

--real column corresponding to a visual column for a specific tabsize.
--if the target vcol is between two possible vcols, return the vcol that is closer.
function tabview:real_col(s, vcol)
	local vcol1 = 1
	local col = 0
	for i in str.indices(s) do
		col = col + 1
		local vcol2 = vcol1 + (str.istab(s, i) and self:tabstop_distance(vcol1 - 1) or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			return col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
		end
		vcol1 = vcol2
	end
	col = col + vcol - vcol1 + 1 --extend col past eol
	return col
end

--find the maximum visual line length of a buffer
function tabview:max_visual_col(lines)
	local maxlen = 0
	for i,line in ipairs(lines) do
		local len = self:visual_col(line, str.len(line))
		if len > maxlen then
			maxlen = len
		end
	end
	return maxlen
end

--view: displaying the text and the cursor

local view = glue.update({
	font_face = 'Fixedsys',
	linesize = 16,
	charsize = 8,
	charvsize = 10,
	caret_width = 2,
	eol_markers = true,
	smooth_vscroll = false,
	smooth_hscroll = true,
}, tabview)

function view:new(t)
	assert(t.x, 'x missing')
	assert(t.y, 'y missing')
	assert(t.w, 'w missing')
	assert(t.h, 'h missing')
	return glue.inherit(t, self)
end

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

function view:expand_tabs(s)
	local ts = self.tabsize
	local ds = ''
	local col = 0
	for i in str.indices(s) do
		col = col + 1
		if str.istab(s, i) then
			ds = ds .. (' '):rep(self:tabstop_distance(#ds))
		else
			ds = ds .. s:sub(col, col) --str.sub(s, col, col)
		end
	end
	return ds
end

function view:render_scrollbox(buffer, player, editor)
	local maxlen = self:max_visual_col(buffer.lines)

	local cw = self.charsize * maxlen
	local ch = self.linesize * #buffer.lines

	local cx, cy, x, y, w, h = player:scrollbox{id = editor.id .. '_scrollbox',
																x = self.x, y = self.y, w = self.w, h = self.h,
																cx = self.cx, cy = self.cy, cw = cw, ch = ch}

	self.clipbox = {x, y, w, h}
	self:scroll(cx, cy)
end

function view:render_buffer(buffer, player)
	local cr = player.cr

	cr:save()

	cr:select_font_face(self.font_face, 0, 0)

	cr:rectangle(unpack(self.clipbox))
	cr:clip()
	cr:set_source_rgba(1, 1, 1, 0.02)
	cr:paint()

	local first_visible_line = math.floor(-self.cy / self.linesize) + 1
	local last_visible_line = math.ceil((-self.cy + self.h) / self.linesize) - 1

	local x = self.cx + self.x
	local y = self.cy + self.y + first_visible_line * self.linesize - math.floor((self.linesize - self.charvsize) / 2)

	for i = first_visible_line, last_visible_line do

		local s = self:expand_tabs(buffer.lines[i])

		if self.eol_markers then
			--s = s .. string.char(0xE2, 0x81, 0x8B) --REVERSE PILCROW SIGN
		end

		cr:move_to(x, y)
		cr:set_source_rgba(1, 1, 1, 1)
		cr:show_text(s)

		if self.eol_markers then
			--draw a reverse pilcrow at eol
			local x = x + str.len(s) * self.charsize + 2.5
			local yspacing = math.floor(self.linesize - self.charvsize) / 2 + 0.5
			local y = y - self.linesize + yspacing
			cr:move_to(x, y);     cr:rel_line_to(0, self.linesize - 0.5)
			cr:move_to(x + 3, y); cr:rel_line_to(0, self.linesize - 0.5)
			cr:set_source_rgba(1, 1, 1, 0.4)
			cr:move_to(x - 2.5, y)
			cr:line_to(x + 3.5, y)
			cr:stroke()
			cr:arc(x + 2.5, y + 3.5, 4, - math.pi / 2 + 0.2, - 3 * math.pi / 2 - 0.2)
			cr:close_path()
			cr:fill()
		end

		y = y + self.linesize
	end

	cr:restore()
end

function view:cursor_coords(cursor)
	local s = cursor:getline()
	local vcol = s and self:visual_col(s, cursor.col) or cursor.col
	local x = (vcol - 1) * self.charsize
	local y = (cursor.line - 1) * self.linesize
	return x, y, vcol
end

function view:insert_caret_rect(cursor)
	local x, y, vcol = self:cursor_coords(cursor)
	local w = self.caret_width
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	return x, y, w, h
end

function view:over_caret_rect(cursor)
	local x, y, vcol = self:cursor_coords(cursor)
	local w = self.charsize *
		(str.istab(cursor:getline(), cursor.col) and self:tabstop_distance(vcol - 1) or 1)
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
	col = clamp(col, 1, str.len(s) + 1.5)
	local vcol = self:visual_col(s, col)
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
		cr:rectangle(self.x + self.cx + x1, self.y + self.cy + y1, x2 - x1, y2 - y1)
	end

	cr:set_source_rgba(1, 1, 1, 0.4)
	cr:fill()
end

function view:cursor_at(x, y)
	local line = math.floor((y - self.y - self.cy) / self.linesize) + 1
	local vcol = math.floor((x - self.x - self.cx + self.charsize / 2) / self.charsize) + 1
	return line, vcol
end

--editor: ties a buffer, cursor, selection and view together. processes input and provides rendering.

local editor = {}

function editor:new(t)
	assert(t.id, 'id missing')
	assert(t.buffer, 'buffer missing')
	assert(t.view, 'view missing')
	self = glue.inherit(t, self)
	self.cursor = cursor:new{buffer = self.buffer, view = self.view}
	self.selection = selection:new{buffer = self.buffer}
	return self
end

function editor:_helpmove(ctrl, shift, player)
	if player:keypressed'up' then
		self.cursor:move_up(1, shift)
	elseif player:keypressed'down' then
		self.cursor:move_down(1, shift)
	end
end

function editor:save(s) end --stub

function editor:render(player)

	local key, char, ctrl, shift, lbutton, mousex, mousey =
		player.key, player.char, player.ctrl, player.shift, player.lbutton, player.mousex, player.mousey

	if ctrl and key == 'up' then
		self.view:scroll(self.view.cx, self.view.cy + self.view.linesize)
	elseif ctrl and key == 'down' then
		self.view:scroll(self.view.cx, self.view.cy - self.view.linesize)
	elseif key == 'left' then
		self.cursor:move_left(1, shift)
		self.selection:move(self.cursor.line, self.cursor.col, shift)
		self:_helpmove(ctrl, shift, player)
	elseif key == 'right' then
		self.cursor:move_right(1, shift)
		self.selection:move(self.cursor.line, self.cursor.col, shift)
		self:_helpmove(ctrl, shift, player)
	elseif key == 'up' then
		self.cursor:move_up(1, shift)
		self.selection:move(self.cursor.line, self.cursor.col, shift)
	elseif key == 'down' then
		self.cursor:move_down(1, shift)
		self.selection:move(self.cursor.line, self.cursor.col, shift)
	elseif ctrl and key == 'A' then
		self.selection:move(1, 1)
		self.selection:move(1/0, 1/0, true)
	elseif key == 'insert' then
		self.cursor.insert_mode = not self.cursor.insert_mode
	elseif key == 'backspace' then
		self.cursor:delete_before()
	elseif key == 'delete' then
		self.cursor:delete_after()
	elseif key == 'return' then
		self.cursor:newline()
	elseif key == 'esc' then
		--ignore
	elseif ctrl and key == 'S' then
		self:save(buffer:save())
	elseif char and not ctrl then
		self.cursor:insert(char)
	end

	self.view:render_scrollbox(self.buffer, player, self)

	if not player.active and lbutton and player:hotbox(unpack(self.view.clipbox)) then
		player.active = self.id
		self.cursor.line, self.cursor.vcol = self.view:cursor_at(mousex, mousey)
		self.cursor:restore_vcol()
		self.selection:move(self.cursor.line, self.cursor.col)
	elseif player.active == self.id then
		if lbutton then
			local line, vcol = self.view:cursor_at(mousex, mousey)
			local col = self.view:real_col(self.cursor:getline(), vcol)
			self.selection:move(line, col, true)
			self.cursor.line = line
			self.cursor.col = col
		else
			player.active = nil
		end
	end

	self.view:render_selection(self.selection, player)
	self.view:render_buffer(self.buffer, player)
	self.view:render_cursor(self.cursor, player)

end

if not ... then require'codedit_demo' end

return {
	str = str,
	buffer = buffer,
	selection = selection,
	cursor = cursor,
	view = view,
	editor = editor,
}

