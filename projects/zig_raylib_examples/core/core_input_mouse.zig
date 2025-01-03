//!zig-autodoc-section: core_input_mouse.Main
//! raylib_examples/core_input_mouse.zig
//!   Example - Mouse input.
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - mouse input");

  var ballPosition = rl.Vector2{
    .x = -100.0,
    .y = -100.0,
  };
  var ballColor = rl.DARKBLUE;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    ballPosition = rl.GetMousePosition();

    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) ballColor = rl.MAROON;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_MIDDLE)) ballColor = rl.LIME;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) ballColor = rl.DARKBLUE;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_SIDE)) ballColor = rl.PURPLE;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_EXTRA)) ballColor = rl.YELLOW;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_FORWARD)) ballColor = rl.ORANGE;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_BACK)) ballColor = rl.BEIGE;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawCircleV(ballPosition, 40, ballColor);

    rl.DrawText("move ball with mouse and click mouse button to change color", 10, 10, 20, rl.DARKGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}