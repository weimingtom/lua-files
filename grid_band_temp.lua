
--stateless top-down navigation

local function right_band(band)
	local pband = band.parent
	if not pband then return end
	if band.index < #pband then
		band = pband[band.index + 1]
		return band, band.index, band.parent
	else
		return right_band(pband)
	end
end

local function next_band(band0, band)
	if not band then
		return band0, band0.index, band0.parent
	end
	if #band > 0 then
		band = band[1]
		return band, band.index, band.parent
	else
		return right_band(band)
	end
end

local function bands_top_down_static(band)
	return next_band, band
end

--stateful top-down navigation

local function walk_bands_top_down(f, band, i, pband)
	f(band, pband, i)
	for i,cband in ipairs(band) do
		walk_bands_top_down(f, cband, i, band)
	end
end

local function bands_top_down(band, i, pband)
	return coroutine.wrap(function()
		walk_bands_top_down(coroutine.yield, band, i, pband)
	end)
end

--stateful bottom-up navigation

local function walk_bands_bottom_up(f, band, i, pband)
	for i,cband in ipairs(band) do
		walk_bands_bottom_up(f, cband, i, ban)
	end
	f(band, i, pband)
end

local function bands_bottom_up(band, i, pband)
	return coroutine.wrap(function()
		walk_bands_bottom_up(coroutine.yield, band, i, pband)
	end)
end

local function band_total_rows(band) --cummulated number of rows of a band
	local crows = 0
	for i, cband in ipairs(band) do
		crows = math.max(crows, band_total_rows(cband))
	end
	return (band.rows or 1) + crows
end
