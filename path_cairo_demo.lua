local path = require'path'
local draw_function = require'path_cairo'
local player = require'cairo_player'

local i=0
function player:on_render(cr)
	i=i+1
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local draw = draw_function(cr)
	local mt --= require'affine2d'():translate(100, 200):scale(.5, .5):rotate_around(500, 300, 10+i/10)

	local p = {
		'move', 900, 10,
		--lines and control commands
		'rel_line', 20, 100,
		'rel_hline', 100,
		'rel_vline', -100,
		'close',
		'rel_line', 50, 50,
		--quad curves
		'move', 100, 60,
		'rel_quad_curve', 20, -100, 40, 0,
		'rel_symm_quad_curve', 40, 0,
		'rel_move', 50, 0,
		'rel_smooth_quad_curve', 100, 20, 0, --smooth without a tangent
		'rel_move', 50, 0,
		'rel_quad_curve', 20, -100, 20, 0,
		'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
		'rel_move', 50, 0,
		'rel_curve', 0, -50, 40, -50, 40, 0,
		'rel_smooth_quad_curve', 50, 40, 0, --smooth a cubic curve
		'rel_move', 50, 0,
		'rel_arc_3p', 0, -40, 50, 0,
		'rel_smooth_quad_curve', 50, 40, 0, --smooth an arc
		'rel_move', 50, -50,
		'rel_line', 0, 50,
		'rel_smooth_quad_curve', 50, 40, 0, --smooth a line
		'rel_move', 50, 0,
		'rel_quad_curve_3p', 20, -50, 40, 0,  --3p
		--cubic curves
		'move', 100, 200,
		'rel_curve', 0, -50, 40, -50, 40, 0,
		'rel_symm_curve', 40, 50, 40, 0,
		'rel_move', 50, 0,
		'rel_smooth_curve', 100, 20, 50, 20, 0, --smooth without a tangent
		'rel_move', 50, 0,
		'rel_quad_curve', 20, -100, 20, 0,
		'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a quad curve
		'rel_move', 50, 0,
		'rel_curve', 0, -50, 40, -50, 40, 0,
		'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a cubic curve
		'rel_move', 50, 0,
		'rel_arc_3p', 0, -40, 50, 0,
		'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth an arc
		'rel_move', 50, -50,
		'rel_line', 0, 50,
		'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a line
		--arcs
		'move', 100, 350,
		'rel_line_arc', 0, 0, 50, -90, 180,
		'rel_move', 100, -50,
		'rel_arc', 0, 0, 50, -90, 180,
		'rel_move', 100, -100,
		'rel_svgarc', -50, -20, -30, 0, 1, 30, 40,
		'rel_svgarc', -50, -20, -30, 1, 0, 30, 40,
		'rel_svgarc', 10, 0, 0, 0, 0, 50, 0, --invalid parametrization (zero radius)
		'rel_svgarc', 10, 10, 10, 10, 0, 0, 0, --invalid parametrization (endpoints coincide)
		'rel_move', 50, -50,
		'rel_arc_3p', 40, -40, 80, 0,
		'rel_arc_3p', 40, 0, 40, 0, --invalid parametrization (endpoints are collinear)
		'rel_arc_3p', 0, 0, 0, 0, --invalid parametrization (endpoints coincide)
		'rel_move', 70, 0,
		'rel_line_elliptic_arc', 0, 0, 70, 30, 0, -270, -30,
		'close',
		--closed shapes
		'rect', 100+60, 550, -50, -100,
		'round_rect', 100+120, 550, -50, -100, -10,
		'elliptic_rect', 100+180, 550, -50, -100, -100, -10,
		'elliptic_rect', 100+240, 550, -50, -100, -10, -100,
		'circle', 100+300, 500, -50,
		'ellipse', 100+390, 500, -30, -50, 30,
		'move', 100+480, 500,
		'rel_circle_3p', 50, 0, 0, 50, -50, 0,
		'superformula', 100+580, 500, 50, 300, 1, 1, 3, 1, 1, 1,
		'move', 100+700, 500,
		'rel_star', 0, 0, 0, -50, 30, 8,
		'move', 100+800, 500,
		'rel_star_2p', 0, 0, 0, -50, 20, 15, 5,
		'move', 100+900, 500,
		'rel_rpoly', 0, 0, 20, -30, 5,
		'move', 700, 250,
		'rel_text', 0, 0, {size=70}, 'mittens',
	}

	--convert to abs. form and draw
	if true then
		local ap = path.to_abs(p)
		draw(ap, mt)
		cr:set_source_rgba(1,0,0,1)
		cr:set_line_width(7)
		cr:stroke()
	end

	--convert to rel. form and draw
	if true then
		local rp = path.to_rel(p)
		draw(rp, mt)
		cr:set_source_rgba(0,0,.5,1)
		cr:set_line_width(5)
		cr:stroke()
	end

	--draw as is
	if true then
		draw(p, mt)
		cr:set_source_rgba(1,1,1,1)
		cr:set_line_width(2)
		cr:stroke()
	end

	--draw bounding box
	if true then
		local x,y,w,h = path.bounding_box(p, mt)
		draw{'rect',x,y,w,h}
		cr:set_source_rgba(1,1,1,.5)
		cr:set_line_width(1)
		cr:stroke()
	end

	if true then
		local len = path.length(p, mt)
		cr:set_source_rgb(1,1,1)
		cr:move_to(self.window.client_w - 160, 20)
		cr:set_font_size(18)
		cr:text_path(string.format('length: %4.2f', len))
		cr:fill()
	end

	if true then
		local x0, y0 = self.mouse_x or 0, self.mouse_y or 0
		local d,x,y,i,t = path.hit(x0, y0, p, mt)
		cr:circle(x,y,5)
		cr:set_source_rgb(1,1,0)
		cr:fill()
		cr:move_to(x,y+16)
		cr:text_path(string.format(t and '%s: %g' or '%s', p[i], t))
		cr:fill()
	end

	if true then
		ap = path.to_abs(p)
		for i,s in path.subpaths(ap) do
			--[[
			local x,y,w,h = path.bounding_box({unpack(p,i,path.subpath_end(p,i))}, mt)
			draw{'rect',x,y,w,h}
			cr:set_source_rgba(1,1,1,.5)
			cr:stroke()
			]]
		end
	end
	--os.exit(1)

	--[[
	for i,s in path.commands(p) do
		local x,y,w,h = path.bounding_box({path.cmd(p, i)}, mt)
		draw{'rect',x,y,w,h}
		cr:set_source_rgba(1,1,1,.5)
		cr:stroke()
	end
	]]

end
player:play()
