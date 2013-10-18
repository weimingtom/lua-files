--controller -------------------------------------------------------------------------------------------------------------
local editor = require'codedit_editor'

--UI API
function editor:setactive(active) end --stub
function editor:focused() end --stub
function editor:focus() end --stub


--input ------------------------------------------------------------------------------------------------------------------

function editor:input(focused, active, key, char, ctrl, shift, alt,
								mousex, mousey, lbutton, rbutton, wheel_delta,
								doubleclicked, tripleclicked, quadrupleclicked, waiting_for_triple_click)

	if not self.view.clip_x then return end --editor has not been rendered yet, input cannot work

	local hot = self.view:client_hit_test(mousex, mousey)

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

	if doubleclicked and hot then
		self:select_word_at_cursor()
		self.word_selected = true
	else
		if tripleclicked and hot then
			self:select_line_at_cursor()
		elseif not active and lbutton and hot and not waiting_for_triple_click then
			self:move_cursor_to_coords(mousex, mousey)
			self:setactive(true)
		elseif active == self.id then
			if lbutton then
				local mode = alt and 'select_block' or 'select'
				self:move_cursor_to_coords(mousex, mousey, mode)
			else
				self:setactive(false)
			end
		end
		self.word_selected = false
	end

end


if not ... then require'codedit_demo' end
