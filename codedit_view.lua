--codedit view object: measuring and rendering of buffer, selection and cursor objects.
--implementation for monospace fonts and fixed line height.
local glue = require'glue'
local str = require'codedit_str'

local view = {
	--tab expansion
	tabsize = 3,
	--font metrics
	line_h = 16,
	char_w = 8,
	char_baseline = 14,
	--cursor metrics
	cursor_xoffset = -1,     --cursor x offset from a char's left corner
	cursor_xoffset_col1 = 0, --cursor x offset for the first column
	cursor_thickness = 2,
	--scrolling
	cursor_margins = {top = 16, left = 0, right = 0, bottom = 16},
	--rendering
	background_color = 'background',
	text_color = 'text', --text color in absence of syntax highlighting
	margin_background_color = 'margin_background',
	selection_background_color = 'selection_background',
	selection_text_color = 'selection_text',
	cursor_color = 'cursor',
	line_number_text_color = 'line_number_text',
	line_number_highlight_background_color = 'line_number_highlight_background',
	lexer = nil, --lexer to use for syntax highlighting. nil means no highlighting.
	--reflowing
	line_width = 72,
}

--lifetime

function view:new(buffer)
	self = glue.inherit({
		buffer = buffer,
	}, self)
	--objects to render
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}
	self.margins = {} --{margin1, ...}
	--state
	self.scroll_x = 0
	self.scroll_y = 0
	self.changed = {}
	return self
end

--adding objects to render

