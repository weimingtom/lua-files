--get the number of CPU cores on multiple platforms
local ffi = require'ffi'

local ncpu = {}

function ncpu.Windows()
	local winapi = require'winapi'
	require'winapi.sysinfo'
	return winapi.GetSystemInfo().dwNumberOfProcessors
end

function ncpu.Linux() --Linux, Solaris, & AIX and Mac OS X (for all OS releases >= 10.4, i.e., Tiger onwards)
	return ffi.C.sysconf(C._SC_NPROCESSORS_ONLN)
end

local function numcpu()
	return assert(ncpu[ffi.os], 'unsupported OS')()
end

if not ... then print(numcpu()) end

return numcpu

