--pdf generator
local glue = require'glue'
local streams = require'streams'

local function PDF(write, page_width, page_height)

	--low-level formatting

	local offset = 0 --keep track of current byte offset for building the xref table
	local function S(s)
		write(s)
		offset = offset + #s
	end

	local function octal(c)
		return string.format('\\%0.3o', c:byte())
	end
	local function str(s)
		s = s:gsub('([\\%(%)\r\n\t])', octal)
		S'('; S(s); S')\n'
	end

	local function hex(s)
		S'<'; S(glue.tohex(s, true)); S'>\n'
	end

	local min_frac = 1/2^13 --fractions smaller than this format with exponent which pdf doesn't support
	local function num_(n)
		local int,frac = math.modf(n)
		if frac < min_frac then S(tostring(int)) else S(tostring(n)) end
	end
	local function num(n) num_(n); S'\n' end

	local function start_array() S'[\n' end
	local function end_array() S']\n' end

	local function start_dict() S'<<\n' end
	local function end_dict() S'>>\n' end

	local function nums_(...)
		num_(...)
		for i=2,select('#',...) do
			S' '; num_(select(i,...))
		end
	end
	local function nums(...) nums_(...); S'\n' end

	local function numarray_(...) S'['; nums_(...); S']' end
	local function numarray(...) numarray_(...); S'\n' end

	--indirect object creation and referencing and writing of the xref table and trailer

	local objnum = 1
	local offsets = {} --{offset1,...}; record object offsets for building the xref table

	local function new_obj()
		offsets[objnum] = true --object id generated but object not yet created
		objnum = objnum + 1
		return objnum - 1
	end

	local function start_obj(id)
		glue.assert(offsets[id] == true, 'invalid object id %d', id)
		offsets[id] = offset
		num_(id); S' 0 obj\n'
	end

	local function end_obj()
		S'endobj\n'
	end

	local function ref(id)
		glue.assert(offsets[id], 'invalid object id %d', id)
		num_(id); S' 0 R\n'
	end

	local function check_refs()
		local t = {}
		for i=1,#offsets do
			t[#t+1] = offsets[i] == true and i or nil
		end
		if #t > 0 then error('objects not created: '..table.concat(t, ', ')) end
	end

	local xref_offset
	local function xref()
		xref_offset = offset
		S'xref\n1 '; num(#offsets)
		for i=1,#offsets do
			local entry = string.format('%010d %05d n \n', offsets[i], 0)
			assert(#entry == 20)
			S(entry)
		end
	end

	local root_obj_id = new_obj()

	local function trailer()
		S'trailer\n'
		start_dict()
			S'/Root '; ref(root_obj_id)
			S'/Size '; num(#offsets)
		end_dict()
		S'startxref\n'
		num(xref_offset)
		S'%%EOF\n'
	end

	--streams

	local function stream()
		local id = new_obj()
		local length_id = new_obj()
		start_obj(id)
			start_dict()
				S'/Length '; ref(length_id)
			end_dict()
		S'stream\n'
		local start_offset = offset
		return function()
			local length = offset - start_offset
			S'\nendstream\n'
			end_obj()
			start_obj(length_id)
				num(length)
			end_obj()
			return id
		end
	end

	--resource name generation and referencing

	local resnum = 1
	local res_names = {} --{res_obj = res_name}

	local function res_name(t)
		if res_names[t] then return res_names[t] end
		local name = string.format('/R%d', resnum)
		res_names[t] = name
		resnum = resnum + 1
		return name
	end

	--resource creation

	local res_dict_id = new_obj()
	local resources = {} --

	local function res_dict()
		start_obj(res_dict_id)
			start_dict()
				S'/Font '
					start_dict()
						for v,k in pairs(resources) do
							S'/'; S(k); S' '; S(v); S'\n'
						end
					end_dict()
			end_dict()
		end_obj()
	end

	local function set_font(font, size)
		S(res_name(font)); num_(size); S' Tf\n'
	end

	--page objects, the page tree and the root object

	local page_tree_id = new_obj()
	local page_ids = {} --{page_id1, ...}

	local function page(contents_id, rotate, w, h)
		local id = new_obj()
		page_ids[#page_ids+1] = id
		start_obj(id)
			start_dict()
				S'/Type Page\n'
				S'/Parent '; ref(page_tree_id)
				S'/Contents '; ref(contents_id)
				if rotate then S'/Rotate '; num(rotate) end
				if w and h then S'/MediaBox '; numarray(0, 0, w, h) end
			end_dict()
		end_obj()
	end

	local function page_tree()
		start_obj(page_tree_id)
			start_dict()
				S'/Type Pages\n'
				S'/Kids '
					start_array()
						for i=1,#page_ids do
							ref(page_ids[i])
						end
					end_array()
				S'/Count '; num(#page_ids)
				S'/MediaBox '; numarray(0, 0, page_width, page_height)
				S'/Resources '; ref(res_dict_id)
			end_dict()
		end_obj()
	end

	local function root_obj()
		start_obj(root_obj_id)
			start_dict()
				S'/Type Catalog\n'
				S'/Pages '; ref(page_tree_id)
			end_dict()
		end_obj()
	end

	--header, close function and the pdf state object

	S'%PDF-1.4\n%\130\131\132\133\n'

	local function close()
		res_dict()
		page_tree()
		root_obj()
		check_refs()
		xref()
		trailer()
	end

	return {
		--object and stream content formatting API
		S = S,
		str = str,
		hex = hex,
		num = num,
		nums = nums,
		numarray = numarray,
		--object creation and referencing API
		new_obj = new_obj,
		start_obj = start_obj,
		end_obj = end_obj,
		ref = ref,
		--stream creation API
		stream = stream,
		--page creation and document API
		page = page,
		close = close,
	}
end

local function FilePDF(filename, ...)
	local fwrite, f = streams.sink.file(filename)
	local pdf = PDF(fwrite,...)
	local close = pdf.close
	pdf.close = function()
		close()
		f:close()
	end
	return pdf
end

local function StringPDF(...)
	local t = {}
	local writebuf, flush = streams.sink.buffer(streams.sink.table(t))
	local pdf = PDF(writebuf,...)
	local close = pdf.close
	pdf.close = function()
		close()
		flush()
		return table.concat(t)
	end
	return pdf
end

if not ... then require'pdfgen_test' end

return {
	PDF = PDF,
	FilePDF = FilePDF,
	StringPDF = StringPDF,
}
