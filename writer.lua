
--sender
function fakesend(send_sizes)
	local i = 1
	local buf = ''
	return function(s)
		local size = math.min(#s, send_sizes[i]) i = i + 1
		buf = buf .. s:sub(1, size)
		--print('send', size, s:sub(1, size))
		return size
	end, function() return buf end
end

--send in multiple chunks
local send, readbuf = fakesend{9,2,1,1,1}
local write = writecache(send, 2)
write('abcde'); assert(readbuf() == 'abcde')


--send(s) -> n
function writecache(send, flushsize)
	flushsize = flushsize or 65536
	return function(s)
		local i = 1
		while true do
			local n = math.min(flushsize, #s - i + 1)
			if n == 0 then break end
			n = send(s:sub(i, i + n - 1))
			i = i + n
		end
	end
end

