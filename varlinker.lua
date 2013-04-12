--features:
--

local function varlinker()
	local refs = {}
	local val --forward decl.
	local function var(t,i,setter,...)
		local k = #refs+1
		refs[k] = {t,i,setter,...}
		if setter then
			t[i] = setter(val,...)
		end
		return k
	end
	local function constrain(k,setter,...)
		local t,i = refs[k][1], refs[k][2]
		refs[k] = {t,i,setter,...}
		t[i] = setter(val,...)
	end
	local function get(_,k)
		local t,i = unpack(refs[k])
		return t[i]
	end
	local function set(k,v)
		local t,i,setter = unpack(refs[k])
		t[i] = v
		if setter then
			t[i] = setter(val, unpack(refs[k], 4))
		end
	end

	local linksets = {}
	local function link(linkset, k1, k2, f, ...)
		assert(k1 and k2)
		local deps = linksets[linkset] or {}
		linksets[linkset] = deps
		deps[k1] = deps[k1] or {}
		local dep = f and {f, ...} or {get, k1}
		deps[k1][k2] = dep
	end
	local function expr(linkset, k2, f, ...)
		assert(k2 and f)
		local deps = linksets[linkset] or {}
		linksets[linkset] = deps
		local dep = {f, ...}
		for i=1,select('#', ...) do
			local k1 = assert(select(i,...))
			deps[k1] = deps[k1] or {}
			deps[k1][k2] = dep
		end
	end
	local function update_linkset(linkset, k, v, touched)
		if touched[k] then return end
		set(k,v)
		touched[k] = true
		local dt = linksets[linkset][k]
		if not dt then return end
		for k2,dep in pairs(dt) do
			update_linkset(linkset, k2, dep[1](val, unpack(dep, 2)), touched)
		end
	end

	local function update(_, k, v)
		for linkset in pairs(linksets) do
			update_linkset(linkset, k, v, {})
		end
	end

	val = setmetatable({}, {__index = get, __newindex = update})
	return {
		var = var,
		val = val,
		link = link,
		expr = expr,
		constrain = constrain,
	}
end

if not ... then require'path_editor_demo' end

return varlinker

