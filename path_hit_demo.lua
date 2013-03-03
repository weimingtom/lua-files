local player = require'cairopanel_player'
local glue = require'glue'
local point = require'path_point'
local line = require'path_line'
local arc = require'path_arc'
local bezier2 = require'path_bezier2'
local bezier3 = require'path_bezier3'
local svgarc = require'path_svgarc'
local path_simplify = require'path_simplify'

local function path_draw(cr)
	local function write(s,...)
		if s == 'move' then cr:move_to(...)
		elseif s == 'line' then cr:line_to(...)
		elseif s == 'curve' then cr:curve_to(...)
		elseif s == 'close' then cr:close_path()
		elseif s == 'text' then
			local font,s = ...
			cr:select_font_face(font.family or 'Arial', 0, 0)
			cr:set_font_size(font.size or 12)
			cr:text_path(s)
		end
	end

	local function hex_color(s)
		local r,g,b = tonumber(s:sub(2,3), 16), tonumber(s:sub(4,5), 16), tonumber(s:sub(6,7), 16)
		return r/255, g/255, b/255
	end

	local function draw(path,stroke_color,fill_color)
		cr:new_path()
		path_simplify(write,path)
		if fill_color then
			cr:set_source_rgb(hex_color(fill_color))
			cr:fill_preserve()
		end
		if stroke_color ~= false then
			cr:set_source_rgb(hex_color(stroke_color or '#ffffff'))
			cr:stroke()
		end
	end

	return draw
end

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:set_line_width(1)
	local draw = path_draw(cr)

	local x0,y0 = self.mouse_x or 0/0,self.mouse_y or 0/0

	local dists = {}

	local function addhit(d,x,y,t)
		if not d then return end
		glue.append(dists,d,x,y,t)
	end

	local function point_hit(x1,y1)
		local d2 = point.distance2(x0,y0,x1,y1)
		addhit(d2,x1,y1,0)
	end

	local function line_hit(x1,y1,x2,y2)
		x2,y2=x1+x2,y1+y2
		point_hit(x1,y1); point_hit(x2,y2)
		draw{'move',x1,y1,'line',x2,y2}
		addhit(line.hit(x0,y0,x1,y1,x2,y2))
	end

	local function arc_hit(cx,cy,r,a1,a2)
		local x1,y1,x2,y2 = arc.endpoints(cx,cy,r,math.rad(a1),math.rad(a2))
		point_hit(x1,y1); point_hit(x2,y2)
		draw{'arc',cx,cy,r,a1,a2}
		addhit(arc.hit(x0,y0,cx,cy,r,math.rad(a1),math.rad(a2)))
	end

	local function bezier2_hit(x1,y1,x2,y2,x3,y3)
		x2,y2,x3,y3=x1+x2,y1+y2,x1+x3,y1+y3
		point_hit(x1,y1); point_hit(x3,y3)
		draw{'move',x1,y1,'quad_curve',x2,y2,x3,y3}
		addhit(bezier2.hit(x0,y0,x1,y1,x2,y2,x3,y3))
	end

	local function bezier3_hit(x1,y1,x2,y2,x3,y3,x4,y4)
		x2,y2,x3,y3,x4,y4=x1+x2,y1+y2,x1+x3,y1+y3,x1+x4,y1+y4
		point_hit(x1,y1); point_hit(x4,y4)
		draw{'move',x1,y1,'curve',x2,y2,x3,y3,x4,y4}
		addhit(bezier3.hit(x0,y0,x1,y1,x2,y2,x3,y3,x4,y4))
	end

	line_hit(100, 100, 50, 100)
	line_hit(300, 100, -100, 0)
	line_hit(400, 200, 0, -100)

	arc_hit(100, 300, 50, 0, 90)
	arc_hit(300, 300, 50, -270, 270)
	arc_hit(500, 300, 50, 270, -270)
	arc_hit(700, 300, 50, 0, 360 + 90)

	bezier2_hit(500, 500, 50, 100, 100, 0)
	bezier3_hit(100, 500, 100, 100, 200, -100, 300, 0)

	local mind = 1/0
	local x1,y1,t1
	for i=1,#dists,4 do
		local d,x,y,t = unpack(dists,i,i+3)
		if d < mind then
			mind = d
			x1,y1,t1=x,y,t
		end
	end
	if x1 then
		draw({'move',x0,y0,'line',x1,y1,'circle',x1,y1,3},'#ff0000')
		draw({'move',50,50,'text',{family='Arial',size=24},string.format('t: %.2f', t1)},false,'#ffffff')
	end
end

player:play()

