--uuid cross-platform API
local ffi = require'ffi'

local gen

if ffi.abi'win' then
	local winapi = require'winapi'
	require'winapi.uuid'
	gen = function()
		return tostring(winapi.UuidCreate())
	end
elseif ffi.os'Linux' then
	gen = function()
		error'NYI'
	end
end

return {
	gen = gen,
}

