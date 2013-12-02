--color conversions, ripped from Sputnik (MIT/X License)

--color module: contains standalone functions and the color object constructor

local color_module = {}
local color_module_mt = {}
setmetatable(color_module, color_module_mt)

local function clamp(x)
	return math.min(math.max(x, 0), 1)
end

local function _h2rgb(m1, m2, h)
	if h<0 then h = h+1 end
	if h>1 then h = h-1 end
	if h*6<1 then
		return m1+(m2-m1)*h*6
	elseif h*2<1 then
		return m2
	elseif h*3<2 then
		return m1+(m2-m1)*(2/3-h)*6
	else
		return m1
	end
end

--hsl is clamped to (0..360, 0..1, 0..1); rgb is (0..1, 0..1, 0..1)
function color_module.hsl_to_rgb(h, s, L)
	h = (h % 360) / 360
	local m1, m2
	if L<=0.5 then
		m2 = L*(s+1)
	else
		m2 = L+s-L*s
	end
	m1 = L*2-m2
	return
		clamp(_h2rgb(m1, m2, h+1/3)),
		clamp(_h2rgb(m1, m2, h)),
		clamp(_h2rgb(m1, m2, h-1/3))
end

--rgb is clamped to (0..1, 0..1, 0..1); hsl is (0..360, 0..1, 0..1)
function color_module.rgb_to_hsl(r, g, b)
	r, g, b = clamp(r), clamp(g), clamp(b)
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local h, s, l = 0, 0, ((min+max)/2)

	if l > 0 and l < 0.5 then s = delta/(max+min) end
	if l >= 0.5 and l < 1 then s = delta/(2-max-min) end

	if delta > 0 then
		if max == r and max ~= g then h = h + (g-b)/delta end
		if max == g and max ~= b then h = h + 2 + (b-r)/delta end
		if max == b and max ~= r then h = h + 4 + (r-g)/delta end
		h = h / 6;
	end

	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end

	return h * 360, s, l
end

--color class

local color = {}
local color_mt = {__index = color}

local function rgb_string_to_hsl(rgb)
	return color.rgb_to_hsl(tonumber(rgb:sub(2,3), 16)/256,
									tonumber(rgb:sub(4,5), 16)/256,
									tonumber(rgb:sub(6,7), 16)/256)
end

local function new(self, H, S, L) --either H, S, L (0..360, 0..1, 0..1) or RGB string '#rrggbb'
	if type(H) == "string" and H:sub(1,1)=="#" and H:len() == 7 then
		H, S, L = rgb_string_to_hsl(H)
	else
		H, S, L = H % 360, clamp(S), clamp(L)
	end
	return setmetatable({H = H, S = S, L = L}, color_mt)
end

color_module_mt.__call = new

function color:hsl()
	return self.H, self.S, self.L
end

function color:rgb()
	return color_module.hsl_to_rgb(self:hsl())
end

function color:rgba()
	local r, g, b = color_module.hsl_to_rgb(self:hsl())
	return r, g, b, 1
end

function color:tostring()
	local r, g, b = self:rgb()
	return string.format("#%02x%02x%02x",
		math.floor(r*256 + 0.5),
		math.floor(g*256 + 0.5),
		math.floor(b*256 + 0.5))
end

color_mt.__tostring = color.tostring

function color:hue_offset(delta)
	return new(nil, (self.H + delta) % 360, self.S, self.L)
end

function color:complementary()
	return self:hue_offset(180)
end

function color:neighbors(angle)
	local angle = angle or 30
	return self:hue_offset(angle), self:hue_offset(360-angle)
end

function color:triadic()
	return self:neighbors(120)
end

function color:split_complementary(angle)
	return self:neighbors(180-(angle or 30))
end

function color:desaturate_to(saturation)
	return new(nil, self.H, saturation, self.L)
end

function color:desaturate_by(r)
	return new(nil, self.H, self.S*r, self.L)
end

function color:lighten_to(lightness)
	return new(nil, self.H, self.S, lightness)
end

function color:lighten_by(r)
	return new(nil, self.H, self.S, self.L*r)
end

function color:variations(f, n)
	n = n or 5
	local results = {}
	for i=1,n do
	  table.insert(results, f(self, i, n))
	end
	return results
end

function color:tints(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L + (1-color.L)/n*i)
	end, n)
end

function color:shades(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L - (color.L)/n*i)
	end, n)
end

function color:tint(r)
	return self:lighten_to(self.L + (1-self.L)*r)
end

function color:shade(r)
	return self:lighten_to(self.L - self.L*r)
end


if not ... then require'color_demo' end


return color_module
