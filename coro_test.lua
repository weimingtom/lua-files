local coro = require'coro'

coro.transfer(coro.create(function()
	local parent = coro.current
	local thread = coro.create(function()
		print'sub'
	end)
	coro.transfer(thread)
	print'back'
end))
assert(coro.current == coro.main)

coro.transfer(coro.create(function()
	local parent = coro.current
	local thread = coro.wrap(function()
		for i=1,10 do
			coro.transfer(parent, i * i)
		end
	end)
	for s in thread do
		print(s)
	end
end))

