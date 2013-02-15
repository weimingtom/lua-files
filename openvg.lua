require'vgext_h_amanith'
local ffi = require'ffi'
local glue = require'glue'

local function bind(C)
	local M = setmetatable({C = C}, {__index = function(t,k) t[k] = C[k]; return C[k] end})

	function M.vgGetString(...)
		return ffi.string(C.vgGetString(...))
	end

	return M
end

if not ... then require'amanithvg_test' end

return {
	bind = bind,
}