--bitmap porter-duff blending submodule. loaded automatically on-demand by the bitmap module.
--TODO: should I bother implementing an integer-only fast variant for 8bpc rgba types?
local bitmap = require'bitmap'

local op = {}

function op.clear (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return 0, 0, 0, 0 end
function op.src   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Sr, Sg, Sb, Sa end
function op.dst   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Dr, Dg, Db, Da end

function op.src_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr + (1 - Sa) * Dr,
		Sg + (1 - Sa) * Dg,
		Sb + (1 - Sa) * Db,
		Sa + Da - Sa * Da
end

function op.dst_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Dr + (1 - Da) * Sr,
		Dg + (1 - Da) * Sg,
		Db + (1 - Da) * Sb,
		Sa + Da - Sa * Da
end

function op.src_in (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Da,
		Sg * Da,
		Sb * Da,
		Sa * Da
end

function op.dst_in (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sa * Dr,
		Sa * Dg,
		Sa * Db,
		Sa * Da
end

function op.src_out (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Dr),
		Sg * (1 - Dg),
		Sb * (1 - Db),
		Sa * (1 - Da)
end

function op.dst_out (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Dr * (1 - Sa),
		Dg * (1 - Sa),
		Db * (1 - Sa),
		Da * (1 - Sa)
end

function op.src_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Da + (1 - Sa) * Dr,
		Sg * Da + (1 - Sa) * Dg,
		Sb * Da + (1 - Sa) * Db,
		Da
end

function op.dst_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sa * Dr + Sr * (1 - Da),
		Sa * Dg + Sg * (1 - Da),
		Sa * Db + Sb * (1 - Da),
		Sa
end

function op.xor (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Da) + (1 - Sa) * Dr,
		Sg * (1 - Da) + (1 - Sa) * Dg,
		Sb * (1 - Da) + (1 - Sa) * Db,
		Sa + Da - 2 * Sa * Da
end

function op.darken (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Da) + Dc * (1 - Sa) + math.min(Sr, Dr),
		Sg * (1 - Da) + Dc * (1 - Sa) + math.min(Sg, Dg),
		Sb * (1 - Da) + Dc * (1 - Sa) + math.min(Sb, Db),
		Sa + Da - Sa * Da
end

function op.lighten (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Da) + Dc * (1 - Sa) + math.max(Sr, Dr),
		Sg * (1 - Da) + Dc * (1 - Sa) + math.max(Sg, Dg),
		Sb * (1 - Da) + Dc * (1 - Sa) + math.max(Sb, Db),
		Sa + Da - Sa * Da
end

function op.modulate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Dr,
		Sg * Dg,
		Sb * Db,
		Sa * Da
end

function op.screen (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr + Dr - Sr * Dr,
		Sg + Dg - Sg * Dg,
		Sb + Db - Sb * Db,
		Sa + Da - Sa * Da
end

function op.add (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	Da = math.min(1, Sa + Da)
	return
		(Sr + Dr) / Da,
		(Sg + Dg) / Da,
		(Sb + Db) / Da,
		Da
end

function op.saturate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	local Za = math.min(Sa, 1 - Da)
	Da = math.min(1, Sa + Da)
	return
		(Za * Sr + Dr) / Da,
		(Za * Sg + Dg) / Da,
		(Za * Sb + Db) / Da,
		Da
end

function bitmap.blend(src, dst, operator)
	local operator = assert(op[operator], 'invalid operator')
	local src_getpixel = bitmap.pixel_interface(src, 'rgbaf')
	local dst_getpixel, dst_setpixel = bitmap.pixel_interface(dst, 'rgbaf')
	for y = 0, src.h-1 do
		for x = 0, src.w-1 do
			local Sr, Sg, Sb, Sa = src_getpixel(x, y)
			local Dr, Dg, Db, Da = dst_getpixel(x, y)
			dst_setpixel(x, y, operator(Sr, Sg, Sb, Sa, Dr, Dg, Db, Da))
		end
	end
end


if not ... then require'bitmap_demo' end

