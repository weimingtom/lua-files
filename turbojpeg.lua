--turbojpeg binding
local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
require'turbojpeg_h'
local C = ffi.load'turbojpeg'

local function err()
	error(string.format('TurboJPEG Error: %s', GetErrorStr()), 3)
end

local function checkh(h) if h == nil then err() end; return h end
local function checkz(i) if i ~= 0 then err() end; end

local function compress(...)
	checkh(C.tjInitCompress())
end

local function decompress(...)
	return glue.fcall(function(finally)
		local tj = checkh(C.tjInitDecompress())
		finally(function() checkz(C.tjDestroy(tj)) end)
	end)
end

if not ... then require'turbojpeg_test' end

return {
	compress = compress,
	decompress = decompress,
}

