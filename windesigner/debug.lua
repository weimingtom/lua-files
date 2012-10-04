--debug: setup the app. environment for easy debugging
setfenv(1, require'namespace')

--set strict mode for the whole namespace
local _G = _G
function _M:__index(k)
	if _G[k] ~= nil then return _G[k] end
	error('Undefined global %s' % k, 2)
end

local declared = {}
function _M:__newindex(k,v)
	local w = debug.getinfo(2, 'S').what
	if w == 'main' or w == 'C' then
		declared[k] = true
		rawset(self, k, v)
	else
		error('Assignment to undeclared global %s' % k, 2)
	end
end