function view:add_selection(sel) self.selections[sel] = true end
function view:add_cursor(cur) self.cursors[cur] = true end
function view:add_margin(margin, pos)
	table.insert(self.margins, pos or #self.margins + 1, margin)
end

--memento

function view:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
end

local function update_state(dst, src)
	dst.scroll_x = src.scroll_x
	dst.scroll_y = src.scroll_y
end

function view:save_state(state)
	update_state(state, self)
end

function view:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--utils

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

function view:point_in_rect(x, y, x1, y1, w1, h1)
	return x >= x1 and x <= x1 + w1 and y >= y1 and y <= y1 + h1
end

--basic measurements in client space

--char space -> pixel space
function view:char_coords(line, vcol)
	local x = self.char_w * (vcol - 1)
	local y = self.line_h * (line - 1)
	return x, y
end

--char baseline space -> pixel space
function view:text_coords(line, vcol) --y is at the baseline
	local x, y = self:char_coords(line, vcol)
	return x, y + self.char_baseline
end

--pixel space -> char space
function view:char_at(x, y)
	local line = math.floor(y / self.line_h) + 1
	local vcol = math.floor((x + self.char_w / 2) / self.char_w) + 1
	return line, vcol
end

--selection space -> pixel space
function view:char_rect(line1, vcol1, line2, vcol2)
	local x1, y1 = self:char_coords(line1, vcol1)
	local x2, y2 = self:char_coords(line2 + 1, vcol2)
	return x1, y1, x2 - x1, y2 - y1
end

--selection measurements (in client space)

function view:selection_line_rect(sel, line)
	if not sel.visible then return end
	if sel:isempty() then return end
	local col1, col2 = sel:cols(line)
	local vcol1 = self.buffer:visual_col(line, col1)
	local vcol2 = self.buffer:visual_col(line, col2) - 1
	local x, y, w, h = self:char_rect(line, vcol1, line, vcol2)
	if not sel.block and line < sel.line2 then
		w = w + 0.5 * self.char_w --show eol as half space
	end
	return x, y, w, h
end

--cursor measurements (in client space)

function view:cursor_rect_insert_mode(cursor)
	local vcol = self.buffer:visual_col(cursor.line, cursor.col)
	local x, y = self:char_coords(cursor.line, vcol)
	local w = cursor.thickness or self.cursor_thickness
	local h = self.line_h
	x = x + (vcol == 1 and self.cursor_xoffset_col1 or self.cursor_xoffset)
	return x, y, w, h
end

function view:cursor_rect_over_mode(cursor)
	local vcol = self.buffer:visual_col(cursor.line, cursor.col)
	local x, y = self:text_coords(cursor.line, vcol)
	local w = self.buffer:istab(cursor.line, cursor.col) and self.buffer:tab_width(vcol) or 1
	w = w * self.char_w
	local h = cursor.thickness or self.cursor_thickness
	y = y + 1 --1 pixel under the baseline
	return x, y, w, h
end

function view:cursor_rect(cursor)
	if cursor.insert_mode then
		return self:cursor_rect_insert_mode(cursor)
	else
		return self:cursor_rect_over_mode(cursor)
	end
end

--scrolling (the relationship between client rectangle and clipping rectangle)

--how many lines are in the clipping rect
function view:pagesize()
	return math.floor(self.clip_h / self.line_h)
end

function view:scroll_by(x, y)
	self.scroll_x = self.scroll_x + x
	self.scroll_y = self.scroll_y + y
end

function view:scroll_up()
	self:scroll_by(0, self.line_h)
end

function view:scroll_down()
	self:scroll_by(0, -self.line_h)
end

--scroll to make a specific rectangle visible
function view:make_rect_visible(x, y, w, h)
	self.scroll_x = -clamp(-self.scroll_x, x + w - self.clip_w, x)
	self.scroll_y = -clamp(-self.scroll_y, y + h - self.clip_h, y)
end

--scroll to make the char under cursor visible
function view:make_cursor_visible(cur)
	local line, vcol = cur.line, self.buffer:visual_col(cur.line, cur.col)
	local x, y, w, h = self:char_rect(line, vcol, line, vcol + 1)
	--enlarge the char rectangle with the cursor margins
	x = x - self.cursor_margins.left
	y = y - self.cursor_margins.top
	w = w + self.cursor_margins.right  + self.cursor_margins.left
	h = h + self.cursor_margins.bottom + self.cursor_margins.top
	self:make_rect_visible(x, y, w, h)
end

--which lines are partially or entirely visibile
function view:visible_lines()
	local line1 = math.floor(-self.scroll_y / self.line_h) + 1
	local line2 = math.ceil((-self.scroll_y + self.clip_h) / self.line_h)
	line1 = clamp(line1, 1, self.buffer:last_line())
	line2 = clamp(line2, 1, self.buffer:last_line())
	return line1, line2
end

--which visual columns are partially or entirely visibile
function view:visible_cols()
	local vcol1 = math.floor(-self.scroll_x / self.char_w) + 1
	local vcol2 = math.ceil((-self.scroll_x + self.clip_w) / self.char_w)
	return vcol1, vcol2
end

--layout measurements

function view:client_size()
	local maxvcol = self.buffer:max_visual_col() + 1
	local maxline = self.buffer:last_line()
	--unrestricted cursors can enlarge the client area
	for cur in pairs(self.cursors) do
		maxline = math.max(maxline, cur.line)
		if not cur.restrict_eol then
			maxvcol = math.max(maxvcol, self.buffer:visual_col(cur.line, cur.col))
		end
	end
	return self:char_coords(maxline + 1, maxvcol + 1)
end

function view:margins_width()
	local w = 0
	for _,m in ipairs(self.margins) do
		w = w + m:get_width()
	end
	return w
end

--rendering

function view:draw_char(x, y, s, i, color) end --stub
function view:draw_rect(x, y, w, h, color) end --stub

function view:draw_text(x, y, s, color, i, j)
	i = i or 1
	j = j or str.len(s)
	for i = i, j do
		self:draw_char(x, y, s, i, color)
		x = x + self.char_w
	end
end

function view:draw_buffer(cx, cy, line1, vcol1, line2, vcol2, color)

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
		local s = self.buffer:getline(line)
		local vcol = 1
		for i in str.byte_indices(s) do
			if str.istab(s, i) then
				vcol = vcol + self.buffer:tab_width(vcol)
			else
				if vcol > vcol2 then
					break
				elseif vcol >= vcol1 then
					local x, y = self:text_coords(line, vcol)
					self:draw_char(cx + x, cy + y, s, i, color)
				end
				vcol = vcol + 1
			end
		end
	end
end


lexer = require'lexers.lexer'
_LEXER = nil
lexer.load'lexers.cpp'

function view:next_pos(line, line_i, next_i)
	while true do
		local next_line_i = line_i + #self.buffer:getline(line) + #self.buffer.line_terminator
		if next_i < next_line_i then
			break
		end
		line_i = next_line_i
		line = line + 1
	end
	local col = next_i == line_i and 1 or str.char_index(self.buffer:getline(line), next_i - line_i + 1)
	return line, col, line_i, next_i
end

function view:draw_buffer_highlighted(cx, cy)

	local minline, maxline = self:visible_lines()

	if self.buffer.changed.highlighting ~= false then
		self.text = self.buffer:contents()
		self.lex_result = lexer.lex(self.text, 'cpp')
		self.buffer.changed.highlighting = false
	end

	local line_i, i, ci = 1, 1, 1
	local line, col = 1, 1

	local t = self.lex_result
	for ti = 1, #t, 2 do
		local color, next_i = t[ti], t[ti+1]

		local _line, _col, _line_i, _i = self:next_pos(line, line_i, next_i)

		if line >= minline and line <= maxline then
			if not str.isascii(self.text, i, '\n') and not str.isspace(self.text, i) then
				local vcol = self.buffer:visual_col(line, col)

				local x, y = self:text_coords(line, vcol)
				self:draw_text(x, y, self.buffer:getline(line), color, i - line_i + 1, next_i - line_i)

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

function view:draw_visible_text(cx, cy)
	if self.lexer then
		self:draw_buffer_highlighted(cx, cy)
	else
		local color = self.buffer.text_color or self.text_color
		self:draw_buffer(cx, cy, 1, 1, 1/0, 1/0, color)
	end
end

function view:draw_selection(sel, cx, cy)
	if not sel.visible then return end
	if sel:isempty() then return end
	local bg_color = sel.background_color or self.selection_background_color
	local text_color = sel.text_color or self.selection_text_color
	for line, col1, col2 in sel:lines() do
		local vcol1 = self.buffer:visual_col(line, col1)
		local vcol2 = self.buffer:visual_col(line, col2) - 1
		local x, y, w, h = self:char_rect(line, vcol1, line, vcol2)
		if not sel.block and line < sel.line2 then
			w = w + 0.5 * self.char_w --show eol as half space
		end
		self:draw_rect(cx + x, cy + y, w, h, bg_color)
		self:draw_buffer(cx, cy, line, vcol1, line, vcol2, text_color)
	end
end

function view:draw_cursor(cursor, cx, cy)
	if not cursor.visible then return end
	local x, y, w, h = self:cursor_rect(cursor)
	local color = cursor.color or self.cursor_color
	self:draw_rect(cx + x, cy + y, w, h, color)
end

function view:draw_margin_line(margin, line, cx, cy, cw, ch)
	margin:draw_line(line, cx, cy, cw, ch)
end

function view:draw_margin(margin, cx, cy, cw, ch, clip_x, clip_y, clip_w, clip_h)
	self:clip(clip_x, clip_y, clip_w, clip_h)
	--background
	local color = margin.background_color or self.margin_background_color
	self:draw_rect(clip_x, clip_y, clip_w, clip_h, color)
	--contents
	local minline, maxline = self:visible_lines()
	for line = minline, maxline do
		local x, y = self:char_coords(line, 1)
		self:draw_margin_line(margin, line, cx + x, cy + y, cw, ch)
		y = y + self.line_h
	end
end

function view:draw_client(cx, cy, cw, ch, clip_x, clip_y, clip_w, clip_h)
	self:clip(clip_x, clip_y, clip_w, clip_h)
	--background
	local color = self.buffer.background_color or self.background_color
	self:draw_rect(clip_x, clip_y, clip_w, clip_h, color)
	--text, selections, cursors
	self:draw_visible_text(cx, cy)
	for sel in pairs(self.selections) do
		self:draw_selection(sel, cx, cy)
	end
	for cur in pairs(self.cursors) do
		self:draw_cursor(cur, cx, cy)
	end
end

--draw a scrollbar control of (x, y, w, h) outside rect and (cx, cy, cw, ch) client rect,
--where cx, cy is relative to the outside rect and return the new cx, cy, adjusted by user input
--and other scrollbox constraints, and the clipping rect of the scrollbox, relative to the client rect.
--this stub implementation is equivalent to a scrollbox that can take no user input, has no margins,
--and has invisible scrollbars.
function view:draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	return cx, cy, x, y, w, h
end

function view:clip(x, y, w, h) end --stub

--[[
...................................
:client |m1 |m2 |                 :  view rect (*):  x, y, w, h
:rect   |   |   |                 :  scrollbox rect: x + margins_w, y, w - margins_w, h -> clip_x, clip_y, clip_w, clip_h
:       |___|___|_____________    :  clip rect:      clip_x, clip_y, clip_w, clip_h
:       |*  |   |clip       ||    :  client rect:    clip_x + scroll_x, clip_y + scroll_y, client_size()
:       |   |   |rect       ||    :  m1 rect:        x, client_y, m1:get_width(), client_h
:       |   |   |           |O    :  m1 clip rect:   m1_x, clip_y, m1_w, clip_h
:       |   |   |           |O    :
:       |   |   |           |O    :
:       |   |   |           |O    :
:       |   |   |           ||    :
:       |___|___|___________||    :
:       |   |   |------0OO--+*    :
:       |   |   |                 :
:       |   |   |                 :
...................................
]]
function view:render()

	local client_w, client_h = self:client_size()
	local margins_w = self:margins_width()

	local clip_x, clip_y
	self.scroll_x, self.scroll_y, clip_x, clip_y, self.clip_w, self.clip_h =
		self:draw_scrollbox(
			self.x + margins_w,
			self.y,
			self.w - margins_w,
			self.h,
			self.scroll_x, self.scroll_y, client_w, client_h)

	local client_x, client_y = clip_x + self.scroll_x, clip_y + self.scroll_y

	local margin_x = self.x
	for i,margin in ipairs(self.margins) do
		local margin_y = client_y
		local margin_w = margin:get_width()
		local margin_h = client_h

		local mclip_x = margin_x
		local mclip_y = clip_y
		local mclip_w = margin_w
		local mclip_h = self.clip_h

		self:draw_margin(margin, margin_x, margin_y, margin_w, margin_h, mclip_x, mclip_y, mclip_w, mclip_h)

		margin_x = margin_x + margin_w
	end

	self:draw_client(client_x, client_y, client_w, client_h, clip_x, clip_y, self.clip_w, self.clip_h)
end




if not ... then require'codedit_demo' end

return view
