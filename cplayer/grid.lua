local player = require'cairo_player'

function player:grid(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)

	local fields = assert(t.fields, 'field missing')
	local rows = assert(t.rows, 'rows missing')
	local field_meta = t.field_meta
	local state = t.state or {
		selected_row = 1
	}
	local default_col_w = 100
	local col_spacing = 4
	local row_h = 24
	local font_size = t.font_size or row_h/2

	local cw = 0
	for i,name in ipairs(fields) do
		cw = cw + (field_meta and field_meta[name] and field_meta[name].w or default_col_w)
		cw = cw + (i < #fields and col_spacing or 0)
	end
	local ch = (1 + #rows) * row_h

	local cx, cy, bx, by, bw, bh = self:scrollbox{
		id = id .. '_scrollbox',
		x = x, y = y, w = w, h = h,
		cw = cw,
		ch = ch,
		cx = state.cx,
		cy = state.cy,
		vscroll = 'auto',
		hscroll = 'auto',
	}

	state.cx = cx
	state.cy = cy

	self.cr:rectangle(bx, by, bw, bh)
	self.cr:save()
	self.cr:clip()
	self.cr:translate(bx + cx, by + cy)

	self:rect(0, 0, cw, ch, 'normal_bg')
	self:rect(0, 0, cw, row_h, 'selected_bg')

	local field_x = 0
	for i,name in ipairs(fields) do
		local field = field_meta and field_meta[name]
		local col_w = field and field.w or default_col_w
		local col_align = field and field.align or 'left'

		self:text(name, font_size, 'selected_fg', col_align, 'middle', field_x, 0, col_w, row_h)

		field_x = field_x + col_w + col_spacing
	end

	local field_x = 0
	local field_y = row_h
	for j,row in ipairs(rows) do

		local selrow = state.selected_row == j
		local hotrow = self:hotbox(0, field_y, cw, row_h)
		if hotrow and self.clicked then
			state.selected_row = j
			selrow = true
		end

		if selrow or hotrow then
			self:rect(0, field_y, cw, row_h, selrow and 'selected_bg' or 'hot_bg')
		end

		for i,name in ipairs(fields) do
			local field = field_meta and field_meta[name]
			local col_w = field and field.w or default_col_w
			local col_align = field and field.align or 'left'
			local v = tostring(row[i])

			self:text(v, font_size, selrow and 'selected_fg' or hotrow and 'hot_fg' or 'normal_fg',
							col_align, 'middle', field_x, field_y, col_w, row_h)

			field_x = field_x + col_w + col_spacing
		end
		field_y = field_y + row_h
		field_x = 0
	end

	self.cr:restore()

	return state
end

if not ... then require'cairo_player_demo' end

