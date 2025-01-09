//!zig-autodoc-section: shapes_following_eyes.Main
//! raylib_examples/shapes_following_eyes.zig
//!   Example - following eyes.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - following eyes
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
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

  ray.InitWindow(toInt(screenWidth), toInt(screenHeight), "raylib [shapes] example - following eyes");

  const scleraLeftPosition = ray.Vector2{ .x = screenWidth / 2.0 - 100.0, .y = screenHeight / 2.0 };
  const scleraRightPosition = ray.Vector2{ .x = screenWidth / 2.0 + 100.0, .y = screenHeight / 2.0 };
  const scleraRadius: f32 = 80.0;

  var irisLeftPosition = ray.Vector2{ .x = screenWidth / 2.0 - 100.0, .y = screenHeight / 2.0 };
  var irisRightPosition = ray.Vector2{ .x = screenWidth / 2.0 + 100.0, .y = screenHeight / 2.0 };
  const irisRadius: f32 = 24.0;

  var angle: f32 = 0.0;
  var dx: f32 = 0.0;
  var dy: f32 = 0.0;
  var dxx: f32 = 0.0;
  var dyy: f32 = 0.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    irisLeftPosition = ray.GetMousePosition();
    irisRightPosition = ray.GetMousePosition();

    // Check not inside the left eye sclera
    if (!ray.CheckCollisionPointCircle(irisLeftPosition, scleraLeftPosition, scleraRadius - irisRadius)) {
      dx = irisLeftPosition.x - scleraLeftPosition.x;
      dy = irisLeftPosition.y - scleraLeftPosition.y;

      angle = std.math.atan2(dy, dx);

      dxx = (scleraRadius - irisRadius) * @cos(angle);
      dyy = (scleraRadius - irisRadius) * @sin(angle);

      irisLeftPosition.x = scleraLeftPosition.x + dxx;
      irisLeftPosition.y = scleraLeftPosition.y + dyy;
    }

    // Check not inside the right eye sclera
    if (!ray.CheckCollisionPointCircle(irisRightPosition, scleraRightPosition, scleraRadius - irisRadius)) {
      dx = irisRightPosition.x - scleraRightPosition.x;
      dy = irisRightPosition.y - scleraRightPosition.y;

      angle = std.math.atan2(dy, dx);

      dxx = (scleraRadius - irisRadius) * @cos(angle);
      dyy = (scleraRadius - irisRadius) * @sin(angle);

      irisRightPosition.x = scleraRightPosition.x + dxx;
      irisRightPosition.y = scleraRightPosition.y + dyy;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawCircleV(scleraLeftPosition, scleraRadius, ray.LIGHTGRAY);
      ray.DrawCircleV(irisLeftPosition, irisRadius, ray.BROWN);
      ray.DrawCircleV(irisLeftPosition, 10, ray.BLACK);

      ray.DrawCircleV(scleraRightPosition, scleraRadius, ray.LIGHTGRAY);
      ray.DrawCircleV(irisRightPosition, irisRadius, ray.DARKGREEN);
      ray.DrawCircleV(irisRightPosition, 10, ray.BLACK);

      ray.DrawFPS(10, 10);

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