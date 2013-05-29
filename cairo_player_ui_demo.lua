local player = require'cairo_player'


function player:on_render(cr)
	cr:reset_clip()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	self.tab = self.tab or 2
	self.text1 = self.text1 or 'edit me'
	self.text2 = self.text2 or 'edit me too as I am a very long string that wants to be edited'

	self.tab = self:tabs{id = 'tabs', x = 10, y = 10, w = 200, h = 24, buttons = {'tab1', 'tab2', 'tab3'}, selected = self.tab}

	if self.tab == 1 then

		local rx, ry, rw, rh = 10, 40, 260, 140

		self.vx = self:hscrollbar{id = 'hs', x = rx, y = ry + rh, w = rw, h = 16, size = rw * 2, i = self.vx or 0}
		self.vy = self:vscrollbar{id = 'vs', x = rx + rw, y = ry, w = 16, h = rh, size = rh * 2, i = self.vy or 0}

		cr:rectangle(rx, ry, rw, rh)
		cr:clip()
		cr:set_source_rgba(1,1,1,0.1)
		cr:paint()

		if self:button{id = 'apples_btn', x = rx - self.vx, y = ry - self.vy, w = 100, h = 24, text = 'go apples!'} then
			self.fruit = 1
		end

		if self:button{id = 'bannanas_btn', x = rx - self.vx, y = ry + 30 - self.vy, w = 100, h = 24, text = 'go bannanas!'} then
			self.fruit = 2
		end

		if self:button{id = 'undecided_btn', x = rx - self.vx, y = ry + 2*30 - self.vy, w = 100, h = 24, text = 'meh, dunno...'} then
			self.fruit = nil
		end

		self.fruit = self:mbutton{id = 'fruits_btn', x = rx - self.vx, y = ry + 3*30 - self.vy, w = 260, h = 24,
											buttons = {'apples', 'bannanas', 'cherries'}, selected = self.fruit}

	elseif self.tab == 2 then

		self.text1 = self:edit{id = 'ed1', x = 10, y = 40, w = 200, h = 24, text = self.text1, next_tab = 'ed2', prev_tab = 'ed2'}
		self.text2 = self:edit{id = 'ed2', x = 10, y = 70, w = 200, h = 24, text = self.text2, next_tab = 'ed1', prev_tab = 'ed1'}

	end
end

player:play()

