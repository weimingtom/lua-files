
for k=1,1 do
	for i=0,4 do
		local scale = 10^i
		print(1/1.66)
		local sweep = math.sqrt(1/scale^(1/1.66)) * 40
		--local sweep = 1/2^math.log10(scale) * 40
		print(scale, sweep)
	end
end

