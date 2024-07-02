// This is my "Fake" OpenGL Mathematics (GLM) library, as the episodes progress and
// further depends on C++ GLM, I'm adding functions and helpers to this library.
// I tried to @cImport cGML, @import ziglm and glm-zig, but each have their own
// quirks and styles while I'm wanted to keep the source code similar to the episodes.

pub const math = @import("std").math;
pub usingnamespace math;
const print = @import("std").debug.print;

pub const vec3 = @Vector(3, f32);
pub const vec4 = @Vector(4, f32);

pub const mat4Type = struct{ vec4, vec4, vec4, vec4 };
pub const mat4 = mat4Type{  // aka Identity matrix
    //  x    y    z    w
  vec4{1.0, 0.0, 0.0, 0.0},
  vec4{0.0, 1.0, 0.0, 0.0},
  vec4{0.0, 0.0, 1.0, 0.0},
  vec4{0.0, 0.0, 0.0, 1.0},
};
pub const vertexType = struct { x:f32, y: f32, z: f32 };
pub const colorType = struct { r:f32, g: f32, b: f32, a: f32 };

pub fn asVertex(vec: vec3) vertexType {
  return .{
    .x = vec[0],
    .y = vec[1],
    .z = vec[2],
  };
}

pub fn asColor(vec: vec3, alpha: f32) colorType {
  return .{
    .r = vec[0],
    .g = vec[1],
    .b = vec[2],
    .a = alpha,
  };
}

pub fn zero(vec: *vec3) void {
  vec = @splat(0.0);
}

pub fn fill(vec: *vec3, value: f32) void {
  vec = @splat(value);
}

pub fn dot(vecA: vec3, vecB: vec3) f32 {
  return vecA[0] * vecB[0] + vecA[1] * vecB[1] + vecA[2] * vecB[2];
}

pub fn dot4(vecA: vec4, vecB: vec4) f32 {
  return vecA[0] * vecB[0] + vecA[1] * vecB[1] + vecA[2] * vecB[2] + vecA[3] * vecB[3];
}

pub fn normalize(vec: vec3) vec3 {
  const veclen: f32 = length(vec);
  return vec3{vec[0] / veclen, vec[1] / veclen, vec[2] / veclen};
}

pub fn length(vec: vec3) f32 {
  return @sqrt(dot(vec, vec));
}

pub fn distance(vecA: vec3, vecB: vec3) f32 {
  return @sqrt(dot(vecA, vecB));
}

pub fn rsqrt(vec: anytype) @TypeOf(vec) {
    return 1.0 / @sqrt(vec);
}

pub fn mulFloat(vecA: vec3, val: f32) vec3 {
  return vec3{
    vecA[0] * val,
    vecA[1] * val,
    vecA[2] * val
  };
}

pub fn sub(vecA: vec3, vecB: vec3) vec3 {
  return vec3{
    vecA[0] - vecB[0],
    vecA[1] - vecB[1],
    vecA[2] - vecB[2]
  };
}

pub fn cross(vecA: vec3, vecB: vec3) vec3 {
  return vec3{
    vecA[1] * vecB[2] - vecA[2] * vecB[1],
    vecA[2] * vecB[0] - vecA[0] * vecB[2],
    vecA[0] * vecB[1] - vecA[1] * vecB[0]
  };
}

pub fn scale(mat: mat4Type, vec: vec3) mat4Type {
  return multiplyMat4(MatrixScale(vec), mat);
}

pub fn rotate(mat: mat4Type, angle: f32, axis: vec3) mat4Type {
  return multiplyMat4(MatrixRotate(angle, axis), mat);
}

pub fn rotateAll(mat: mat4Type, angle: vec3) mat4Type {
  var rot: mat4Type = mat;
  rot = rotate(rot, angle[0], vec3{ 1.0, 0.0, 0.0});
  rot = rotate(rot, angle[1], vec3{ 0.0, 1.0, 0.0});
  rot = rotate(rot, angle[2], vec3{ 0.0, 0.0, 1.0});
  return rot;
}

pub fn translate(mat: mat4Type, vec: vec3) mat4Type {
  return multiplyMat4(MatrixTranslate(vec), mat);
}

pub fn transform(mat: mat4Type, matTranslate: mat4Type, matRotate: mat4Type, matScale: mat4Type) mat4Type {
  return multiplyMat4(multiplyMat4(multiplyMat4(
        matScale,
        matRotate),
        matTranslate),
        mat);
}

