local socket = require'socket'

return function()
	local loop = {}
	function loop.connect(address, port)
		local skt = assert(socket.tcp())
		assert(skt:connect(address, port))
		return skt
	end
	function loop.newthread(f) loop.f = f end
	function loop.start() loop.f() end
	return loop
end
