//!zig-autodoc-section: shapes_easings_ball_anim.Main
//! raylib_examples/shapes_easings_ball_anim.zig
//!   Example - easings ball anim.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - easings ball anim
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 2.5
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
  @cInclude("reasings.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - easings ball anim");

  // Ball variable value to be animated with easings
  var ballPositionX: f32 = -100.0;
  var ballRadius: f32 = 20.0;
  var ballAlpha: f32 = 0.0;

  var state : c_int = 0;
  var framesCounter: f32 = 0.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (state == 0) {             // Move ball position X with easing
      framesCounter += 1;
      ballPositionX = ray.EaseElasticOut(framesCounter, -100, toFloat(screenWidth) / 2.0 + 100, 120);

      if (framesCounter >= 120) {
        framesCounter = 0;
        state = 1;
      }
    } else if (state == 1) {        // Increase ball radius with easing
      framesCounter += 1;
      ballRadius = ray.EaseElasticIn(framesCounter, 20, 500, 200);

      if (framesCounter >= 200) {
        framesCounter = 0;
        state = 2;
      }
    } else if (state == 2) {        // Change ball alpha with easing (background color blending)
      framesCounter += 1;
      ballAlpha = ray.EaseCubicOut(framesCounter, 0.0, 1.0, 200);

      if (framesCounter >= 200) {
        framesCounter = 0;
        state = 3;
      }
    } else if (state == 3) {        // Reset state to play again
      if (ray.IsKeyPressed(ray.KEY_ENTER)) {
        // Reset required variables to play again
        ballPositionX = -100;
        ballRadius = 20;
        ballAlpha = 0.0;
        state = 0;
      }
    }

    if (ray.IsKeyPressed(ray.KEY_R)) framesCounter = 0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      if (state >= 2) ray.DrawRectangle(0, 0, screenWidth, screenHeight, ray.GREEN);
      ray.DrawCircle(toInt(ballPositionX), 200, ballRadius, ray.Fade(ray.RED, 1.0 - ballAlpha));

      if (state == 3) ray.DrawText("PRESS [ENTER] TO PLAY AGAIN!", 240, 200, 20, ray.BLACK);

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