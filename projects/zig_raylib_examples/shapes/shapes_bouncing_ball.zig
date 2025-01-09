//!zig-autodoc-section: shapes_bouncing_ball.Main
//! raylib_examples/shapes_bouncing_ball.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - bouncing ball
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
  //---------------------------------------------------------
  const screenWidth: f32 = 800.0;
  const screenHeight: f32 = 450.0;

  ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - bouncing ball");

  const getScreenWidth: f32 = @floatFromInt(ray.GetScreenWidth());
  const getScreenHeight: f32 = @floatFromInt(ray.GetScreenHeight());

  var ballPosition = ray.Vector2{ .x = getScreenWidth / 2.0, .y = getScreenHeight / 2.0 };
  var ballSpeed = ray.Vector2{ .x = 5.0, .y = 4.0 };
  const ballRadius = 20;

  var pause = false;
  var framesCounter: c_int = 0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //----------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //-----------------------------------------------------
    if (ray.IsKeyPressed(ray.KEY_SPACE)) pause = !pause;

    if (!pause) {
      ballPosition.x += ballSpeed.x;
      ballPosition.y += ballSpeed.y;

      // Check walls collision for bouncing
      if ((ballPosition.x >= getScreenWidth - ballRadius) or (ballPosition.x <= ballRadius)) ballSpeed.x *= -1.0;
      if ((ballPosition.y >= getScreenHeight - ballRadius) or (ballPosition.y <= ballRadius)) ballSpeed.y *= -1.0;
    } else framesCounter += 1;
    //-----------------------------------------------------

    // Draw
    //-----------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawCircleV(ballPosition, ballRadius, ray.MAROON);
      ray.DrawText("PRESS SPACE to PAUSE BALL MOVEMENT", 10, ray.GetScreenHeight() - 25, 20, ray.LIGHTGRAY);

      // On pause, we draw a blinking message
      if (pause and (@mod(@divExact(@as(f32, @floatFromInt(framesCounter)), 30.0), 2)) != 0) ray.DrawText("PAUSED", 350, 200, 30, ray.GRAY);

      ray.DrawFPS(10, 10);

    ray.EndDrawing();
    //-----------------------------------------------------
  }

  // De-Initialization
  //---------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //----------------------------------------------------------

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