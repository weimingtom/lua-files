setfenv(1, require'windesigner.namespace')

Inspector = class(Window)

function Inspector:__init(designer)

	Inspector.__index.__init(self, {
		owner = designer.window,
		x = 10, y = 560, w = 200, h = 400,
		visible = false,
		tool_window = true,
		title = 'Properties',
		noclose = true,
	})

	self.designer = designer

	self.list = ReportListView{parent = self, x = 0, y = 0,
		w = self.client_w,
		h = self.client_h,
		tabstops = true,
		vscroll = true,
		free_height = true,
		full_row_select = true,
		single_selection = true,
		grid_lines = true,
		always_show_selection = true,
		track_select = true,
		hoover_time = 1,
		anchors = {left = true, top = true, right = true, bottom = true},
		min_size = {w = 100, h = 100},
		columns = {'property', 'value'}
	}

	local edit
	function self.list:on_selection_changed(i, subitem, selected)
		if not selected then
			edit.visible = false
		else
			local r = self.items:get_rect(i,1)
			local q = (edit.h - edit.client_h) / 2
			r.y1 = r.y1 - q
			r.y2 = r.y2 + q
			edit.rect = r
			--edit.text = self.items:get(i).text
			edit.visible = true
			edit:focus()
		end
	end

	function self.list:NM_CUSTOMDRAW(t)
		t = ffi.cast('NMLVCUSTOMDRAW*', t)
		if t.nmcd.stage == CDDS_PREPAINT then
			return CDRF_NOTIFYITEMDRAW
		elseif t.nmcd.stage == CDDS_ITEMPREPAINT then
			return CDRF_NOTIFYSUBITEMDRAW
		elseif t.nmcd.stage == bit.bor(CDDS_SUBITEM, CDDS_ITEMPREPAINT) then
			if t.subitem == 0 then
				t.bk_color = RGB(200,200,200)
				return CDRF_NEWFONT
			elseif t.subitem == 1 then
				t.bk_color = RGB(255,255,255)
				return CDRF_NEWFONT
			end
		end
		return CDRF_DODEFAULT
	end

	edit = Edit{parent = self.list,
		margins = {3,0},
		visible = false,
		client_edge = true,
	}


	self.controls = {}

	self.visible = true
end

local function keysequal(t1, t2)
	for k in pairs(t1) do if t2[k] == nil then return false end end
	for k in pairs(t2) do if t1[k] == nil then return false end end
	return true
end

function Inspector:inspect(controls)
	if keysequal(controls, self.controls) then return end
	self.controls = controls
	return self:inspect_one(next(controls))
end

function Inspector:inspect_one(ctl)
	local function add(k,v,indent)
		k=('  '):rep(indent)..tostring(k)
		if isinstance(v, ItemList) then
			self.list.items:add(k)
			for i=1,v.count do
				add(i,v:get(i),indent+1)
			end
		elseif isinstance(v, Object) then
			self.list.items:add(k)
			self.list.items:set_subitem(self.list.items.count, 1, '<object>')
		elseif type(v) == 'table' then
			self.list.items:add(k)
			for k,v in pairs(v) do
				add(k,v,indent+1)
			end
		else
			self.list.items:add(k)
			self.list.items:set_subitem(self.list.items.count, 1, tostring(v))
		end
	end
	self.list:batch_update(function()
		self.list.items:clear()
		for k,v in pairs(ctl) do
			add(k,v,0)
		end
		self.list.items:add'----------------'
		for name, info in ctl:__vproperties() do
			add(name,ctl[name],0)
		end
	end)
end

