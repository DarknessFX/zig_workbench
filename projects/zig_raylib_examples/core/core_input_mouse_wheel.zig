//!zig-autodoc-section: core_input_mouse_wheel.Main
//! raylib_examples/core_input_mouse_wheel.zig
//!   Example - Mouse wheel input.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h"); 
});

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - input mouse wheel");

  var boxPositionY: i32 =  toFloat(screenWidth) / 2.0 - 40.0;
  const scrollSpeed: i32 = 4; // Scrolling speed in pixels

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    boxPositionY -= toInt(rl.GetMouseWheelMove()) * scrollSpeed;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawRectangle(toFloat(screenWidth) / 2.0 - 40.0, boxPositionY, 80, 80, rl.MAROON);

    rl.DrawText("Use mouse wheel to move the cube up and down!", 10, 10, 20, rl.GRAY);
    rl.DrawText(rl.TextFormat("Box position Y: %03i", boxPositionY), 10, 40, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}