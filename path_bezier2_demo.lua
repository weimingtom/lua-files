local player = require'cairo_player'
local bezier2 = require'path_bezier2'

local b1 = {50, 200, 200, 50, 300, 200}
local b2 = {50, 300, 500, 400, 4000050, 300}
local b3 = {4000050, 500, 500, 400, 50, 500}

function player:on_render(cr)

	local function interpolate(x1, y1, x2, y2, x3, y3, ...)
		--stroke segments
		cr:move_to(x1, y1)
		bezier2.interpolate(function(s, x, y) cr:line_to(x, y) end, x1, y1, x2, y2, x3, y3)
		self:stroke(...)
		--segment endpoints
		self:dot(x1, y1, 2)
		bezier2.interpolate(function(s, x, y) self:dot(x, y, 2) end, x1, y1, x2, y2, x3, y3)
	end

	local function draw(id, b)
		--draw draggable control points
		self:dragpoints{id = id, points = b}

		--draw faint lines from endpoints to control point
		self:line(b[1], b[2], b[3], b[4], 'faint_bg')
		self:line(b[5], b[6], b[3], b[4], 'faint_bg')

		--draw with cairo first to see if there's any difference
		local x1, y1, x2, y2, x3, y3, x4, y4 = bezier2.to_bezier3(unpack(b))
		self:curve(x1, y1, x2, y2, x3, y3, x4, y4, 'error_bg')

		--bounding box
		local x, y, w, h = bezier2.bounding_box(unpack(b))
		self:rect(x, y, w, h, 'faint_bg')

		--hit -> draw hit point
		local d,x,y,t = bezier2.hit(self.mousex, self.mousey, unpack(b))
		self:dot(x, y, 4, '#00ff00')

		--split -> draw pieces with different colors
		local
			ax1, ay1, ax2, ay2, ax3, ay3,
			bx1, by1, bx2, by2, bx3, by3 = bezier2.split(t, unpack(b))
		interpolate(ax1, ay1, ax2, ay2, ax3, ay3, '#ffff00')
		interpolate(bx1, by1, bx2, by2, bx3, by3, '#ff00ff')

		--t and length
		self:label{x = x, y = y+10, text = string.format('t: %4.2f, len: %4.2f', t, bezier2.length(t, unpack(b)))}
	end

	--draw curves
	draw('b1', b1)
	draw('b2', b2)
	draw('b3', b3)
end

player:play()
