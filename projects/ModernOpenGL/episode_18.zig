//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 18] OpenGL Math - Introduction to the GLM Library - Modern OpenGL
//   Mike Shah - https://www.youtube.com/watch?v=F0vUESYIrno

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

  const vA: glm.vec3 = @splat(1.0);
  const vB: glm.vec3 = .{ 0.5, 1.0, 0.0 }; //@splat(1.5);

  print("A is {d:0.6}\n", .{ vA });
  print("B is {d:0.6}\n", .{ vB });
  print("normalize(A) is {d:0.6}\n", .{ glm.normalize(vA) });
  print("normalize(B) is {d:0.6}\n", .{ glm.normalize(vB) });

  const vDot: f32 = glm.dot(vA, vB);
  print("\ndot(A,B) is {d:0.6}\n", .{ vDot });
  const vDotNorm: f32 = glm.dot(glm.normalize(vA), glm.normalize(vB));
  print("dot(normalize(A),normalize(B)) is {d:0.6}\n", .{ vDotNorm });
  print("cross(A,B) is {d:0.6}\n", .{ glm.cross(vA, vB) });

  const mat = glm.mat4;
  print("\nmat4 is {}\n", .{ mat });

  print("\nasVertex(A) is {}\n", .{ glm.asVertex(vA) });
  print("asColor(A, 1.0) is {}\n", .{ glm.asColor(vA, 1.0) });

  return 0;
}

// ============================================================================
// Tests.
//
