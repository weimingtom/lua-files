2D affine transforms

## `local matrix = require'trans_affine2d'`

2D affine transformation matrices.

### `matrix([xx, yx, xy, yy, x0, y0]) -> mt`
Create a new matrix object, optionally initializing it with specific fields. By default the fields are `1, 0, 0, 1, 0, 0` which make up the identity matrix.

### `mt:set(xx, yx, xy, yy, x0, y0) -> mt`
Set the matrix to the specified fields.

### `mt:reset() -> mt`
Set the matrix to the identity matrix `1, 0, 0, 1, 0, 0`.

### `mt:unpack() -> xx, yx, xy, yy, x0, y0`
Unpack the matrix fields.

### `mt:copy() -> newmt`
Create a new matrix object with the same fields as `mt`.

### `mt:transform_point(x, y) -> tx, ty`
### `mt(x, y) -> tx, ty`
Transform a 2D point. Return the transformed point.

### `mt:transform_distance(x, y) -> dx, dy`
Transform a point ignoring translation. Return the transformed distance.

### `mt:multiply(bxx, byx, bxy, byy, bx0, by0) -> mt`
Multiply `mt * b` and store the result in `mt`.

### `mt:transform(bxx, byx, bxy, byy, bx0, by0) -> mt`
Multiply `b * mt` and store the result in `mt`.

### `mt:determinant() -> det`
Compute the matrix determinant.

### `mt:is_invertible() -> true | false`
Check to see if the matrix is invertible or not (that is, if it has a non-infinite, non-zero determinant).

### `mt:scalar_multilpy(s) -> mt`
Mulitply each field of the matrix with a scalar value.

### `mt:inverse() -> newmt`
Return the inverse matrix (or nothing if the matrix is not invertible).

### `mt:translate(x, y) -> mt`
### `mt:scale(sx[, sy]) -> mt`
### `mt:rotate(angle) -> mt`
### `mt:skew(angle_x, angle_y) -> mt`

Transform the matrix in various ways. Angles are expressed in degrees, not radians.

### `mt:has_unity_scale() -> true | false`
Check that no scaling is done with this transform, only flipping and multiple-of-90deg rotation.

### `mt:has_uniform_scale() -> true | false`
Check that scaling with this transform is uniform on both axes.

### `mt:scale_factor() -> s`
Return the largest dimension of the bounding box of the transformed unit square.

### `mt:is_pixel_exact() -> true | false`
Check that pixels map 1:1 with this transform so that no filtering is necessary to project an image to the screen for example.

### `mt:is_straight() -> true | false`
Check that there's no skew and that there's no rotation other than multiple-of-90-deg. rotation.
