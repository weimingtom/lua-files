--2d affine matrix class transcribed from cairo

local matrix = {}
local matrix_mt = {__index = matrix}

function matrix:reset(xx, yx, xy, yy, x0, y0)
	self.xx = xx
	self.yx = yx
	self.xy = xy
	self.yy = yy
	self.x0 = x0
	self.y0 = y0
	return self
end

function matrix:identity()
	return self:reset(1,0,0,1,0,0)
end

function matrix:new(...)
	local m = setmetatable({}, matrix_mt)
	if ... then return m:reset(...) else return m:identity() end
end

function matrix:unpack()
	return self.xx, self.yx, self.xy, self.yy, self.x0, self.y0
end

function matrix:copy()
	return matrix:new(self:unpack())
end

function matrix:transform(x, y)
	return self.xx * x + self.xy * y + self.x0,
			 self.yx * y + self.yy * y + self.y0
end

function matrix:transform_distance(x, y)
	return self.xx * x + self.xy * y,
			 self.yx * y + self.yy * y
end

function matrix:multiply(xx, yx, xy, yy, x0, y0)
	 return self:reset(
				 xx * self.xx + yx * self.xy,
				 xx * self.yx + yx * self.yy,
				 xy * self.xx + yy * self.xy,
				 xy * self.yx + yy * self.yy,
				 x0 * self.xx + y0 * self.xy + self.x0,
				 x0 * self.yx + y0 * self.yy + self.y0)
end

function matrix:determinant()
	local a,b,c,d = self:unpack()
	return a*d-b*c
end

function matrix:scalar_multiply(scalar)
	self.xx = self.xx * scalar
	self.yx = self.yx * scalar
	self.xy = self.xy * scalar
	self.yy = self.yy * scalar
   self.x0 = self.x0 * scalar
   self.y0 = self.y0 * scalar
	return self
end

function matrix:inverse()
	self = self:copy()
	--shortcut: invert scaling/translation matrices
	if self.xy == 0 and self.yx == 0 then
		self.x0 = -self.x0
		self.y0 = -self.y0

		if self.xx ~= 1 then
			if self.xx == 0 then return end
			self.xx = 1 / self.xx
			self.x0 = self.x0 * self.xx
		end
		if self.yy ~= 1 then
			if self.yy == 0 then return end
			self.yy = 1 / self.yy
			self.y0 = self.y0 * self.yy
		end
		return self
	end
	--inv (A) = 1/det (A) * adj (A)
	local det = self:determinant()
	if det == 0 or det == math.huge or det == -math.huge then return end
	--adj (A) = transpose (C:cofactor (A,i,j))
	local a, b, c, d, tx, ty = self:unpack()
   self:reset(d, -b, -c, a, c*ty - d*tx, b*tx - a*ty)
	return self:scalar_multiply(1/det)
end

function matrix:is_invertible()
	local det = self:determinant()
	return det ~= 0 and det ~= math.huge and det ~= -math.huge
end

function matrix:translate(x,y)
	self.x0 = self.x0 + x
	self.y0 = self.y0 + y
	return self
end

function matrix:scale(x,y)
	self.xx = self.xx * x
	self.yy = self.yy * y
	return self
end

function matrix:skew(ax,ay)
	return self:multiply(1, math.tan(ay), math.tan(ax), 1, 0, 0)
end

function matrix:rotate(a)
    local s = math.sin(a)
    local c = math.cos(a)
    return self:multiply(c, s, -s, c, 0, 0)
end

function matrix:has_unity_scale()
	if self.xy == 0 and self.yx == 0 then
		if not (self.xx == 1 or self.xx == -1) then return false end
		if not (self.yy == 1 or self.yy == -1) then return false end
	elseif self.xx == 0 and self.yy == 0 then
		if not (self.xy == 1 or self.xy == -1) then return false end
		if not (self.yx == 1 or self.yx == -1) then return false end
	else
		return false
	end
	return true
end

function matrix:is_pixel_perfect() --means pixels map 1:1 with this transform so no filtering necessary
	return self:has_unity_scale() and math.floor(self.x0) == self.x0 and math.floor(self.y0) == self.y0
end

return matrix
