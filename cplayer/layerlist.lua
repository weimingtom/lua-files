--layer list for decoupling paint order from call order in IMGUIs.
local list = {}

function list:new()
	return setmetatable({layers = {}}, {__index = self})
end

function list:add(layer, z_order)
	z_order = z_order or 0
	local index = #self.layers - z_order + 1
	index = math.min(math.max(index, 1), #self.layers + 1)
	table.insert(self.layers, index, layer)
end

function list:indexof(layer)
	for i,layer1 in ipairs(self.layers) do
		if layer1 == layer then
			return i
		end
	end
end

function list:remove(layer)
	table.remove(self.layers, self:indexof(layer))
end

function list:bring_to_front(layer)
	self:remove(layer)
	self:add(layer)
end

function list:send_to_back(layer)
	self:remove(layer)
	self:add(layer, 1/0)
end

function list:render(cx)
	for i,layer in ipairs(self.layers) do
		if layer.visible then
			layer:render(cx)
		end
	end
end

function list:hit(x, y)
	for i = #self.layers, 1, -1 do
		local layer = self.layers[i]
		if layer.visible and layer:hit(x, y) then
			return layer
		end
	end
end


if not ... then require'cplayer.layerlist_demo' end


return list
