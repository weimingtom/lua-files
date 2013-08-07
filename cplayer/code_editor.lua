--code editor based on codedit.
local codedit = require'codedit'
local glue = require'glue'

local view = {
	font_face = 'Fixedsys',
	linesize = 16,
	charsize = 8,
	charvsize = 10,
	caret_width = 2,
	eol_markers = true,
}

local function new(self, t)
	self = glue.inherit(t, self)
	self.buffer = self.buffer or codedit.buffer:new()
	self.cursor = self.cursor or cursor:new{buffer = self.buffer, view = self.view}
	self.selection = selection:new{buffer = self.buffer}
	self:update(t)
	return self
end

function view:render_scrollbox(player, id, buffer)
	local maxlen = self:max_visual_col(buffer.lines)
	local cw = self.charsize * maxlen
	local ch = self.linesize * #buffer.lines
	player:scrollbox{id = id,
							x = self.x, y = self.y, w = self.w, h = self.h,
							cx = self.cx, cy = self.cy, cw = cw, ch = ch,
							vscroll = self.vscroll,
							hscroll = self.hscroll,
							vscroll_w = self.vscroll_w,
							hscroll_h = self.hscroll_h,
							page_size = self.scroll_page_size}
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
			ds = ds .. str.sub(s, col, col)
		end
	end
	return ds
end

function view:render_buffer(player, buffer, x, y, w, h)

	self:scroll(cx, cy)

	local cr = player.cr

	cr:select_font_face(self.font_face, 0, 0)
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

	return self.cx, self.cy
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
	if y + w > self.clipbox[2] + self.clipbox[4] then
		self:scroll(self.cx, self.clipbox[2] - y + self.linesize)
	end
end

function view:render_selection(sel, player)
	local cr = player.cr
	if sel:isempty() then return end
	cr:new_path()
	for line = sel.line1, sel.line2 do
		cr:rectangle(self.view:selection_rect(sel, line)
	end
	cr:set_source_rgba(1, 1, 1, 0.4)
	cr:fill()
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
		self.cursor:move_left()
		self.selection:move(self.cursor.line, self.cursor.col, shift)
		self:_helpmove(ctrl, shift, player)
	elseif key == 'right' then
		self.cursor:move_right()
		self.selection:move(self.cursor.line, self.cursor.col, shift)
		self:_helpmove(ctrl, shift, player)
	elseif key == 'up' then
		self.cursor:move_up()
		self.selection:move(self.cursor.line, self.cursor.col, shift)
	elseif key == 'down' then
		self.cursor:move_down()
		self.view:scroll_into_view(self.cursor)
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
	self.view:render_buffer(self.buffer, player, self.id .. '_scrollbox')
	self.view:render_cursor(self.cursor, player)

end

function player:code_editor(t)
	return new(self, t)
end

if not ... then assert(loadfile('../cairo_player_demo.lua'))() end

