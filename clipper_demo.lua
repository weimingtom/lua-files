local player = require'cairo_player'
local clipper = require'clipper'
local ffi = require'ffi'
local cairo = require'cairo'

local i = 0

function player:on_render(cr)
	i = i + 1
	math.randomseed(math.floor(i / 100))

	local even_odd = i % 100 > 50

	cr:set_fill_rule(even_odd and
		cairo.C.CAIRO_FILL_RULE_EVEN_ODD or
		cairo.C.CAIRO_FILL_RULE_WINDING)
	cr:set_line_width(1)

	cr:set_source_rgba(0, 0, 0, 1)
	cr:paint()

	local scale = 1000000

	local function draw_poly(i, p, fr,fg,fb,fa, sr,sg,sb,sa)
		if p:size() == 0 then return end
		cr:new_path()
		cr:move_to(p:get(1).x / scale, p:get(1).y / scale)
		for i=2,p:size() do
			cr:line_to(p:get(i).x / scale, p:get(i).y / scale)
		end
		cr:close_path()
		if fr then
			fr, fg, fb, fa = fr or 1, fg or 1, fb or 1, fa or 1
			cr:set_source_rgba(fr, fg, fb, fa)
			cr:fill_preserve()
		end
		if sr then
			sr, sg, sb, sa = sr or 1, sg or 1, sb or 1, sa or 1
			cr:set_source_rgba(sr, sg, sb, sa)
			cr:stroke()
		end
	end

	local function draw_polys(p, ...)
		for i=1,p:size() do
			draw_poly(i, p:get(i), ...)
		end
	end

	local function random_polys(n)
		n = math.floor(n / 2)
		--you can preallocate elements...
		local p = clipper.polygon(n)
		for i=1,n do
			p:get(i).x = math.random(100, 1000) * scale
			p:get(i).y = math.random(100, 600) * scale
		end
		--or you can add elements one by one...
		for i=1,n do
			p:add(math.random(100, 1000) * scale, math.random(100, 600) * scale)
		end

		p = clipper.polygons(p)
		--p = p:clean() --TODO: this crashes with clipper 5.1.5
		p = p:simplify(even_odd and 'even_odd' or 'non_zero')
		return p
	end

	local p1 = random_polys(10)
	draw_polys(p1, 0.7, 0.7, 1, 0.2, 0.7, 0.7, 1, 0.5)

	local p2 = random_polys(10)
	draw_polys(p2, 0.7, 1, 0.7, 0.2, 0.7, 1, 0.7, 0.5)

	local cl = clipper.new()
	cl:add_subject(p1)
	cl:add_clip(p2)
	local p3 = cl:execute'intersection'
	draw_polys(p3, 0, 1, 0, 0.5, 0, 1, 0, 1)
	draw_polys(p3:offset(5 * scale, 'round'), 0, 1, 0, 0, 0, 1, 0, 1)
	draw_polys(p3:offset(-5 * scale, 'round'), 0, 1, 0, 0, 0, 1, 0, 1)
end

player:play()