pub fn perspective(fov: f32, aspect: f32, zNear: f32, zFar: f32) mat4Type {
  const tanHalfFov = @tan(fov / 2.0);
  const sx = 1.0 / (aspect * tanHalfFov);
  const sy = 1.0 / tanHalfFov;
  const sz = -(zFar + zNear) / (zFar - zNear);
  const pz = -(2.0 * zFar * zNear) / (zFar - zNear);

  return mat4Type{
    vec4{ sx, 0.0, 0.0,  0.0},
    vec4{0.0,  sy, 0.0,  0.0},
    vec4{0.0, 0.0,  sz, -1.0},
    vec4{0.0, 0.0,  pz,  0.0},
  };
}

pub fn lookAt(eye: vec3, viewdirection: vec3, up: vec3) mat4Type {
  const forward = normalize(sub(viewdirection, eye));
  const side = normalize(cross(forward, normalize(up)));
  const upVec = cross(side, forward);

  return mat4Type{
    vec4{side[0], upVec[0], -forward [0], 0.0},
    vec4{side[1], upVec[1], -forward [1], 0.0},
    vec4{side[2], upVec[2], -forward [2], 0.0},
    vec4{-dot(side, eye), -dot(upVec, eye), dot(forward, eye), 1.0},
  };
}

pub inline fn mat4col(mat: mat4Type, col: usize) vec4 {
  return vec4{ mat[0][col], mat[1][col], mat[2][col], mat[3][col] };
}

pub fn mat4mul(mat: mat4Type, vec: vec4) vec4 {
  return vec4{
    mat[0][0] * vec[0] + mat[0][1] * vec[1] + mat[0][2] * vec[2] + mat[0][3] * vec[3],
    mat[1][0] * vec[0] + mat[1][1] * vec[1] + mat[1][2] * vec[2] + mat[1][3] * vec[3],
    mat[2][0] * vec[0] + mat[2][1] * vec[1] + mat[2][2] * vec[2] + mat[2][3] * vec[3],    
    mat[3][0] * vec[0] + mat[3][1] * vec[1] + mat[3][2] * vec[2] + mat[3][3] * vec[3],
  };
}

pub fn multiplyMat4(matA: mat4Type, matB: mat4Type) mat4Type {
  var result: mat4Type = mat4;
  inline for (0..4) |index| {
    result[index] = vec4{
      dot4(matA[index], mat4col(matB, 0)),
      dot4(matA[index], mat4col(matB, 1)),
      dot4(matA[index], mat4col(matB, 2)),
      dot4(matA[index], mat4col(matB, 3)),
    };
  }
  return result;
}

pub inline fn radians(angle: f32) f32 {
  return angle * (math.pi / 180.0);
}

pub inline fn mat4print(mat: mat4Type) void {
  print("{d:>10.6}\n", .{ mat4col(mat, 0) });
  print("{d:>10.6}\n", .{ mat4col(mat, 1) });
  print("{d:>10.6}\n", .{ mat4col(mat, 2) });
  print("{d:>10.6}\n", .{ mat4col(mat, 3) });
}

pub fn MatrixTranslate(vec: vec3) mat4Type {
  return mat4Type{
    vec4{1.0, 0.0, 0.0, 0.0},
    vec4{0.0, 1.0, 0.0, 0.0},
    vec4{0.0, 0.0, 1.0, 0.0},
    vec4{vec[0], vec[1], vec[2],    1.0},
  };
}

pub fn MatrixScale(vec: vec3) mat4Type {
  return mat4Type{
    vec4{vec[0],    0.0,    0.0, 0.0},
    vec4{   0.0, vec[1],    0.0, 0.0},
    vec4{   0.0,    0.0, vec[2], 0.0},
    vec4{   0.0,    0.0,    0.0, 1.0},
  };
}

pub fn MatrixRotate(angle: f32, axis: vec3) mat4Type {
  const c = @cos(radians(angle));
  const s = @sin(radians(angle));
  const t = 1.0 - c;
  const x = axis[0]; const y = axis[1]; const z = axis[2];
  const tx = t * x;  const ty = t * y;  const tz = t * z;
  const sx = s * x;  const sy = s * y;  const sz = s * z;
  const xy = tx * y; const xz = tx * z; const yz = ty * z;

  return mat4Type{
    vec4{tx * x + c,       xy - sz,       xz + sy,     0.0},
    vec4{   xy + sz,    ty * y + c,       yz - sx,     0.0},
    vec4{   xz - sy,       yz + sx,    tz * z + c,     0.0},
    vec4{       0.0,           0.0,           0.0,     1.0}
  };
}

pub fn rotateVector(vec: vec3, angle: f32, axis: vec3) vec3 {
  const rot = mat4mul(
    MatrixRotate(angle, axis), 
    vec4{vec[0], vec[1], vec[2], 1.0});
  return vec3{
    rot[0],
    rot[1],
    rot[2],
  };
}

pub fn rotateVector4(vec: vec4, angle: f32, axis: vec3) vec4 {
  const rot = mat4mul(
    MatrixRotate(angle, axis), 
    vec);
  return rot;
}