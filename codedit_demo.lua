local lines = require'codedit_lines'
local move = require'codedit_move'

local ce = require'codedit'
local player = require'cairo_player'
local glue = require'glue'

local text = [[
function lines.pos(s, lnum)
	if lnum < 1 then return end
	local n = 0
	for _, i, j in lines.lines(s) do
		n = n + 1
		if n == lnum then return i, j end
	end
end
]]

local ed = ce.editor:new(text)
local vwer = ce.viewer:new(300, 50, 800, 400, hliter)
local car = ce.caret:new(ed)

local tabsize

function player:on_render(cr)

	--[[
	local i, j, n = lines.pos(ed.s, car.lnum)
	local vcnum = lines.view_cnum(ed.s, car.lnum, car.cnum, car.tabsize)
	self:label{x = 10, y = 10, text = string.format('lnum: %d, cnum: %d | line: %d, size: %d | vcnum: %d',
																	car.lnum, car.cnum, n, j - i + 2, vcnum)}
	]]

	car.tabsize = self:slider{id = 'tabsize', x = 10, y = 40, w = 90, h = 24, i0 = 1, i1 = 8, i = car.tabsize}
	car.restrict_right = self:togglebutton{id = 'restrict_right', x = 10, y = 70, w = 90, h = 24, selected = car.restrict_right}
	car.restrict_down = self:togglebutton{id = 'restrict_down', x = 10, y = 100, w = 90, h = 24, selected = car.restrict_down}
	vwer.linesize = self:slider{id = 'linesize', x = 10, y = 130, w = 90, h = 24, i0 = 10, i1 = 30, i = vwer.linesize}
	vwer.tabsize = car.tabsize

	car.gettime = function() return self.clock end

	if self.key == 'left' then
		car:move_left()
	elseif self.key == 'right' then
		car:move_right()
	elseif self.key == 'up' then
		car:move_up()
	elseif self.key == 'down' then
		car:move_down()
	elseif self.key == 'insert' then
		car.insert_mode = not car.insert_mode
	end

	vwer:render_text(cr, ed.s)
	vwer:render_caret(cr, car, ed)

end

player:play()

