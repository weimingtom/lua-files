--layouting API: box stack and box-based alignment and hit testing
local player = require'cplayer'

--UI controls state
player.active = nil  --active control id
player.ui = {}       --active control state

function player:getbox(x, y, w, h) --get a box with missing sides snapped to the current box
	if type(x) == 'table' then
		x, y, w, h = x.x, x.y, x.w, x.h
	end
	return x or 0, y or 0, w or self.w, h or self.h
end

function player:absbox(x, y, w, h) --get the abs. box of a rel. box
	x, y, w, h = self:getbox(x, y, w, h)
	return self.x + x, self.y + y, w, h
end

function player:pushbox(x, y, w, h) --push a rel. box making it the current box
	table.insert(self.boxstack, {x = self.x, y = self.y, w = self.w, h = self.h})
	self.x, self.y, self.w, self.h = self:absbox(x, y, w, h)
end

function player:popbox(advancex, advancey) --pop the stack optionally pushing a new box
	advancex = advancex or 0
	advancey = advancey or 0
	if advancex ~= 0 or advancey ~= 0 then
		if advancex then
			self.x = self.x + self.w
		else
			self.y = self.y + self.h
		end
		self.w = self.boxstack[#self.boxstack].w
		self.h = self.boxstack[#self.boxstack].h
	else
		local t = table.remove(self.boxstack)
		self.x, self.y, self.w, self.h = t.x, t.y, t.w, t.h
	end
end

function player:alignbox(w, h, halign, valign, bx, by, bw, bh)
	bx, by, bw, bh = self:getbox(bx, by, bw, bh)
	local x =
		halign == 'center' and (2 * bx + bw - w) / 2 or
		halign == 'left' and bx or
		halign == 'right' and bx + bw - w
	local y =
		valign == 'middle' and (2 * by + bh - h) / 2 or
		valign == 'top' and by or
		valign == 'bottom' and by + bh - h
	return x, y, w, h
end

function player:savebox(x, y, w, h)
	x, y, w, h = self:absbox(x, y, w, h)
	return {x = x, y = y, w = w, h = h}
end

function player:setbox(x, y, w, h) --set current box to a previously saved box
	self.x, self.y, self.w, self.h = self:getbox(x, y, w, h)
end

function player:vsplit(h1, h2)
	assert(h1 or h2, 'h1 or h2 missing')
	h1 = h1 or self.h - h2
	h2 = h2 or self.h - h1
	return
		self:savebox(nil, nil, nil, h1),
		self:savebox(nil, h1, nil, nil)
end

function player:hsplit(w1, w2)
	assert(w1 or w2, 'w1 or w2 missing')
	w1 = w1 or self.w - w2
	w2 = w2 or self.w - w1
	return
		self:savebox(nil, nil, w1, nil),
		self:savebox(w1, nil, nil, nil)
end

function player:nsplit(n, direction, x, y, w, h) --direction = 'v' or 'h'
	x, y, w, h = self:getbox(x, y, w, h)
	assert(direction == 'v' or direction == 'h', 'invalid direction')
	return coroutine.wrap(function()
		for i=1,n do
			if direction == 'v' then
				self:pushbox(x, y + (i - 1) * h / n, w, h / n)
			else
				self:pushbox(x + (i - 1) * w / n, y, w / n, h)
			end
			coroutine.yield(i)
			self:popbox()
		end
	end)
end

--text API

function player:rect(x, y, w, h)
	self.cr:rectangle(x or 0, y or 0, w or self.w, h or self.h)
end

function player:text(text, color, halign, valign)
	self:aligntext(text, 0, 0, self.w, self.h, halign or 'center', valign or 'middle')
	self:setcolor(color or 'normal_fg')
	self.cr:show_text(text)
end

if not ... then require'cplayer_ui_demo' end
