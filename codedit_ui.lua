--controller -------------------------------------------------------------------------------------------------------------
local editor = require'codedit_editor'

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


--input ------------------------------------------------------------------------------------------------------------------

function editor:input(focused, active, key, char, ctrl, shift, alt, mousex, mousey, lbutton, rbutton, wheel_delta)

	local hot =
	       mousex >= -self.scroll_x
		and mousex <= -self.scroll_x + self.clip_w
		and mousey >= -self.scroll_y
		and mousey <= -self.scroll_y + self.clip_h

	if hot then
		self.player.cursor = 'text'
	end

	if focused then

		local is_input_char = char and not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
		if is_input_char then
			self.cursor:insert_char(char)
		elseif key then
			local shortcut = (ctrl and 'ctrl+' or '') .. (alt and 'alt+' or '') .. (shift and 'shift+' or '') .. key
			local binding = self.key_bindings[shortcut]
			if type(binding) == 'table' then
				local command = self.commands[binding[1]]
				command(self, unpack(binding, 2))
			elseif binding then
				self.commands[binding](self)
			end
		end

	end

	if not active and lbutton and hot then
		self:setactive(true)
		self.cursor.line, self.cursor.vcol = self:cell_at(mousex, mousey)
		self.cursor.col = self.cursor:real_col()
		self.cursor.selection:reset(self.cursor.line, self.cursor.col)
		self:setactive(true)
	elseif active == self.id then
		if lbutton then
			local line, vcol = self:cell_at(mousex, mousey)
			local col = self:real_col(self.cursor.line, vcol)
			self.cursor:move(line, col, true, true, key and alt or (not key and self.cursor.selection.block))
		else
			self:setactive(false)
		end
	end

end

