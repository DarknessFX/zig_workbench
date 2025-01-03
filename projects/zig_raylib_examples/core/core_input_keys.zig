//!zig-autodoc-section: core_input_keys.Main
//! raylib_examples/core_input_keys.zig
//!   Example - Keyboard input.
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

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - keyboard input");

  var ballPosition = rl.Vector2{
    .x = @as(f32, @floatFromInt(screenWidth)) / 2,
    .y = @as(f32, @floatFromInt(screenHeight)) / 2,
  };

  rl.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    if (rl.IsKeyDown(rl.KEY_RIGHT)) ballPosition.x += 2.0;
    if (rl.IsKeyDown(rl.KEY_LEFT)) ballPosition.x -= 2.0;
    if (rl.IsKeyDown(rl.KEY_UP)) ballPosition.y -= 2.0;
    if (rl.IsKeyDown(rl.KEY_DOWN)) ballPosition.y += 2.0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);
    rl.DrawText("move the ball with arrow keys", 10, 10, 20, rl.DARKGRAY);
    rl.DrawCircleV(ballPosition, 50, rl.MAROON);
    //----------------------------------------------------------------------------------

    rl.EndDrawing();
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}