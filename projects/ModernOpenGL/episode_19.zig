//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 19] OpenGL Math 1 - Vectors, Dot Product, and Cross Product (with code demonstration)
//   Mike Shah - https://www.youtube.com/watch?v=UL4O3wf28X0

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

  const vA: glm.vec3 = .{ 4.0, 0.0, 0.0 };
  const vB: glm.vec3 = .{ 0.0, 4.0, 0.0 };
  const vC: glm.vec3 = glm.cross(vB, vA);

  print("A length is {d:0.6}\n", .{ glm.length(vA) });
  print("B length is {d:0.6}\n\n", .{ glm.length(vB) });

  print("A normalized is {d:0.6}\n", .{ glm.normalize(vA) });
  print("A-hat (length normalized) is {d:0.6}\n\n", .{ glm.length(glm.normalize(vA)) });

  print("dot(A,B) is {d:0.6}\n", .{ glm.dot(vA, vB) });
  const dotproduct: f32 = glm.dot(glm.normalize(vA), glm.normalize(vB));
  print("dotproduct is {d:0.6}\n", .{ dotproduct });
  print("angle(dotproduct) is {d:0.6}\n\n", .{ @round( glm.acos(dotproduct) * 180.0 / glm.pi ) });

  print("cross product is {d:0.6}\n", .{ vC });


  return 0;
}

// ============================================================================
// Tests.
//
