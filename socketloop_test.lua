local lanes = require'lanes'
lanes.configure()

local function log(...) print(...) end
local function logto(s) return function(...) return log(s,...) end end

local linda = lanes.linda()
linda:set('clients_served', 0)

local function reverse_echo_server(port)
	local socketloop = require'socketloop'
	local loop = socketloop(logto'server')
	local hcount = 0
	local function handler(skt)
		hcount = hcount + 1
		while true do
			local line = skt:receive'*l'
			if line == 'close' then
				linda:set('clients_served', linda:get('clients_served') + 1)
				break
			end
			skt:send(line:reverse() .. '\n')
		end
		hcount = hcount - 1
	end
	loop.newserver('localhost', port, handler)
	while loop.dispatch(1) do
		if linda:get('stop') then
			if hcount == 0 then break end
		end
	end
end

local function client_multi_conn(server_port)
	local socketloop = require'socketloop'
	local loop = socketloop(logto'client')
	local function client()
		local skt,err = loop.connect('localhost', server_port)
		if not skt then log(err) return end
		local s = 'duuude'
		skt:send(s .. '\n')
		local ss = skt:receive'*l'
		assert(ss == s:reverse())
		skt:send'close\n'
	end
	for i=1,50 do
		loop.newthread(client)
	end
	loop.start(1)
end

local server_lane = lanes.gen('*', reverse_echo_server)(1234)
local client_lane_gen = lanes.gen('*', client_multi_conn)

local client_lanes = {}
for i=1,10 do
	client_lanes[i] = client_lane_gen(1234)
end

log('waiting for clients')
for i=1,#client_lanes do
	select(1, client_lanes[i][1])
	log('client finished')
end
log('all clients finished')

linda:set('stop', true)
log('waiting for server')
select(1, server_lane[1])
log('server finished')
log('clients served', linda:get('clients_served'))


