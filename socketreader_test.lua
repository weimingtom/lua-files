local socket = require'socket'
local socketreader = require'socketreader'

reader = socketreader()

local skt = assert(socket.tcp())
--assert(skt:settimeout(1,'b'))
--assert(skt:settimeout(1,'t'))
assert(skt:connect('www.google.ro', 80))

local function readall(skt, prefix)
	local s, err, partial = skt:receive'*a'
	if s then return s end
	if err == 'timeout' then
		return readall(skt, partial)
	end
	error(err)
end

local path = '/'
local host = 'www.google.ro'
skt:send(
		'GET '.. path ..' HTTP/1.1' .. '\r\n' ..
		'Host: ' .. host .. '\r\n' ..
		'Connection: close' .. '\r\n' ..
		'Cache-Control: max-age=0' .. '\r\n' ..
		'User-Agent: Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.64 Safari/537.31' .. '\r\n' ..
		'\r\n'
)
print(readall(skt))
skt:close()

