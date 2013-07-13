--bitmap blending submodule. loaded automatically on-demand by the bitmap module.
local bitmap = require'bitmap'

local op = {}

function op.clear    (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return 0, 0, 0, 0 end
function op.src      (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Sr, Sg, Sb, Sa end
function op.dst      (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Dr, Dg, Db, Da end

local function clip(x, max)
	return math.min(math.max(x, 0), max)
end

function op.src_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		clip(Sr + (max - Sa) * Dr, max),
		clip(Sg + (max - Sa) * Dg, max),
		clip(Sb + (max - Sa) * Db, max),
		clip(Sa + Da - Sa * Da, max)
end

function op.dst_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Dr + (max - Da) * Sr,
		Dg + (max - Da) * Sg,
		Db + (max - Da) * Sb,
		Sa + Da - Sa * Da
end

function op.src_in   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * Da,
		Sg * Da,
		Sb * Da,
		Sa * Da
end

function op.dst_in   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sa * Dr,
		Sa * Dg,
		Sa * Db,
		Sa * Da
end

function op.src_out  (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * (max - Dr),
		Sg * (max - Dg),
		Sb * (max - Db),
		Sa * (max - Da)
end

function op.dst_out  (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Dr * (max - Sa),
		Dg * (max - Sa),
		Db * (max - Sa),
		Da * (max - Sa)
end

function op.src_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * Da + (max - Sa) * Dr,
		Sg * Da + (max - Sa) * Dg,
		Sb * Da + (max - Sa) * Db,
		Da
end

function op.dst_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sa * Dr + Sr * (max - Da),
		Sa * Dg + Sg * (max - Da),
		Sa * Db + Sb * (max - Da),
		Sa
end

function op.xor      (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * (max - Da) + (max - Sa) * Dr,
		Sg * (max - Da) + (max - Sa) * Dg,
		Sb * (max - Da) + (max - Sa) * Db,
		Sa + Da - 2 * Sa * Da
end

function op.darken   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * (max - Da) + Dc * (max - Sa) + math.min(Sr, Dr),
		Sg * (max - Da) + Dc * (max - Sa) + math.min(Sg, Dg),
		Sb * (max - Da) + Dc * (max - Sa) + math.min(Sb, Db),
		Sa + Da - Sa * Da
end

function op.lighten  (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * (max - Da) + Dc * (max - Sa) + math.max(Sr, Dr),
		Sg * (max - Da) + Dc * (max - Sa) + math.max(Sg, Dg),
		Sb * (max - Da) + Dc * (max - Sa) + math.max(Sb, Db),
		Sa + Da - Sa * Da
end

function op.modulate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr * Dr,
		Sg * Dg,
		Sb * Db,
		Sa * Da
end

function op.screen   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	return
		Sr + Dr - Sr * Dr,
		Sg + Dg - Sg * Dg,
		Sb + Db - Sb * Db,
		Sa + Da - Sa * Da
end

function op.add      (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	Da = math.min(max, Sa + Da)
	return
		(Sr + Dr) / Da,
		(Sg + Dg) / Da,
		(Sb + Db) / Da,
		Da
end

function op.saturate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max)
	local Za = math.min(Sa, max - Da)
	Da = math.min(max, Sa + Da)
	return
		(Za * Sr + Dr) / Da,
		(Za * Sg + Dg) / Da,
		(Za * Sb + Db) / Da,
		Da
end

function bitmap.blend(src, dst, operator)
	local src_colortype = bitmap.colortype(src)
	local dst_colortype = bitmap.colortype(dst)
	assert(#src_colortype.channels == 4, 'invalid colortype')
	assert(src_colortype == dst_colortype, 'different colortypes')
	local operator = assert(op[operator], 'invalid operator')
	local maxval = src_colortype.max
	local src_getpixel = bitmap.pixel_interface(src)
	local dst_getpixel, dst_setpixel = bitmap.pixel_interface(dst)
	for y = 0, src.h-1 do
		for x = 0, src.w-1 do
			local Sr, Sg, Sb, Sa = src_getpixel(x, y)
			local Dr, Dg, Db, Da = dst_getpixel(x, y)
			dst_setpixel(x, y, operator(Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, maxval))
		end
	end
end

