local ffi = require'ffi'
local C = ffi.load'clipper'

ffi.cdef[[
typedef struct { int64_t x, y; } clipper_point;
typedef struct { int64_t x1, y1, x2, y2; } clipper_rect;

typedef enum {
	clipper_ctIntersection,
	clipper_ctUnion,
	clipper_ctDifference,
	clipper_ctXor
} clipper_ClipType;

typedef enum {
	clipper_ptSubject,
	clipper_ptClip
} clipper_PolyType;

typedef enum {
	clipper_pftEvenOdd,
	clipper_pftNonZero,
	clipper_pftPositive,
	clipper_pftNegative
} clipper_PolyFillType;

typedef enum {
	clipper_jtSquare,
	clipper_jtRound,
	clipper_jtMiter
} clipper_JoinType;

typedef struct clipper_Polygon clipper_polygon_t;
typedef struct clipper_Polygons clipper_polygons_t;
typedef struct clipper_Clipper clipper_t;

clipper_polygon_t* clipper_create_polygon(int);
void clipper_free_polygon(clipper_polygon_t*);

int clipper_polygon_get_size(clipper_polygon_t*);
clipper_point* clipper_polygon_get_data(clipper_polygon_t*);

clipper_polygons_t* clipper_create_polygons(int n);
void clipper_free_polygons(clipper_polygons_t*);

int clipper_polygons_get_size(clipper_polygons_t*);
clipper_polygon_t* clipper_polygons_get_data(clipper_polygons_t*);

int clipper_orientation(clipper_polygon_t*);
double clipper_area(clipper_polygon_t*);

clipper_polygons_t* clipper_simplify_polygon(clipper_polygon_t*, clipper_PolyFillType fillType);
clipper_polygons_t* clipper_simplify_polygons(clipper_polygons_t*, clipper_PolyFillType fillType);
clipper_polygon_t* clipper_clean_polygon(clipper_polygon_t*, double);
clipper_polygons_t* clipper_clean_polygons(clipper_polygons_t*, double);
clipper_polygons_t* clipper_offset_polygons(clipper_polygons_t*, double, clipper_JoinType, double);
void clipper_reverse_polygon(clipper_polygon_t*);
void clipper_reverse_polygons(clipper_polygons_t*);

clipper_t* clipper_create_clipper();
void clipper_free_clipper(clipper_t*);

int clipper_add_polygon(clipper_t*, clipper_polygon_t*, clipper_PolyType);
int clipper_add_polygons(clipper_t*, clipper_polygons_t*, clipper_PolyType);
void clipper_get_bounds(clipper_t*, clipper_rect*);
clipper_polygons_t* clipper_execute(clipper_t*, clipper_ClipType, clipper_PolyFillType, clipper_PolyFillType);
void clipper_clear(clipper_t*);
int clipper_get_reverse_solution(clipper_t*);
void clipper_set_reverse_solution(clipper_t*, int);
]]

local fill_types = {
	even_odd = C.clipper_pftEvenOdd,
	non_zero = C.clipper_pftNonZero,
	positive = C.clipper_pftPositive,
	negative = C.clipper_pftNegative,
}

local join_types = {
	square = C.clipper_jtSquare,
	round  = C.clipper_jtRound,
	miter  = C.clipper_jtMiter,
}

local clip_types = {
	intersection = C.clipper_ctIntersection,
	union        = C.clipper_ctUnion,
	difference   = C.clipper_ctDifference,
	xor          = C.clipper_ctXor
}

local polygon = {}

function polygon.new(n)
	return ffi.gc(C.clipper_create_polygon(n or 0), C.clipper_free_polygon)
end

function polygon:free()
	C.clipper_free_polygon(self)
	ffi.gc(self, nil)
end

function polygon:size()
	return C.clipper_polygon_get_size(self)
end

function polygon:points()
	return C.clipper_polygon_get_data(self)
end

function polygon:orientation()
	return C.clipper_orientation(self) == 1
end

polygon.area = C.clipper_area

function polygon:simplify(fill_type)
	return ffi.gc(C.clipper_simplify_polygon(self, fill_types[fill_type or 'even_odd']),
						C.clipper_free_polygons)
end

function polygon:clean()
	return ffi.gc(C.clipper_clean_polygon(self), C.clipper_free_polygon)
end

polygon.reverse = C.clipper_reverse_polygon

ffi.metatype('clipper_polygon_t', {__index = polygon})


local polygons = {}

function polygons.new(n)
	return ffi.gc(C.clipper_create_polygons(n or 0), C.clipper_free_polygons)
end

function polygons:free()
	C.clipper_free_polygons(self)
	ffi.gc(self, nil)
end

function polygons:size()
	return C.clipper_polygons_get_size(self)
end

function polygons:polygons()
	return C.clipper_polygons_get_data(self)
end

function polygons:simplify(fill_type)
	return ffi.gc(C.clipper_simplify_polygons(self, fill_types[fill_type or 'even_odd']),
						C.clipper_free_polygons)
end

function polygons:clean()
	return ffi.gc(C.clipper_clean_polygons(self), C.clipper_free_polygons)
end

function polygons:offset(delta, join_type, limit)
	return ffi.gc(C.clipper_offset_polygons(self, delta,
						join_types[join_type or 'square'],
						limit or 0), C.clipper_free_polygons)
end

polygons.reverse = C.clipper_reverse_polygons

ffi.metatype('clipper_polygons_t', {__index = polygons})


local clipper = {} --clipper methods

function clipper.new()
	return ffi.gc(C.clipper_create_clipper(), C.clipper_free_clipper)
end

function clipper:free()
	C.clipper_free_clipper(self)
	ffi.gc(self, nil)
end

local function clipper_add(self, poly, poly_type)
	if ffi.istype('clipper_polygon_t*', poly) then
		C.clipper_add_polygon(self, poly, poly_type)
	else
		C.clipper_add_polygons(self, poly, poly_type)
	end
end

function clipper:add_subject(poly) clipper_add(self, poly, C.clipper_ptSubject) end
function clipper:add_clip(poly) clipper_add(self, poly, C.clipper_ptClip) end

function clipper:get_bounds(r)
	local r = r or ffi.new'clipper_rect'
	C.clipper_get_bounds(self, r)
	return r.x1, r.y1, r.x2, r.y2
end

function clipper:execute(clip_type, subj_fill_type, clip_fill_type)
	return ffi.gc(C.clipper_execute(self,
						clip_types[clip_type],
						fill_types[subj_fill_type or 'even_odd'],
						fill_types[clip_fill_type or 'even_odd']), C.clipper_free_polygons)
end

clipper.clear = C.clipper_clear
clipper.get_reverse_solution = C.clipper_get_reverse_solution
clipper.set_reverse_solution = C.clipper_set_reverse_solution

ffi.metatype('clipper_t', {__index = clipper})

if not ... then require'clipper_demo' end

return {
	new = clipper.new,
	polygon = polygon.new,
	polygons = polygons.new,
	C = C,
}

