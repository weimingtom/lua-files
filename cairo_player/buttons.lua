local player = require'cairo_player'

local kappa = 4 / 3 * (math.sqrt(2) - 1)

local function button_path(cr, x1, y1, w, h, cut)
	local rx, ry = 5, 5
	rx = math.min(math.abs(rx), math.abs(w/2))
	ry = math.min(math.abs(ry), math.abs(h/2))
	if rx == 0 and ry == 0 then
		rect_to_lines(write, x1, y1, w, h)
		return
	end
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	if cut == 'right' or cut == 'both' then
		cr:move_to(x2, y1)
		cr:line_to(x2, y2)
		cr:line_to(cut == 'right' and x1+rx or x1, y2)
	else
		cr:move_to(cx, y1)
		cr:curve_to(cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
		cr:line_to(x2, y2-ry)
		cx, cy = x2-rx, y2-ry
		cr:curve_to(cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
		cr:line_to(cut and x1 or x1+rx, y2)
	end
	if cut == 'left' or cut == 'both' then
		cr:line_to(x1, y1)
	else
		cx, cy = x1+rx, y2-ry
		cr:curve_to(cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
		cr:line_to(x1, y1+ry)
		cx, cy = x1+rx, y1+ry
		cr:curve_to(cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
		cr:line_to(cx, y1)
	end
	cr:close_path()
end

function player:button(t)
	local id, x, y, w, h, text, cut, selected = t.id, t.x, t.y, t.w, t.h or 24, t.text, t.cut, t.selected
	x = x or self.cpx
	y = y or self.cpy
	local font_size = t.font_size or h / 2

	local down = self.lbutton
	local hot = self:hot(x, y, w, h)

	local clicked = false
	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if hot then
			clicked = not down
			selected = clicked
		end
		if not down then
			self.active = nil
		end
	end

	local color_state = (selected or self.active == id and hot and down) and 'selected'
						or ((not self.active or self.active == id) and hot and 'hot') or 'normal'
	local bg_color = color_state..'_bg'
	local fg_color = color_state..'_fg'

	--drawing
	local cr = self.cr

	button_path(cr, x, y, w, h, cut)

	self:setcolor(bg_color)
	cr:fill_preserve()

	self:setcolor'normal_border'
	cr:set_line_width(self.theme.border_width)
	cr:stroke()

	cr:set_font_size(font_size)
	self:aligntext(text, x, y, w, h, 'center', 'middle')
	self:setcolor(fg_color)
	cr:show_text(text)

	self:advance(x, y, w, h)
	return clicked
end

function player:mbutton(t)
	local id, x, y, w, h, buttons, selected = t.id, t.x, t.y, t.w, t.h, t.buttons, t.selected

	local bwidth = w/#buttons
	for i=1,#buttons do
		local cut = #buttons > 1 and (i==#buttons and 'left' or i==1 and 'right' or 'both')
		if self:button{id = id..'_'..i, x = x, y = y, w = bwidth, h = h, text = buttons[i],
							cut = cut, selected = selected == i}
		then
			selected = i
		end
		x = x + bwidth
	end
	return selected
end

function player:tabs(t)
	local id, x, y, w, h, buttons, selected = t.id, t.x, t.y, t.w, t.h, t.buttons, t.selected

	local bwidth = w/#buttons
	for i=1,#buttons do
		if self:button{id = id..'_'..i, x = x, y = y, w = bwidth, h = h, text = buttons[i],
							cut = 'both', selected = selected == i}
		then
			selected = i
		end
		x = x + bwidth
	end
	return selected
end

if not ... then require'cairo_player_ui_demo' end

