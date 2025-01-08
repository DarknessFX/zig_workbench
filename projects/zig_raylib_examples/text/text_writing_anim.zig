//!zig-autodoc-section: text_writing_anim.Main
//! raylib_examples/text_writing_anim.zig
//!   Example - Text Writing Animation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Text Writing Animation
// *
// *   Example originally created with raylib 1.4, last time updated with raylib 1.4
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2016-2024 Ramon Santamaria (@raysan5)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - text writing anim");

  const message = "This sample illustrates a text writing\nanimation effect! Check it out! ;)";

  var framesCounter: f32 = 0.0;

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsKeyDown(ray.KEY_SPACE)) framesCounter += 8.0
    else framesCounter += 1.0;

    if (ray.IsKeyPressed(ray.KEY_ENTER)) framesCounter = 0.0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText(ray.TextSubtext(message, 0, toInt(framesCounter / 10.0)), 210, 160, 20, ray.MAROON);

      ray.DrawText("PRESS [ENTER] to RESTART!", 240, 260, 20, ray.LIGHTGRAY);
      ray.DrawText("HOLD [SPACE] to SPEED UP!", 239, 300, 20, ray.LIGHTGRAY);

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