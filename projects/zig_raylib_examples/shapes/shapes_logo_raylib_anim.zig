//!zig-autodoc-section: shapes_logo_raylib_anim.Main
//! raylib_examples/shapes_logo_raylib_anim.zig
//!   Example - raylib logo animation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - raylib logo animation
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 4.0
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
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - raylib logo animation");

  const logoPositionX: f32 = @divTrunc(toFloat(screenWidth), 2) - 128.0;
  const logoPositionY: f32 = @divTrunc(toFloat(screenHeight), 2) - 128.0;

  var framesCounter: f32 = 0.0;
  var lettersCount: c_int = 0;

  var topSideRecWidth: c_int = 16;
  var leftSideRecHeight: c_int = 16;

  var bottomSideRecWidth: c_int = 16;
  var rightSideRecHeight: c_int = 16;

  var state: c_int = 0;                  // Tracking animation states (State Machine)
  var alpha: f32 = 1.0;             // Useful for fading

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (state == 0) {                 // State 0: Small box blinking
      framesCounter += 1;

      if (framesCounter == 120) {
        state = 1;
        framesCounter = 0;      // Reset counter... will be used later...
      }
    } else if (state == 1) {            // State 1: Top and left bars growing
      topSideRecWidth += 4;
      leftSideRecHeight += 4;

      if (topSideRecWidth == 256) state = 2;
    } else if (state == 2) {            // State 2: Bottom and right bars growing
      bottomSideRecWidth += 4;
      rightSideRecHeight += 4;

      if (bottomSideRecWidth == 256) state = 3;
    } else if (state == 3) {            // State 3: Letters appearing (one by one)
      framesCounter += 1;

      if (@divTrunc(framesCounter, 12) > 0) {       // Every 12 frames, one more letter!
        lettersCount += 1;
        framesCounter = 0;
      }

      if (lettersCount >= 10) {     // When all letters have appeared, just fade out everything
        alpha -= 0.02;

        if (alpha <= 0.0) {
          alpha = 0.0;
          state = 4;
        }
      }
    } else if (state == 4) {            // State 4: Reset and Replay
      if (ray.IsKeyPressed(ray.KEY_R)) {
        framesCounter = 0;
        lettersCount = 0;

        topSideRecWidth = 16;
        leftSideRecHeight = 16;

        bottomSideRecWidth = 16;
        rightSideRecHeight = 16;

        alpha = 1.0;
        state = 0;          // Return to State 0
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      if (state == 0) {
        if (@mod(@divTrunc(framesCounter, 15), 2) != 0) ray.DrawRectangle(logoPositionX, logoPositionY, 16, 16, ray.BLACK);
      } else if (state == 1) {
        ray.DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, ray.BLACK);
        ray.DrawRectangle(logoPositionX, logoPositionY, 16, leftSideRecHeight, ray.BLACK);
      } else if (state == 2) {
        ray.DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, ray.BLACK);
        ray.DrawRectangle(logoPositionX, logoPositionY, 16, leftSideRecHeight, ray.BLACK);

        ray.DrawRectangle(logoPositionX + 240, logoPositionY, 16, rightSideRecHeight, ray.BLACK);
        ray.DrawRectangle(logoPositionX, logoPositionY + 240, bottomSideRecWidth, 16, ray.BLACK);
      } else if (state == 3) {
        ray.DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, ray.Fade(ray.BLACK, alpha));
        ray.DrawRectangle(logoPositionX, logoPositionY + 16, 16, leftSideRecHeight - 32, ray.Fade(ray.BLACK, alpha));

        ray.DrawRectangle(logoPositionX + 240, logoPositionY + 16, 16, rightSideRecHeight - 32, ray.Fade(ray.BLACK, alpha));
        ray.DrawRectangle(logoPositionX, logoPositionY + 240, bottomSideRecWidth, 16, ray.Fade(ray.BLACK, alpha));

        ray.DrawRectangle(@divTrunc(ray.GetScreenWidth(), 2) - 112, @divTrunc(ray.GetScreenHeight(), 2) - 112, 224, 224, ray.Fade(ray.RAYWHITE, alpha));

        ray.DrawText(ray.TextSubtext("raylib", 0, lettersCount), @divTrunc(ray.GetScreenWidth(), 2) - 44, @divTrunc(ray.GetScreenHeight(), 2) + 48, 50, ray.Fade(ray.BLACK, alpha));
      } else if (state == 4) {
        ray.DrawText("[R] REPLAY", 340, 200, 20, ray.GRAY);
      }

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