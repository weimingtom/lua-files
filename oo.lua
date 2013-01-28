--object system with the following characteristics:
--
--single inheritance: class creation is done with class([<superclass>]) or superclass:subclass().
--inheritance is dynamic: changing the superclass reflects on all subclasses and instances.
--a class' superclass, or an instance's class is accessible as self.super.
--subclassing is different than instantiation: instantiation calls self:init(...), subclassing doesn't.
--instantiation is done with myclass:create(...) or simply myclass(...).
--virtual properties: reading self.<property> calls self:get_<property>() to retrieve the value.
--  writing self.<property> calls self:set_<property>(value).
--stored properties, or virtual properties with a setter but no getter: writing self.<property> creates the table
--  self.state and the value is stored in self.state.<property> only after calling self:set_<property>(value).
--  reading self.<property> reads back the value from self.state. you can initialize self.state with defaults.
--before/after hooks: method overriding can be done by defining self:before_<method> and self:after_<method> functions.
--  setting self:before_<method> overrides self:<method> such as it will call the hook before calling the method.
--  the hook receives the method's args and must return the final args to pass to the method.
--  setting self:after_<method> overrides self:<method> such as it will call the hook after calling the method.
--  the hook receives the method's return values and must return the final return values.
--classes are assigned the metatable of their superclass, instances get the metatable of their class.
--
--free stuff:
--
--subclassing from an instance: instance:subclass().
--instantiation from an instance: instance:create(...). note that instance() does not work.
--customizing subclassing: override self:subclass().
--class properties get inherited and behave like default values.
--

local object = {classname = 'object'}

local function class(super, classname)
	return (super or object):subclass(classname)
end

function object:subclass(classname)
	return setmetatable({super = self, classname = classname}, getmetatable(self))
end

function object:init(...) end

function object:create(...)
	local o = setmetatable({super = self}, getmetatable(self))
	o:init(...)
	return o
end

local meta = {}

function meta.__call(o,...)
	return o:create(...)
end

function meta.__index(o,k)
	if k == 'get_property' then --'get_property' is not virtualizable to avoid infinite recursion
		return rawget(o, 'super').get_property --...but it is inheritable
	end
	return o:get_property(k)
end

function meta.__newindex(o,k,v)
	o:set_property(k,v)
end

function object:before_hook(method_name, hook)
	local method = self[method_name]
	if not method then error(string.format('method missing for %s hook', k)) end
	rawset(self, method_name, function(self, ...)
		return method(self, hook(self, ...))
	end)
end

function object:after_hook(method_name, hook)
	local method = self[method_name]
	if not method then error(string.format('method missing for %s hook', k)) end
	rawset(self, method_name, function(self, ...)
		return hook(method(self, ...))
	end)
end

function object:get_property(k)
	if type(k) == 'string' and rawget(self, 'get_'..k) then --virtual property
		return rawget(self, 'get_'..k)(self, k)
	elseif rawget(self, 'set_'..k) then --stored property
		if rawget(self, 'state') then
			return self.state[k]
		end
	elseif rawget(self, 'super') then --inherited property
		return rawget(self, 'super')[k]
	end
end

function object:set_property(k,v)
	if type(k) == 'string' then
		if rawget(self, 'get_'..k) then --virtual property
			if rawget(self, 'set_'..k) then --r/w property
				rawget(self, 'set_'..k)(self, v)
			else --r/o property
				error(string.format('trying to set read only property "%s"', k))
			end
		elseif rawget(self, 'set_'..k) then --stored property
			if not rawget(self, 'state') then rawset(self, 'state', {}) end
			rawget(self, 'set_'..k)(self, v) --if the setter breaks, the property is not updated
			self.state[k] = v
		elseif k:match'^before_' then --install before hook
			local method_name = k:match'^before_(.*)'
			self:before_hook(method_name, v)
		elseif k:match'^after_' then --install after hook
			local method_name = k:match'^after_(.*)'
			self:after_hook(method_name, v)
		else
			rawset(self, k, v)
		end
	else
		rawset(self, k, v)
	end
end

function object:own_meta()
	local meta = {}
	for k,v in pairs(getmetatable(self)) do meta[k] = v end
	setmetatable(self, meta)
	return meta
end

function object:freeze()
	for k,v in self:pairs() do
		self[k] = v
	end
	local meta = self:own_meta()
	local get_property = self.get_property
	local set_property = self.set_property
	meta.__index = function(self, k) return get_property(self, k) end
	meta.__newindex = function(self, k, v) return set_property(self, k, v) end
end

function object:gen_properties(names, getter, setter)
	for k in pairs(names) do
		if getter then
			self['get_'..k] = function(self) return getter(self, k) end
		end
		if setter then
			self['set_'..k] = function(self, v) return setter(self, k, v) end
		end
	end
end

--introspection

function object:allpairs() --returns iterator<k,v,source>; iterates from bottom up
	local source = self
	local k,v
	return function()
		k,v = next(source,k)
		if k == nil then
			source = source.super
			if source == nil then return nil end
			k,v = next(source)
		end
		return k,v,source
	end
end

function object:pairs()
	local t = {}
	for k,v in self:allpairs() do
		if t[k] == nil then t[k] = v end
	end
	return pairs(t)
end

local function pad(s, n) return s..(' '):rep(n - #s) end

function object:inspect()
	local pp = require'pp'
	--collect data
	local supers = {}
	local keys = {}
	local keys_t = {}
	local props = {}
	local source
	for k,v,src in self:allpairs() do
		keys[#keys+1] = k
		if src ~= source then
			table.sort(keys)
			source = src
			keys = {}
			keys_t[source] = keys
			supers[#supers+1] = source
		end
		if type(k) == 'string' and k:match'^[gs]et_' then
			local prop = k:match'^[gs]et_(.*)'
			props[prop] = (props[prop] or '')..(k:match'^.' == 's' and 'w' or 'r')
		end
	end

	--print values
	for i,super in ipairs(supers) do
		print('from '..(
					rawget(super, 'classname') and super.classname
					or super == self and 'self'
					or '#'..tostring(i)
				)..':')
		for _,k in ipairs(keys_t[super]) do
			if k ~= 'super' and k ~= 'state' then
				print('', pad(k, 16), tostring(super[k]))
			end
		end
	end
end

setmetatable(object, meta)

if not ... then require'oo_test' end

return {
	class = class,
}

