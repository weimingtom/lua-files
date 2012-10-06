--cache class: provides shared caching for scene graphs elements.
--an element's fields "invalid", "nocache", and "invalidate" are reserved for cache control.
local glue = require'glue'

local Cache = {} --if you have shared nodes between scene graphs, then share the cache too.

local weak_keys = {__mode = 'k'} --when elements go, associated objects go too.

function Cache:new()
	local objects = setmetatable({}, weak_keys) --we rely on objects ability to free resources on their __gc.
	local release_function = function(e)
		self:release(e)
	end
	return glue.merge({objects = objects, release_function = release_function}, self)
end

function Cache:get(e)
	if e.invalid or e.nocache then
		self:release(e)
		return
	end
	return self.objects[e]
end

function Cache:set(e,o)
	assert(self.objects[e] == nil, 'cache: object alreay set')
	self.objects[e] = o
	e.release = self.release_function --give elements a convenient way to clear their cached object on-demand
end

function Cache:release(e) --clear cached objects of e
	local o = self.objects[e]
	if o then
		if o.free then o:free() end
		self.objects[e] = nil
		e.release = nil
	end
end

function Cache:release_all(e) --clear cached objects of e and its children
	if type(e) ~= 'table' then return end
	self:release(e)
	for k,v in pairs(e) do
		self:release_all(k)
		self:release_all(v)
	end
end

function Cache:clear()
	for e in pairs(self.objects) do
		self:release(e)
	end
	self.objects = {}
end

function Cache:free()
	self:clear()
	self.objects = nil
end

return Cache
