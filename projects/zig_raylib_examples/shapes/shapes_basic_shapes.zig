//!zig-autodoc-section: shapes_basic_shapes.Main
//! raylib_examples/shapes_basic_shapes.zig
//!   Example - Draw basic shapes 2d.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - Draw basic shapes 2d (rectangle, circle, line...)
// *
// *   Example originally created with raylib 1.0, last time updated with raylib 4.2
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2014-2024 Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: f32 = 800.0;
  const screenHeight: f32 = 450.0;

  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - basic shapes drawing");

  var rotation: f32 = 0.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rotation += 0.2;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("some basic shapes available on raylib", 20, 20, 20, ray.DARKGRAY);

      // Circle shapes and lines
      ray.DrawCircle(screenWidth / 5, 120, 35, ray.DARKBLUE);
      ray.DrawCircleGradient(screenWidth / 5, 220, 60, ray.GREEN, ray.SKYBLUE);
      ray.DrawCircleLines(screenWidth / 5, 340, 80, ray.DARKBLUE);

      // Rectangle shapes and lines
      ray.DrawRectangle(screenWidth / 4 * 2 - 60, 100, 120, 60, ray.RED);
      ray.DrawRectangleGradientH(screenWidth / 4 * 2 - 90, 170, 180, 130, ray.MAROON, ray.GOLD);
      ray.DrawRectangleLines(screenWidth / 4 * 2 - 40, 320, 80, 60, ray.ORANGE);  // NOTE: Uses QUADS internally, not lines

      // Triangle shapes and lines
      ray.DrawTriangle(ray.Vector2{ .x = screenWidth / 4.0 * 3.0, .y = 80.0 },
                       ray.Vector2{ .x = screenWidth / 4.0 * 3.0 - 60.0, .y = 150.0 },
                       ray.Vector2{ .x = screenWidth / 4.0 * 3.0 + 60.0, .y = 150.0 }, ray.VIOLET);

      ray.DrawTriangleLines(ray.Vector2{ .x = screenWidth / 4.0 * 3.0, .y = 160.0 },
                            ray.Vector2{ .x = screenWidth / 4.0 * 3.0 - 20.0, .y = 230.0 },
                            ray.Vector2{ .x = screenWidth / 4.0 * 3.0 + 20.0, .y = 230.0 }, ray.DARKBLUE);

      // Polygon shapes and lines
      ray.DrawPoly(ray.Vector2{ .x = screenWidth / 4.0 * 3, .y = 330 }, 6, 80, rotation, ray.BROWN);
      ray.DrawPolyLines(ray.Vector2{ .x = screenWidth / 4.0 * 3, .y = 330 }, 6, 90, rotation, ray.BROWN);
      ray.DrawPolyLinesEx(ray.Vector2{ .x = screenWidth / 4.0 * 3, .y = 330 }, 6, 85, rotation, 6, ray.BEIGE);

      // NOTE: We draw all LINES based shapes together to optimize internal drawing,
      // this way, all LINES are rendered in a single draw pass
      ray.DrawLine(18, 42, screenWidth - 18, 42, ray.BLACK);
    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}
inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
inline fn fmtC(comptime format: []const u8, args: anytype) [:0]u8 {  return std.fmt.allocPrintZ(std.heap.page_allocator, format, args) catch unreachable; }

var cwd: []u8 = undefined;
inline fn getCwd() []u8 { return std.process.getCwdAlloc(std.heap.page_allocator) catch unreachable; }
inline fn getPath(folder: []const u8, file: []const u8) [*]const u8 { 
  if (cwd.len == 0) cwd = getCwd();
  std.fs.cwd().access(folder, .{ .mode = std.fs.File.OpenMode.read_only }) catch {
    return fmt("{s}/{s}", .{ cwd, file} ).ptr; 
  };
  return fmt("{s}/{s}/{s}", .{ cwd, folder, file} ).ptr; 
}