
typedef struct _double_point {
	double x, y;
} double_point_t;

typedef enum { ctIntersection, ctUnion, ctDifference, ctXor } clipper_ClipType;
typedef enum { ptSubject, ptClip } clipper_PolyType;
typedef enum { pftEvenOdd, pftNonZero, pftPositive, pftNegative } clipper_PolyFillType;
typedef enum { jtSquare, jtRound, jtMiter } clipper_JoinType;

#ifndef clipper_hpp
typedef struct Polygon* polygon_t;
typedef struct Polygons* polygons_t;
typedef struct ExPolygons* ex_polygons_t;
typedef struct Clipper* clipper_t;
#else
typedef ClipperLib::Polygon* polygon_t;
typedef ClipperLib::Polygons* polygons_t;
typedef ClipperLib::ExPolygons* ex_polygons_t;
typedef ClipperLib::Clipper* clipper_t;
#endif

#define export extern "C" __declspec (dllexport)

export polygon_t clipper_create_polygon(double_point_t* points, int n, double scale);
export void clipper_free_polygon(polygon_t data);
export int clipper_polygon_get_size(polygon_t data);
export void clipper_save_polygon(polygon_t data, double_point_t* points, double scale);
export int clipper_orientation(polygon_t data);
export int clipper_area(polygon_t data);
export polygons_t clipper_simplify_polygon(polygon_t data, clipper_PolyFillType fillType);
export polygons_t clipper_simplify_polygons_new(polygons_t data, clipper_PolyFillType fillType);
export void clipper_simplify_polygons(polygons_t data, clipper_PolyFillType fillType);
export polygons_t clipper_offset_polygons(polygons_t data, double delta, clipper_JoinType jointype, double miter_limit);
export void clipper_reverse_polygon(polygon_t data);
export void clipper_reverse_polygons(polygons_t data);
export clipper_t clipper_create_clipper();
export void clipper_free_clipper(clipper_t clipper);
export int clipper_add_polygon(clipper_t clipper, polygon_t data, clipper_PolyType poly_type);
export int clipper_add_polygons(clipper_t clipper, polygons_t data, clipper_PolyType poly_type);
export void clipper_get_bounds(clipper_t clipper, double *x1, double *y1, double *x2, double *y2, double scale);
export int clipper_execute(clipper_t clipper, clipper_ClipType clipType,
									clipper_PolyFillType subjFillType,
									clipper_PolyFillType clipFillType);
export int clipper_execute_ex(clipper_t clipper, clipper_ClipType clipType,
									clipper_PolyFillType subjFillType,
									clipper_PolyFillType clipFillType);
export void clipper_clear(clipper_t clipper);
export bool clipper_get_reverse_solution(clipper_t clipper);
export void clipper_set_reverse_solution(clipper_t clipper, int reverse);

