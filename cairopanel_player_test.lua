local player = require'cairopanel_player'

math.randomseed(os.time())

local c = 0
function player:on_render(cr)
	if c % 100 == 0 then
		cr:identity_matrix()
		cr:translate(500, 400)
		c = 0
	end
	c = c + 1
	local i = math.random(100)
	cr:translate(i, i)
	cr:rotate(i)
	cr:set_source_rgba(i/100,i/100,0,.97)
	cr:rectangle(0,0,100,100)
	cr:fill_preserve()
	cr:set_source_rgba(1-i/100,1-i/100,0,1)
	cr:stroke()
end

player:play()

