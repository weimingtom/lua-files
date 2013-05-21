//go@ bash build-mingw32.sh
//Clipper C wrapper by Cosmin Apreutesei (unlicensed)
#include "clipper.cpp"

using namespace ClipperLib;

typedef struct { int64_t x, y; } clipper_point;

#define export extern "C" __declspec (dllexport)

export Polygon* clipper_create_polygon(int n) {
	return new Polygon(n);
}

export void clipper_free_polygon(Polygon* data) {
	delete data;
}

export int clipper_polygon_get_size(Polygon* data) {
	return data->size();
}

export clipper_point* clipper_polygon_get_data(Polygon* data) {
	return (clipper_point*) &((*(data))[0]);
}

export Polygons* clipper_create_polygons(int n) {
	return new Polygons(n);
}

export void clipper_free_polygons(Polygons* data) {
	delete data;
}

export int clipper_polygons_get_size(Polygons* data) {
	return data->size();
}

export Polygon* clipper_polygons_get_data(Polygons* data) {
	return (Polygon*) &((*(data))[0]);
}

export int clipper_orientation(Polygon* data) {
	return Orientation(*data);
}

export double clipper_area(Polygon* data) {
	return Area(*data);
}

export Polygons* clipper_simplify_polygon(Polygon* data, PolyFillType fill_type) {
	Polygons* out = new Polygons();
	SimplifyPolygon(*data, *out, PolyFillType(fill_type));
	return out;
}

export Polygons* clipper_simplify_polygons(Polygons* data, PolyFillType fill_type) {
	Polygons* out = new Polygons();
	SimplifyPolygons(*data, *out, PolyFillType(fill_type));
	return out;
}

export Polygon* clipper_clean_polygon(Polygon* data, double distance) {
	Polygon* out = new Polygon();
	CleanPolygon(*data, *out, distance);
	return out;
}

export Polygons* clipper_clean_polygons(Polygons* data, double distance) {
	Polygons* out = new Polygons();
	CleanPolygons(*data, *out, distance);
	return out;
}

export Polygons* clipper_offset_polygons(Polygons* data, double delta, JoinType jointype, double miter_limit) {
	Polygons* out = new Polygons();
	OffsetPolygons(*data, *out, delta, JoinType(jointype), miter_limit, false);
	return out;
}

export void clipper_reverse_polygon(Polygon* data) {
	ReversePolygon(*data);
}

export void clipper_reverse_polygons(Polygons* data) {
	ReversePolygons(*data);
}

export Clipper* clipper_create_clipper() {
	return new Clipper();
}

export void clipper_free_clipper(Clipper* clipper) {
	delete clipper;
}

export int clipper_add_polygon(Clipper* clipper, Polygon* data, PolyType poly_type) {
	clipper->AddPolygon(*data, PolyType(poly_type));
}

export int clipper_add_polygons(Clipper* clipper, Polygons* data, PolyType poly_type) {
	clipper->AddPolygons(*data, PolyType(poly_type));
}

export void clipper_get_bounds(Clipper* clipper, IntRect* out) {
	out[0] = clipper->GetBounds();
}

export Polygons* clipper_execute(Clipper* clipper, ClipType clipType,
									PolyFillType subjFillType,
									PolyFillType clipFillType) {
	Polygons* solution = new Polygons();
	clipper->Execute(ClipType(clipType), *solution,
										PolyFillType(subjFillType),
										PolyFillType(clipFillType));
	return solution;
}

export void clipper_clear(Clipper* clipper) {
	clipper->Clear();
}

export int clipper_get_reverse_solution(Clipper* clipper) {
	return clipper->ReverseSolution();
}

export void clipper_set_reverse_solution(Clipper* clipper, int reverse) {
	clipper->ReverseSolution(reverse);
}

