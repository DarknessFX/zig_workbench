//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 20] OpenGL Math 2 - Matrix Transformations (with GLM code demonstration) - Modern OpenGL
//   Mike Shah - https://www.youtube.com/watch?v=2KAZCVf0vxg

// ============================================================================
// Globals.
//
const std = @import("std");
const print = std.debug.print;
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;

const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
});
const glm = @import("lib/glm.zig");

// ============================================================================
// Main core and app flow.
//
pub export fn main() u8 {

  // Create a 'vertex' (i.e. point)
  // 'This is the local coordinates'
  // 1.0f at the end is the 'w'coordinate
  // w=1 means we have a position or point
  // w=0 means we have a vector
  const vertex: glm.vec4 = .{ 1.0, 5.0, 1.0, 1.0 };

  // Create a model matrix for our geometry
  // Initialize qieht '1' for identity matrix
  // NOTE: Do not count on GLM to provide an 
  //       identity matrix.
  // Default mat4 is setup as identity matrix.
  var model: glm.mat4Type = glm.mat4;

  // we are now in 'world space'
  print("World Space mat4 : \n", .{ });
  glm.mat4print(model);

  // Perform some transformations (i.e. moving us in the world)
  // Scaling Matrix
  const s: glm.mat4Type = glm.scale(glm.mat4, glm.vec3{2.0, 2.0, 2.0});

  // Rotation Matrix
  const r: glm.mat4Type = glm.rotate(glm.mat4, 180.0, glm.vec3{0.0, 1.0, 0.0});

  // Translation Matrix
  const t: glm.mat4Type = glm.translate(glm.mat4, glm.vec3{0.0, 0.0, -2.0});

  model = glm.transform(model, t, r, s);

  print("\nModel state : \n", .{ });
  glm.mat4print(model);

  // Apply our model to the vertex
  const worldspace_vertex: glm.vec4 = glm.mat4mul(model, vertex);
  print("\nOur vertex in WorldSpace :\n{d:>10.6}\n", .{ worldspace_vertex });

  return 0;
}

// ============================================================================
// Tests.
//
