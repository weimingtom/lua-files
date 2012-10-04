socket_loop = require'socket_loop'
--_G.say = function() end --sayto('SOCKLOOP')
sayto_stdout()
local n=0
local function handler(skt, loop)
	n=n+1
	say('\n\n\nhandling', skt)
	--socket.sleep(1)
	--while true do
		local s, err = loop.receive(skt)
		if not s then print('closed') return end
		print('got', s)
		print('sending')
		loop.send(skt, 'hi there')
		print('sent',n)
		--loop.close(skt)
	--end
	n=n-1
end
socket_loop.newserver('localhost', 1234, handler)
socket_loop.mainloop.loop()
