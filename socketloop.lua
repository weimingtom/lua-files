socket = require'socket'
glue = require'glue'

say = identity

local function fmt(v)
	local t,p = tostring(v):match('{(.).-}: (.*)$')
	return t..p
end
local function fmtth(v)
	return 't'..tostring(v):match(': (.*)$')
end
local function fmtt(t)
	return cat(filter(fmt, t), ', ')
end

function wrap(skt, loop)
	local o = {}
	function o:accept(...) return loop.accept(skt,...) end
	function o:receive(...) return loop.receive(skt,...) end
	function o:send(...) return loop.send(skt,...) end
	function o:close(...) return loop.close(skt,...) end
	return o
end

function newloop()
	local read, write, o = {}, {}, {} --read/write: {skt: thread}
	local function wait(rwt,skt)
		rwt[skt] = coroutine.running()
		coroutine.yield()
		rwt[skt] = nil
	end
	function o.connect(address, port, locaddr, locport)
		local skt = assert(socket.tcp())
		assert(skt:settimeout(0,'b'))
		assert(skt:settimeout(0,'t'))
		if locaddr or locport then
			assert(skt:bind(locaddr, locport))
		end
		say('connect', fmt(skt), address, port, locaddr, locport)
		local res, err = skt:connect(address, port)
		if err ~= 'timeout' then
			say('connect-result', fmt(skt), res, err)
			return res ~= nil and skt or res,err
		end
		wait(write,skt)
		say('connect-again', fmt(skt))
		local res, err = skt:connect(address, port)
		if res or err == 'already connected' then
			say('connected', fmt(skt))
			return skt
		else
			say('connect-again-result', fmt(skt), res, err)
			return res ~= nil and skt or res,err
		end
	end
	function o.accept(skt,...)
		wait(read,skt)
		say('accept',fmt(skt),...)
		return assert(skt:accept(...))
	end
	function o.receive(skt,...)
		wait(read,skt)
		say('receive',fmt(skt),...)
		s = assert(skt:receive(...))
		say('received', s)
		return s
	end
	function o.send(skt,...)
		wait(write,skt)
		say('send',fmt(skt),...)
		return assert(skt:send(...))
	end
	function o.close(skt,...)
		write[skt] = nil
		read[skt] = nil
		say('close',fmt(skt),...)
		return assert(skt:close(...))
	end
	local function wake(skt,rwt)
		local thread = rwt[skt]
		if not thread then return end
		say('wake', fmtth(thread), coroutine.status(thread))
		assert(coroutine.resume(thread))
		if coroutine.status(thread) == 'dead' then
			say('dead', fmtth(thread))
			if not read[skt] and not write[skt] then
				o.close(skt)
			end
		end
	end
	function o.dispatch(timeout)
		if not next(read) and not next(write) then return end
		local reads, writes, err = keys(read), keys(write)
		say('waiting', #reads, #writes)--, fmtt(reads), fmtt(writes))
		reads, writes, err = socket.select(reads, writes, timeout)
		say('ready', #reads, #writes)--, fmtt(reads), fmtt(writes), err)
		for i=1,#reads do wake(reads[i], read) end
		for i=1,#writes do wake(writes[i], write) end
		return true
	end
	local stop = false
	function o.stop() stop = true end
	function o.loop(timeout)
		while o.dispatch(timeout) do
			if stop then break end
		end
	end
	function o.newthread(handler,...)
		assert(coroutine.resume(coroutine.create(handler),...))
	end
	return o
end

mainloop = newloop()

function newserver(host, port, handler, loop)
	loop = loop or mainloop
	local server_skt = socket.tcp()
	server_skt:settimeout(0)
	assert(server_skt:bind(host, port))
	assert(server_skt:listen(1024*16))
	local function server()
		while true do
			client_skt = loop.accept(server_skt)
			loop.newthread(handler, client_skt, loop)
		end
	end
	loop.newthread(server)
end


