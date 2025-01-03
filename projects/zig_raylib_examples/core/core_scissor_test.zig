//!zig-autodoc-section: core_scissor_test.Main
//! raylib_examples/core_scissor_test.zig
//!   Example - Scissor test.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/rl.h"); 
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
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - scissor test");

  var scissorArea = rl.Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 };
  var scissorMode = true;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsKeyPressed(rl.KEY_S)) scissorMode = !scissorMode;

    // Centre the scissor area around the mouse position
    scissorArea.x = toFloat(rl.GetMouseX()) - scissorArea.width / 2.0;
    scissorArea.y = toFloat(rl.GetMouseY()) - scissorArea.height / 2.0;

    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    if (scissorMode) 
      rl.BeginScissorMode(toInt(scissorArea.x), toInt(scissorArea.y), toInt(scissorArea.width), toInt(scissorArea.height));

    // Draw full screen rectangle and some text
    // NOTE: Only part defined by scissor area will be rendered
    rl.DrawRectangle(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight(), rl.RED);
    rl.DrawText("Move the mouse around to reveal this text!", 190, 200, 20, rl.LIGHTGRAY);

    if (scissorMode) 
      rl.EndScissorMode();

    rl.DrawRectangleLinesEx(scissorArea, 1, rl.BLACK);
    rl.DrawText("Press S to toggle scissor test", 10, 10, 20, rl.BLACK);

    rl.EndDrawing();
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}