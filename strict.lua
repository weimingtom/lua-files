--strict mode for _G
local declared = {}
local meta = {}
setmetatable(_G, meta)

function meta:__index(k)
	if declared[k] then return nil end
	if rawget(self,k) ~= nil then return rawget(self,k) end
	error(string.format('undefined global %s', k), 2)
end

function meta:__newindex(k,v)
	local w = debug.getinfo(2, 'S').what
	if w == 'main' or w == 'C' or declared[k] then
		declared[k] = true
		rawset(self, k, v)
	else
		error(string.format('assignment to undeclared global %s', k), 2)
	end
end
