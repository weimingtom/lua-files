v1.0 | [code](http://code.google.com/p/lua-files/source/browse/affine2d.lua) | [test](http://code.google.com/p/lua-files/source/browse/affine2d_test.lua) | Lua 5.1, Lua 5.2, LuaJIT 2

## `local matrix = require'affine2d'` ##

2D affine transformation matrices.

| `matrix(xx, yx, xy, yy, x0, y0) -> mt` <br> <code>matrix() -&gt; mt</code> <table><thead><th> Create a new matrix object. Defaults to identity matrix <code>1, 0, 0, 1, 0, 0</code>. </th></thead><tbody>
<tr><td> <code>mt:set(xx, yx, xy, yy, x0, y0) -&gt; mt</code>                       </td><td> Set the matrix fields.                                                                 </td></tr>
<tr><td> <code>mt:reset() -&gt; mt</code>                                           </td><td> Set the matrix to the identity matrix <code>1, 0, 0, 1, 0, 0</code>.                   </td></tr>
<tr><td> <code>mt:unpack() -&gt; xx, yx, xy, yy, x0, y0</code>                      </td><td> Unpack the matrix fields.                                                              </td></tr>
<tr><td> <code>mt:copy() -&gt; newmt</code>                                         </td><td> Create a new matrix object with the same fields as <code>mt</code>.                    </td></tr>
<tr><td> <code>mt:transform_point(x, y) -&gt; tx, ty</code> <br> <code>mt(x, y) -&gt; tx, ty</code> </td><td> Transform a 2D point.                                                                  </td></tr>
<tr><td> <code>mt:transform_distance(x, y) -&gt; dx, dy</code>                      </td><td> Transform a point ignoring translation.                                                </td></tr>
<tr><td> <code>mt:multiply(bxx, byx, bxy, byy, bx0, by0) -&gt; mt</code>            </td><td> Multiply <code>mt * b</code> and store the result in <code>mt</code>.                  </td></tr>
<tr><td> <code>mt:transform(bxx, byx, bxy, byy, bx0, by0) -&gt; mt</code>           </td><td> Multiply <code>b * mt</code> and store the result in <code>mt</code>.                  </td></tr>
<tr><td> <code>mt:determinant() -&gt; det</code>                                    </td><td> Compute the matrix determinant.                                                        </td></tr>
<tr><td> <code>mt:is_invertible() -&gt; true | false</code>                         </td><td> Check if the matrix is invertible, that is, if the determinant is not 0, 1/0 or -1/0.  </td></tr>
<tr><td> <code>mt:scalar_multilpy(s) -&gt; mt</code>                                </td><td> Mulitply each field of the matrix with a scalar value.                                 </td></tr>
<tr><td> <code>mt:inverse() -&gt; newmt</code>                                      </td><td> Return the inverse matrix, or nothing if the matrix is not invertible.                 </td></tr>
<tr><td> <code>mt:translate(x, y) -&gt; mt</code>                                   </td><td> Translate the matrix.                                                                  </td></tr>
<tr><td> <code>mt:scale(sx, sy) -&gt; mt</code> <br> <code>mt:scale(s)</code>       </td><td> Scale the matrix.                                                                      </td></tr>
<tr><td> <code>mt:rotate(angle) -&gt; mt</code>                                     </td><td> Rotate the matrix. The angle is in degrees.                                            </td></tr>
<tr><td> <code>mt:skew(angle_x, angle_y) -&gt; mt</code>                            </td><td> Skew the matrix. Angles are in degrees.                                                </td></tr>
<tr><td> <code>mt:is_identity() -&gt; true | false</code>                           </td><td> Check if the matrix is the identity matrix, thus having no effect on the input.        </td></tr>
<tr><td> <code>mt:has_unity_scale() -&gt; true | false</code>                       </td><td> Check that no scaling is done with this transform, only flipping and multiple-of-90-degree rotation. </td></tr>
<tr><td> <code>mt:has_uniform_scale() -&gt; true | false</code>                     </td><td> Check that scaling with this transform is uniform on both axes.                        </td></tr>
<tr><td> <code>mt:scale_factor() -&gt; s</code>                                     </td><td> Largest dimension of the bounding box of the transformed unit square.                  </td></tr>
<tr><td> <code>mt:is_pixel_exact() -&gt; true | false</code>                        </td><td> Check that pixels map 1:1 with this transform so that no filtering is necessary to project an image to the screen for example. </td></tr>
<tr><td> <code>mt:is_straight() -&gt; true | false</code>                           </td><td> Check that there's no skew and that there's no rotation other than multiple-of-90-degree rotation. </td></tr>
<tr><td> <code>mt1 * mt2 -&gt; newmt</code>                                         </td><td> Multiply two matrices and return the result as a new matrix.                           </td></tr>
<tr><td> <code>mt1 == mt2</code>                                                    </td><td> Test two matrices for equality. Matrices are considered equal when their fields are equal. </td></tr>