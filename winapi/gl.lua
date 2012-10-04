--proc/gl: opengl dynamic namespace based on PFN*PROC cdefs and wglGetProcAddress.
--instead of loading this module, you should require gl11, gl21, wglext etc. as needed.
setfenv(1, require'winapi')
require'winapi.wgl'

local function accesssym(lib, symbol) return lib[symbol] end
local function checksym(lib, symbol)
	local ok,v = pcall(accesssym, lib, symbol)
	if ok then return v else return nil,v end
end

gl = setmetatable({}, {__index = function(t,k)
	local v = checksym(opengl32, k)
	if not v then v = ptr(ffi.cast('PFN' .. k:upper() .. 'PROC', wglGetProcAddress(k))) end
	if not v then return nil end
	t[k] = v
	return v
end})

--[[
local errors = {
	[0x0500] = 'GL_INVALID_ENUM',
	[0x0501] = 'GL_INVALID_VALUE',
	[0x0502] = 'GL_INVALID_OPERATION',
	[0x0503] = 'GL_OUT_OF_MEMORY',
	[0x0506] = 'GL_INVALID_FRAMEBUFFER_OPERATION',
	[0x0503] = 'GL_STACK_OVERFLOW',
	[0x0504] = 'GL_STACK_UNDERFLOW',
	[0x8031] = 'GL_TABLE_TOO_LARGE',
}

local disabled

local function __index(t,k)
	local sym = gl[k]

	local v = ptr(ffi.cast('PFN' .. k:upper() .. 'PROC', wglGetProcAddress(k)))
	if not v then return nil end
	t[k] = v
	return v

	local v = sym
	if type(v) == 'cdata' then
		v = function(...)
			if k == 'glBegin' then
				disabled = true
			elseif k == 'glEnd' then
				disabled = false
			end
			local ret = sym(...)
			if not disabled then
				local err = gl.glGetError()
				if err ~= 0 then
					error(string.format('%s Error 0x%x: %s', k, err, errors[err] or 'Unknown error.'), 2)
				end
			end
			return ret
		end
	end
	--t[k] = v
	return v
end
]]
