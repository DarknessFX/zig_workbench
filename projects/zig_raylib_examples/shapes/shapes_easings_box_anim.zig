//!zig-autodoc-section: shapes_easings_box_anim.Main
//! raylib_examples/shapes_easings_box_anim.zig
//!   Example - easings box anim.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - easings box anim
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
  var screenWidth: f32 = 800.0;
  var screenHeight: f32 = 450.0;

  ray.InitWindow(toInt(screenWidth), toInt(screenHeight), "raylib [shapes] example - easings box anim");

  // Box variables to be animated with easings
  var rec: ray.Rectangle = ray.Rectangle{ .x = screenWidth / 2.0, .y = -100, .width = 100, .height = 100 };
  var rotation: f32 = 0.0;
  var alpha: f32 = 1.0;

  var state: c_int = 0;
  var framesCounter: f32 = 0.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    screenWidth = toFloat(ray.GetScreenWidth());
    screenHeight = toFloat(ray.GetScreenHeight());
    switch (state) {
      0 => {     // Move box down to center of screen
        framesCounter += 1;

        // NOTE: Remember that 3rd parameter of easing function refers to
        // desired value variation, do not confuse it with expected final value!
        rec.y = ray.EaseElasticOut(framesCounter, -100, screenHeight / 2.0 + 100, 120);

        if (framesCounter >= 120) {
          framesCounter = 0;
          state = 1;
        }
      },
      1 => {     // Scale box to an horizontal bar
        framesCounter += 1;
        rec.height = ray.EaseBounceOut(framesCounter, 100, -90, 120);
        rec.width = ray.EaseBounceOut(framesCounter, 100, screenWidth, 120);

        if (framesCounter >= 120) {
          framesCounter = 0;
          state = 2;
        }
      },
      2 => {     // Rotate horizontal bar rectangle
        framesCounter += 1;
        rotation = ray.EaseQuadOut(framesCounter, 0.0, 270.0, 240);

        if (framesCounter >= 240) {
          framesCounter = 0;
          state = 3;
        }
      },
      3 => {     // Increase bar size to fill all screen
        framesCounter += 1;
        rec.height = ray.EaseCircOut(framesCounter, 10, screenWidth, 120);

        if (framesCounter >= 120) {
          framesCounter = 0;
          state = 4;
        }
      },
      4 => {     // Fade out animation
        framesCounter += 1;
        alpha = ray.EaseSineOut(framesCounter, 1.0, -1.0, 160);

        if (framesCounter >= 160) {
          framesCounter = 0;
          state = 5;
        }
      },
      else => {},
    }

    // Reset animation at any moment
    if (ray.IsKeyPressed(ray.KEY_SPACE)) {
      rec = ray.Rectangle{ .x = screenWidth / 2.0, .y = -100, .width = 100, .height = 100 };
      rotation = 0.0;
      alpha = 1.0;
      state = 0;
      framesCounter = 0;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawRectanglePro(rec, ray.Vector2{ .x = rec.width / 2.0, .y = rec.height / 2.0 }, rotation, ray.Fade(ray.BLACK, alpha));

      ray.DrawText("PRESS [SPACE] TO RESET BOX ANIMATION!", 10, ray.GetScreenHeight() - 25, 20, ray.LIGHTGRAY);

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