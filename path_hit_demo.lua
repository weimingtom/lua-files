local player = require'cairopanel_player'
local glue = require'glue'
local distance2 = require'path_point'.distance2
local line = require'path_line'
local arc = require'path_arc'
local bezier2 = require'path_bezier2'
local bezier3 = require'path_bezier3'
local svgarc = require'path_svgarc'
local path_simplify = require'path_simplify'
bezier3.hit = require'path_bezier3_hit'
bezier2.hit = require'path_bezier2_hit'
local cairo = require'cairo'

print(bezier3.split(.1, 0, 0, -500, 0, 1500, 0, 1000, 0))
print(bezier3.length(1, bezier3.split(.1, 0, 0, -500, -10, 1500, -10, 1000, 0)))

--print(bezier3.length(1, bezier3.split(.8, 100, 600, -500, 10, 1500, 10, 1000, 0)))
--print(bezier3.length(1, select(7, bezier3.split(.8, 100, 600, -500, 10, 1500, 10, 1000, 0))))


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
			cr:set_fill_rule(cairo.CAIRO_FILL_RULE_EVEN_ODD)
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

	local x0 = self.mouse_x or self.window.client_w/2
	local y0 = self.mouse_y or self.window.client_h/2

	local dists = {}
	local lens = {}

	local function line_hit(x1,y1,x2,y2)
		x2,y2=x1+x2,y1+y2
		draw({'rect',line.bounding_box(x1,y1,x2,y2)},'#666666')
		draw{'move',x1,y1,'line',x2,y2}
		local d,x,y,t = line.hit(x0,y0,x1,y1,x2,y2)
		glue.append(dists,d,x,y,t,line.point(t,x1,y1,x2,y2))
		lens[#dists] = line.length(t,x1,y1,x2,y2)
	end

	local function arc_hit(cx,cy,r,a1,a2)
		a1,a2=math.rad(a1),math.rad(a2)
		local x1,y1,x2,y2 = arc.endpoints(cx,cy,r,a1,a2)
		draw({'rect',arc.bounding_box(cx,cy,r,a1,a2)},'#666666')
		draw{'arc',cx,cy,r,math.deg(a1),math.deg(a2)}
		local d,x,y,t = arc.hit(x0,y0,cx,cy,r,a1,a2)
		glue.append(dists,d,x,y,t,arc.point(t,cx,cy,r,a1,a2))
		lens[#dists] = arc.length(t, cx,cy,r,a1,a2)
	end

	local function write(s,x2,y2)
		draw{'circle',x2,y2,1}
	end

	local function bezier2_hit(x1,y1,x2,y2,x3,y3)
		x2,y2,x3,y3=x1+x2,y1+y2,x1+x3,y1+y3
		draw({'rect',bezier2.bounding_box(x1,y1,x2,y2,x3,y3)},'#666666')
		draw{'move',x1,y1,'quad_curve',x2,y2,x3,y3}
		local d,x,y,t = bezier2.hit(x0,y0,x1,y1,x2,y2,x3,y3)
		glue.append(dists,d,x,y,t,bezier2.point(t,x1,y1,x2,y2,x3,y3))
		lens[#dists] = bezier2.length(t,x1,y1,x2,y2,x3,y3)
	end

	local function bezier3_hit(x1,y1,x2,y2,x3,y3,x4,y4)
		x2,y2,x3,y3,x4,y4=x1+x2,y1+y2,x1+x3,y1+y3,x1+x4,y1+y4
		draw({'rect',bezier3.bounding_box(x1,y1,x2,y2,x3,y3,x4,y4)},'#666666')
		draw{'move',x1,y1,'curve',x2,y2,x3,y3,x4,y4}
		local d,x,y,t = bezier3.hit(x0,y0,x1,y1,x2,y2,x3,y3,x4,y4)
		glue.append(dists,d,x,y,t,bezier3.point(t,x1,y1,x2,y2,x3,y3,x4,y4))
		lens[#dists] = bezier3.length(t,x1,y1,x2,y2,x3,y3,x4,y4)
	end

	line_hit(100, 100, 50, 100)
	line_hit(200, 200, -50, -100)
	line_hit(350, 100, -100, 0)
	line_hit(250, 150, 100, 0)
	line_hit(400, 200, 0, -100)
	line_hit(450, 100, 0, 100)
	line_hit(600, 100, -100, 50)
	line_hit(500, 200, 100, -50)

	arc_hit(100, 300, 50, 0, 90)
	arc_hit(300, 300, 50, -270, 180+45)
	arc_hit(500, 300, 50, 270, -270)
	arc_hit(700, 300, 50, 0, 360 + 90)
	arc_hit(900, 300, 50, 0, -360)

	bezier2_hit(100, 400, 50, 100, 1000, 0) --wide assymetric
	bezier2_hit(100, 500, 2000, 0, 0, 5) --very close sides
	bezier2_hit(100, 550, 0, 0, 1000, 0) --handles on endpoints

	bezier3_hit(100, 600, -500, 10, 1500, 10, 1000, 0) --very close sides
	bezier3_hit(100, 700, 500, -100, 500, -100, 1000, 0) --elevated quad curve

	bezier3_hit(700, 100, 400, 100, -200, 100, 200, 0) --loop
	bezier3_hit(1000, 100, 200, 100, 0, 100, 200, 0) --cusp
	bezier3_hit(1100, 200, -300, 100, 300, 100, 0, 0) --bowl

	local mind = 1/0
	local x1,y1,t1,len
	for i=1,#dists,6 do
		local d,x,y,t,x2,y2 = unpack(dists,i,i+5)
		draw({'circle',x2,y2,5},false,'#3333ff')
		draw({'circle',x,y,7,'circle',x,y,9},false,'#ff0000')
		if d < mind then
			mind = d
			x1,y1,t1,len=x,y,t,lens[i+5]
		end
	end
	if x1 then
		draw({'move',x0,y0,'line',x1,y1},'#ff0000')
		draw({'circle',x1,y1,5},false,'#00ff00')
		draw({'move',x0+20,y0+24,'text',{family='Arial',size=14},string.format('t: %.2f', t1)},false,'#ffffff')
		draw({'move',x0+20,y0+38,'text',{family='Arial',size=14},string.format('length: %.2f', len)},false,'#ffffff')
	end
end

player:play()

