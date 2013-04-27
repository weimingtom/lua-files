--luasocket implementation of the readbuffer interface for use with string-based network protocols like http.
local socket = require'socket'

local function new(skt)

	local function readline(prefix)
		local s, err, partial = skt:receive('*l', prefix)
		if s then return s end
		if err == 'timeout' then
			return readline(prefix)
		end
		error(err)
	end

	local function readsize(sz)
		return function()
			if sz == 0 then return end
			local s, err, partial = skt:receive(sz)
			if not s then
				if err == 'timeout' then
					s = partial
				else
					error(err)
				end
			end
			sz = sz - #s
			return s
		end
	end

	local function readall()
		local done
		return function()
			local s, err, partial = skt:receive('*a')
			if s then
				return s
			elseif err == 'timeout' then
				return partial
			elseif done then
				return
			elseif err == 'closed' then
				done = true
				return partial
			else
				error(err)
			end
		end
	end

	return {
		readline = readline,
		readsize = readsize,
		readall = readall,
	}
end

if not ... then require'http_client_test' end

return new
