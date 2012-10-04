//go@ bash build.sh
#include "clipper.cpp"
#include "clipper.h"

using namespace ClipperLib;

export polygon_t clipper_create_polygon(double_point_t* points, int n, double scale) {

	polygon_t data = new Polygon(n);

	for(int i=0; i < n; i++) {
		(*data)[i] = IntPoint(points[i].x * scale, points[i].y * scale);
	}

	return data;
}

export void clipper_free_polygon(polygon_t data) {
	delete data;
}

export int clipper_polygon_get_size(polygon_t data) {
	return data->size();
}

export void clipper_save_polygon(polygon_t data, double_point_t* points, double scale) {

	int n = data->size();

	for(int i=0; i < n; i++) {
		points[i].x = (*(Polygon*)data)[i].X / scale;
		points[i].y = (*(Polygon*)data)[i].Y / scale;
	}
}

export int clipper_orientation(polygon_t data) {
	return Orientation(*data);
}

export int clipper_area(polygon_t data) {
	return Area(*data);
}

export polygons_t clipper_simplify_polygon(polygon_t data, clipper_PolyFillType fill_type) {
	polygons_t out = new Polygons();
	SimplifyPolygon(*data, *out, PolyFillType(fill_type));
	return out;
}

export polygons_t clipper_simplify_polygons_new(polygons_t data, clipper_PolyFillType fill_type) {
	polygons_t out = new Polygons();
	SimplifyPolygons(*data, *out, PolyFillType(fill_type));
	return out;
}

export void clipper_simplify_polygons(polygons_t data, clipper_PolyFillType fill_type) {
	SimplifyPolygons(*data, PolyFillType(fill_type));
}

export polygons_t clipper_offset_polygons(polygons_t data, double delta, clipper_JoinType jointype, double miter_limit) {
	polygons_t out = new Polygons();
	OffsetPolygons(*data, *out, delta, JoinType(jointype), miter_limit);
	return out;
}

export void clipper_reverse_polygon(polygon_t data) {
	ReversePolygon(*data);
}

export void clipper_reverse_polygons(polygons_t data) {
	ReversePolygons(*data);
}

export clipper_t clipper_create_clipper() {
	return new Clipper();
}

export void clipper_free_clipper(clipper_t clipper) {
	delete clipper;
}

export int clipper_add_polygon(clipper_t clipper, polygon_t data, clipper_PolyType poly_type) {
	clipper->AddPolygon(*data, PolyType(poly_type));
}

export int clipper_add_polygons(clipper_t clipper, polygons_t data, clipper_PolyType poly_type) {
	clipper->AddPolygons(*data, PolyType(poly_type));
}

export void clipper_get_bounds(clipper_t clipper, double *x1, double *y1, double *x2, double *y2, double scale) {
	IntRect r = clipper->GetBounds();
	*x1 = r.left / scale;
	*x2 = r.right / scale;
	*y1 = r.top / scale;
	*y2 = r.bottom / scale;
}

export int clipper_execute(clipper_t clipper, clipper_ClipType clipType,
									clipper_PolyFillType subjFillType,
									clipper_PolyFillType clipFillType) {
	polygons_t solution = new Polygons();
	clipper->Execute(ClipType(clipType), *solution,
										PolyFillType(subjFillType),
										PolyFillType(clipFillType));
}

export int clipper_execute_ex(clipper_t clipper, clipper_ClipType clipType,
									clipper_PolyFillType subjFillType,
									clipper_PolyFillType clipFillType) {
	ex_polygons_t solution = new ExPolygons();
	clipper->Execute(ClipType(clipType), *solution,
										PolyFillType(subjFillType),
										PolyFillType(clipFillType));
}

export void clipper_clear(clipper_t clipper) {
	clipper->Clear();
}

export bool clipper_get_reverse_solution(clipper_t clipper) {
	return clipper->ReverseSolution();
}

export void clipper_set_reverse_solution(clipper_t clipper, int reverse) {
	clipper->ReverseSolution(reverse);
}

