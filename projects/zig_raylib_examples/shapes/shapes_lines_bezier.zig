//!zig-autodoc-section: shapes_lines_bezier.Main
//! raylib_examples/shapes_lines_bezier.zig
//!   Example - Cubic-bezier lines.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - Cubic-bezier lines
// *
// *   Example originally created with raylib 1.7, last time updated with raylib 1.7
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2017-2024 Ramon Santamaria (@raysan5)
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
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - cubic-bezier lines");

  var startPoint: ray.Vector2 = ray.Vector2{ .x = 30, .y = 30 };
  var endPoint: ray.Vector2 = ray.Vector2{ .x = screenWidth - 30, .y = screenHeight - 30 };
  var moveStartPoint: bool = false;
  var moveEndPoint: bool = false;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    const mouse = ray.GetMousePosition();

    if (ray.CheckCollisionPointCircle(mouse, startPoint, 10.0) and ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) moveStartPoint = true
    else if (ray.CheckCollisionPointCircle(mouse, endPoint, 10.0) and ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) moveEndPoint = true;

    if (moveStartPoint) {
      startPoint = mouse;
      if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) moveStartPoint = false;
    }

    if (moveEndPoint) {
      endPoint = mouse;
      if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) moveEndPoint = false;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("MOVE START-END POINTS WITH MOUSE", 15, 20, 20, ray.GRAY);

      // Draw line Cubic Bezier, in-out interpolation (easing), no control points
      ray.DrawLineBezier(startPoint, endPoint, 4.0, ray.BLUE);
      
      // Draw start-end spline circles with some details
      ray.DrawCircleV(startPoint, if (ray.CheckCollisionPointCircle(mouse, startPoint, 10.0)) 14.0 else 8.0, if (moveStartPoint) ray.RED else ray.BLUE);
      ray.DrawCircleV(endPoint, if (ray.CheckCollisionPointCircle(mouse, endPoint, 10.0)) 14.0 else 8.0, if (moveEndPoint) ray.RED else ray.BLUE);

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