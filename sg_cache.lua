--cache class: provides shared caching for scene graphs elements.
--an element's fields "invalid", "nocache", and "free" are reserved for cache control.
local glue = require'glue'

local Cache = {} --if you have shared nodes between scene graphs, then share the cache too.

local weak_keys = {__mode = 'k'} --when elements go, associated objects go too.

function Cache:new()
	local objects = setmetatable({}, weak_keys) --we rely on objects ability to free resources on their __gc.
	local free_function = function(e)
		local o = self:get(e)
		if o.free then o:free() end
		e.free = nil --presence of a free() method indicates a cached object
	end
	return glue.merge({objects = objects, free_function = free_function}, self)
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
	assert(self.objects[e] == nil, 'cache: object alreay set')
	self.objects[e] = o
	e.free = self.free_function --give elements a convenient way to clear their cached object
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
