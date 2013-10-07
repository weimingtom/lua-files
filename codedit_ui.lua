--controller -------------------------------------------------------------------------------------------------------------
local editor = require'codedit_editor'

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

	if hot and not self.selection:hit_test(mousex, mousey) then
		self.player.cursor = 'text'
	end

	if focused then

		local is_input_char = char and not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
		if is_input_char then
			self:insert_char(char)
		elseif key then
			local shortcut = (ctrl and 'ctrl+' or '') .. (alt and 'alt+' or '') .. (shift and 'shift+' or '') .. key
			self:perform_shortcut(shortcut)
		end

	end

	if not active and lbutton and hot then
		self:move_cursor_to_coords(mousex, mousey)
		self:setactive(true)
	elseif active == self.id then
		if lbutton then
			local mode = key and (alt and 'select_block' or 'select') or self.selection.block and 'select_block' or 'select'
			self:move_cursor_to_coords(mousex, mousey, mode)
		else
			self:setactive(false)
		end
	end

end


if not ... then require'codedit_demo' end
