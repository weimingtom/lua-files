local player = require'cairo_player'
local clipper = require'clipper'
local ffi = require'ffi'

local i = 0
function player:on_render(cr)
	i = i + 1
	cr:set_source_rgba(0, 0, 0, 1)
	cr:paint()

	local function draw_poly(p,r,g,b,a)
		local data = p:points()
		cr:new_path()
		cr:move_to(data[0].x, data[0].y)
		for i=1,p:size()-1 do
			cr:line_to(data[i].x, data[i].y)
		end
		cr:close_path()
		cr:set_source_rgba(r or 1,g or 1,b or 1,a or 1)
	end

	local p1 = clipper.polygon(3)
	local data = p1:points()
	data[0].x = 0
	data[0].y = 0
	data[1].x = 100
	data[1].y = 0
	data[2].x = 100 + i
	data[2].y = 100 + i
	p1 = p1:simplify()
	if p1:size() > 0 then
		draw_poly(p1:polygons(), 1, 0, 1)
		cr:fill()
	end

	local p2 = clipper.polygon(3)
	local data = p2:points()
	data[0].x = 100 + i
	data[0].y = 0 + i
	data[1].x = 100
	data[1].y = 100
	data[2].x = 0
	data[2].y = 100
	p2 = p2:simplify()
	if p2:size() > 0 then
		draw_poly(p2:polygons(), 1, 1, 0)
		cr:fill()
	end

	local cl = clipper.new()
	cl:add_subject(p1)
	cl:add_clip(p2)
	local p3 = cl:execute('intersection')
	if p3:size() > 0 then
		draw_poly(p3:polygons(), 1, 0, 0)
	end
	cr:fill()
end

player:play()

