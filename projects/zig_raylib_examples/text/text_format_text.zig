//!zig-autodoc-section: text_format_text.Main
//! raylib_examples/text_format_text.zig
//!   Example - Text formatting.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Text formatting
// *
// *   Example originally created with raylib 1.1, last time updated with raylib 3.0
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
pub fn main() u8 {
  // Initialization
  //
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - text formatting");

  const score: c_int = 100020;
  const hiscore: c_int = 200450;
  const lives: c_int = 5;

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText(ray.TextFormat("Score: %08i", score), 200, 80, 20, ray.RED);

      ray.DrawText(ray.TextFormat("HiScore: %08i", hiscore), 200, 120, 20, ray.GREEN);

      ray.DrawText(ray.TextFormat("Lives: %02i", lives), 200, 160, 40, ray.BLUE);

      ray.DrawText(ray.TextFormat("Elapsed Time: %02.02f ms", ray.GetFrameTime() * 1000), 200, 220, 20, ray.BLACK);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //
  ray.CloseWindow(); // Close window and OpenGL context
  //

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}