--luasocket implementation of the reader interface used by the http parser.
local socket = require'socket'

return function(skt)
	local reader = {}

	local function readline(prefix)
		local s, err, partial = skt:receive('*l', prefix)
		if s then return s end
		if err == 'timeout' then
			return readline(prefix)
		end
		error(err)
	end
	function reader:readline()
		return readline()
	end

	function reader:readchunks(sz)
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

	local function readall(prefix)
		local s, err, partial = skt:receive(16384)
		--print(s and #s or nil, prefix and #prefix or nil, err, partial and #partial or nil)
		if s then
			return readall(s)
		elseif err == 'timeout' then
			return readall(partial)
		elseif err == 'closed' then
			return partial
		end
		error(err)
	end
	local done
	function reader:readall()
		if done then return end
		done = true
		return readall()
	end

	return reader
end

