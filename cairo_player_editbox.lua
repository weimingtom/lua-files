--TODO: assumes char size = 1 byte; make it work with arbitrary utf-8 strings
local player = require'cairo_player'
local ffi = require'ffi'

local function find_caret_pos(cr, text, target_x)
	local extents = ffi.new'cairo_text_extents_t'
	local last_x = 0
	for i=1,#text do
		local x = cr:text_extents(text:sub(1, i) .. '\0', extents).width
		if target_x >= last_x and target_x <= x then
			return i - (target_x - last_x < x - target_x and 1 or 0)
		end
		last_x = x
	end
	return #text
end

function player:editbox(t)
	local id, x, y, w, h, text = t.id, t.x, t.y, t.w, t.h or 24, t.text
	local caret_w = t.caret_w or 2
	local font_size = t.font_size or h * .7
	local down = self.lbutton
	local cr = self.cr

	local hot = self:hot(x, y, w, h)

	cr:set_font_size(font_size)

	local text_x = 0
	local caret_pos
	if (not self.active and ((hot and down) or not self.activate or self.activate == id)) then
		self.active = id
		self.focus_tab = nil
		self.text_x = 0
		caret_pos = find_caret_pos(cr, text, self.mousex - x)
	elseif self.active == id then
		if down and not hot then
			self.active = nil
			self.text_x = nil
			self.caret_pos = nil
		elseif self.key == 'tab' then
			self.activate = self.shift and t.prev_tab or t.next_tab
			self.active = nil
			self.text_x = nil
			self.caret_pos = nil
		else
			text_x = self.text_x
			caret_pos = self.caret_pos
		end
	end

	if hot and down and self.active == id then
		caret_pos = find_caret_pos(cr, text, self.mousex - x - text_x)
	end

	local min_view = 4
	local caret_x
	if caret_pos then
		if self.key == 'left' then
			if self.ctrl then
				local pos = text:sub(1, math.max(0, caret_pos - 1)):find('%s[^%s]*$') or 0
				caret_pos = math.max(0, pos)
			else
				caret_pos = math.max(0, caret_pos - 1)
			end
		elseif self.key == 'right' then
			if self.ctrl then
				local pos = text:find('%s', caret_pos + 1) or #text
				caret_pos = math.min(#text, pos)
			else
				caret_pos = math.min(#text, caret_pos + 1)
			end
		elseif self.key == 'backspace' then
			text = text:sub(1, math.max(0, caret_pos - 1)) .. text:sub(caret_pos + 1)
			caret_pos = math.max(0, caret_pos - 1)
		elseif self.key == 'delete' then
			text = text:sub(1, caret_pos) .. text:sub(caret_pos + 2)
		elseif self.char and string.byte(self.char) >= 32 then
			text = text:sub(1, caret_pos) .. self.char .. text:sub(caret_pos + 1)
			caret_pos = math.min(#text, caret_pos + 1)
		end

		local text_w = cr:text_extents(text).x_advance
		caret_x = cr:text_extents(text:sub(1, caret_pos) .. '\0').x_advance
		text_x = math.min(text_x, -(caret_x + caret_w - w))
		text_x = math.max(text_x, -caret_x)

		self.text_x = text_x
		self.caret_pos = caret_pos
	end

	--drawing

	cr:save()

	cr:rectangle(x, y, w, h)
	self:setcolor'faint_bg'
	cr:fill_preserve()
	cr:clip()

	cr:move_to(x + text_x, y + h * .8)
	self:setcolor'normal_fg'
	cr:show_text(text)

	if caret_x then
		self:setcolor'normal_fg'
		cr:rectangle(x + text_x + caret_x, y, caret_w, h)
		cr:fill()
	end

	cr:restore()

	return text
end

if not ... then require'cairo_player_ui_demo' end

