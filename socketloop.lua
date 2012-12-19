local socket = require'socket'
local glue = require'glue'

return function()
	local loop = {}
	local read, write = {}, {} --{skt: thread}
	local function wait(rwt,skt)
		rwt[skt] = coroutine.running()
		coroutine.yield()
		rwt[skt] = nil
	end
	local function accept(skt,...)
		wait(read,skt)
		return assert(skt:accept(...))
	end
	local function receive(skt,...)
		wait(read,skt)
		s = assert(skt:receive(...))
		return s
	end
	local function send(skt,...)
		wait(write,skt)
		return assert(skt:send(...))
	end
	local function close(skt,...)
		write[skt] = nil
		read[skt] = nil
		return assert(skt:close(...))
	end
	function loop.wrap(skt)
		local o = {socket = skt}
		function o:accept(...) return loop.wrap(accept(skt,...)) end
		function o:receive(...) return receive(skt,...) end
		function o:send(...) return send(skt,...) end
		function o:close(...) return close(skt,...) end
		return o
	end
	function loop.connect(address, port, locaddr, locport)
		local skt = assert(socket.tcp())
		assert(skt:settimeout(0,'b'))
		assert(skt:settimeout(0,'t'))
		if locaddr or locport then
			assert(skt:bind(locaddr, locport))
		end
		local res, err = skt:connect(address, port)
		if err ~= 'timeout' then
			return res ~= nil and loop.wrap(skt) or res,err
		end
		wait(write,skt)
		local res, err = skt:connect(address, port)
		if res or err == 'already connected' then
			return loop.wrap(skt)
		else
			return res ~= nil and loop.wrap(skt) or res,err
		end
	end
	local function wake(skt,rwt)
		local thread = rwt[skt]
		if not thread then return end
		assert(coroutine.resume(thread))
		if coroutine.status(thread) == 'dead' then
			if not read[skt] and not write[skt] then
				skt:close()
			end
		end
	end
	function loop.dispatch(timeout)
		if not next(read) and not next(write) then return end
		local reads, writes, err = glue.keys(read), glue.keys(write)
		reads, writes, err = socket.select(reads, writes, timeout)
		for i=1,#reads do wake(reads[i], read) end
		for i=1,#writes do wake(writes[i], write) end
		return true
	end
	local stop = false
	function loop.stop() stop = true end
	function loop.start(timeout)
		while loop.dispatch(timeout) do
			if stop then break end
		end
	end
	function loop.newthread(handler,...)
		assert(coroutine.resume(coroutine.create(handler),...))
	end
	function loop.newserver(host, port, handler)
		local server_skt = socket.tcp()
		server_skt:settimeout(0)
		assert(server_skt:bind(host, port))
		assert(server_skt:listen(1024*16))
		server_skt = loop.wrap(server_skt)
		local function server()
			while true do
				local client_skt = server_skt:accept()
				loop.newthread(handler, client_skt)
			end
		end
		loop.newthread(server)
	end
	return loop
end
