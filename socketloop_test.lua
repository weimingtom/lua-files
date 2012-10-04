
local lanes = require'lanes'
if rawget(lanes, 'configure') then lanes.configure() end
say = sayto'main'

local linda = lanes.linda()
linda:set('clients_served', 0)

local function reverse_echo_server(port)
	require'u'
	require'sktloop'
	--sktloop.say = sayto'server'
	local hcount = 0
	local function handler(skt, loop)
		hcount = hcount + 1
		while true do
			local line = loop.receive(skt, '*l')
			if line == 'close' then
				linda:set('clients_served', linda:get('clients_served') + 1)
				break
			end
			loop.send(skt, line:reverse() .. '\n')
		end
		hcount = hcount - 1
	end
	sktloop.newserver('localhost', port, handler)
	while sktloop.mainloop.dispatch(1) do
		if linda:get('stop') then
			if hcount == 0 then break end
		end
	end
end

local function client_multi_conn(server_port)
	require'u'
	require'sktloop'
	--sktloop.say = sayto'client'
	local function client()
		local skt,err = sktloop.mainloop.connect('localhost', server_port)
		if not skt then say(err) return end
		local s = 'duuude'
		sktloop.mainloop.send(skt, s .. '\n')
		local ss = sktloop.mainloop.receive(skt, '*l')
		assert(ss == s:reverse())
		sktloop.mainloop.send(skt, 'close\n')
	end
	for i=1,10 do
		sktloop.mainloop.newthread(client)
	end
	while sktloop.mainloop.dispatch(1) do end
end

local server_lane = lanes.gen('*', reverse_echo_server)(1234)
local client_lane_gen = lanes.gen('*', client_multi_conn)

local client_lanes = {}
for i=1,20 do
	ins(client_lanes, client_lane_gen(1234))
end

say('waiting for clients')
for i=1,#client_lanes do
	say('client finished', client_lanes[i][1])
end
say('all clients finished')

linda:set('stop', true)
say('waiting for server')
say('server finished', server_lane[1])
print('clients served', linda:get('clients_served'))


