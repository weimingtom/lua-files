--ffi/array: variable length array (VLA) wrapper/memoizer.
setfenv(1, require'winapi.namespace')
require'winapi.ffi'
require'winapi.types'

arrays = {}
setmetatable(arrays, arrays)

function arrays:__index(type_str)
	local ctype = ffi.typeof(type_str..'[?]')
	local itemsize = ffi.sizeof(type_str)
	self[type_str] = function(t)
		if not ffi.istype(ctype, t) then
			if type(t) == 'table' then
				t = ctype(#t, t)
			else
				t = ctype(t)
			end
		end
		return t, ffi.sizeof(t) / itemsize
	end
	return self[type_str]
end

