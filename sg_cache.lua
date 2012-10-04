--cache class: provides shared caching for scene graphs.
local glue = require'glue'

local Cache = {} --if you have shared nodes between scene graphs, then share the cache too.

function Cache:new()
	return glue.merge({objects = {}}, self)
end

function Cache:get(e)
	local o = self.objects[e]
	if o and (e.invalid or e.nocache) then
		if o.free then o:free() end
		e.invalid = nil
		self.objects[e] = nil
		return
	end
	return o
end

function Cache:set(e,o)
	assert(self.objects[e] == nil, 'scene graph cache: overwrite')
	self.objects[e] = o
end

function Cache:clear()
	for e,o in pairs(self.objects) do
		if o.free then o:free() end
	end
	self.objects = {}
end

function Cache:free()
	self:clear()
	self.objects = nil
end

function Cache:delete(e) --clear objects of e and its children; assume only table values (not keys) can cache objects.
	local o = self.objects[e]
	if o and o.free then o:free() end
	if type(e) ~= 'table' then return end
	for k,v in pairs(e) do
		self:clear(v)
	end
end

return Cache
