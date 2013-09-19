--codedit rendering
local editor = require'codedit_editor'
local str = require'codedit_str'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

editor.lexer = nil --lexer to use for syntax highlighting. nil means no highlighting.

function editor:draw_char(x, y, s, i, color) end --stub
function editor:draw_rect(x, y, w, h, color) end --stub
function editor:draw_scrollbox() end --stub; returns scroll_x, scroll_y, clip_w, clip_h

function editor:draw_text(x, y, s, color, i, j)
	i = i or 1
	j = j or #s
	for i = i, j do
		self:draw_char(x, y, s, i, color)
		x = x + self.charsize
	end
end

function editor:draw_background()
	local color = self.background_color or 'background'
	local x, y, w, h = self:clip_rect()
	self:draw_rect(x, y, w, h, color)
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
		local s = self:getline(line)
		local vcol = 1
		for i in str.byte_indices(s) do
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


lexer = require'lexers.lexer'
_LEXER = nil
lexer.load'lexers.cpp'

function editor:next_pos(line, line_i, next_i)
	while true do
		local next_line_i = line_i + #self:getline(line) + #self.line_terminator
		if next_i < next_line_i then
			break
		end
		line_i = next_line_i
		line = line + 1
	end
	local col = next_i == line_i and 1 or str.char_index(self:getline(line), next_i - line_i + 1)
	return line, col, line_i, next_i
end

function editor:highlight()
	local minline, maxline = self:visible_lines()

	if self.dirty then
		self.text = self:contents()
		self.lex_result = lexer.lex(self.text, 'cpp')
		--self.dirty = false
	end

	local line_i, i, ci = 1, 1, 1
	local line, col = 1, 1

	local t = self.lex_result
	for ti = 1, #t, 2 do
		local color, next_i = t[ti], t[ti+1]

		local _line, _col, _line_i, _i = self:next_pos(line, line_i, next_i)

		if line >= minline and line <= maxline then
			if not str.isascii(self.text, i, '\n') and not str.isspace(self.text, i) then
				local vcol = self:visual_col(line, col)

				local x, y = self:text_coords(line, vcol)
				self:draw_text(x, y, self:getline(line), color, i - line_i + 1, next_i - line_i)

				--[[
				for line = line + 1, _line do
					self:draw_text(line, 1, self:getline(line), color, i - line_i + 1, next_i - line_i)
				end
				]]
			end
		end

		line, col, line_i, i = _line, _col, _line_i, _i
	end
end


function editor:draw_buffer_highlighted()

	local minline, maxline = self:visible_lines()

	if self.dirty then
		self.text = self:contents()
		self.lex_result = lexer.lex(self.text, 'cpp')
		--self.dirty = false
	end

	local line_i, i, ci = 1, 1, 1
	local line, col = 1, 1

	local t = self.lex_result
	for ti = 1, #t, 2 do
		local color, next_i = t[ti], t[ti+1]

		local _line, _col, _line_i, _i = self:next_pos(line, line_i, next_i)

		if line >= minline and line <= maxline then
			if not str.isascii(self.text, i, '\n') and not str.isspace(self.text, i) then
				local vcol = self:visual_col(line, col)

				local x, y = self:text_coords(line, vcol)
				self:draw_text(x, y, self:getline(line), color, i - line_i + 1, next_i - line_i)

				--[[
				for line = line + 1, _line do
					self:draw_text(line, 1, self:getline(line), color, i - line_i + 1, next_i - line_i)
				end
				]]
			end
		end

		line, col, line_i, i = _line, _col, _line_i, _i
	end
end

function editor:draw_visible_text()
	if self.lexer then
		self:draw_buffer_highlighted()
	else
		local color = self.text_color or 'text'
		self:draw_buffer(1, 1, 1/0, 1/0, color)
	end
end

function editor:draw_selection_background(sel)
	if not sel.visible then return end
	if sel:isempty() then return end
	local color = sel.color or self.selection_color or 'selection_background'
	for line = sel.line1, sel.line2 do
		local x, y, w, h = self:selection_rect(sel, line)
		self:draw_rect(x, y, w, h, color)
	end
end

function editor:draw_selection_text(sel)
	if not sel.visible then return end
	if sel:isempty() then return end
	for line, col1, col2 in sel:lines() do
		local vcol1 = self:visual_col(line, col1)
		local vcol2 = self:visual_col(line, col2) - 1
		self:draw_buffer(line, vcol1, line, vcol2, 'selection_text')
	end
end

function editor:draw_cursor(cursor)
	if not cursor.visible then return end
	local x, y, w, h = self:caret_rect(cursor)
	local color = cursor.color or self.cursor_color or 'cursor'
	self:draw_rect(x, y, w, h, color)
end

function editor:draw_margin(margin)
	margin:draw()
end

function editor:render()
	self.scroll_x, self.scroll_y, self.clip_x, self.clip_y, self.clip_w, self.clip_h = self:draw_scrollbox()
	self:draw_background()
	for i,m in ipairs(self.margins) do
		self:draw_margin(m)
	end
	self:draw_visible_text()
	for sel in pairs(self.selections) do
		self:draw_selection_background(sel)
		self:draw_selection_text(sel)
	end
	for cur in pairs(self.cursors) do
		self:draw_cursor(cur)
	end
end

