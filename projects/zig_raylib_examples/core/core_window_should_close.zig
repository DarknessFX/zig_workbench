//!zig-autodoc-section: core_window_should_close.Main
//! raylib_examples/core_window_should_close.zig
//!   Example - Window should close.
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
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - window should close");
  
  rl.SetExitKey(rl.KEY_NULL); // Disable KEY_ESCAPE to close window, X-button still works
  
  var exitWindowRequested = false; // Flag to request window to exit
  var exitWindow = false; // Flag to set window to exit

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!exitWindow) {
    // Update
    //----------------------------------------------------------------------------------
    // Detect if X-button or KEY_ESCAPE have been pressed to close window
    if (rl.WindowShouldClose() or rl.IsKeyPressed(rl.KEY_ESCAPE)) exitWindowRequested = true;
    
    if (exitWindowRequested) {
      // A request for close window has been issued, we can save data before closing
      // or just show a message asking for confirmation
      
      if (rl.IsKeyPressed(rl.KEY_Y)) { exitWindow = true; 
      } else if (rl.IsKeyPressed(rl.KEY_N)) { exitWindowRequested = false; }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    if (exitWindowRequested) {
      rl.DrawRectangle(0, 100, screenWidth, 200, rl.BLACK);
      rl.DrawText("Are you sure you want to exit program? [Y/N]", 40, 180, 30, rl.WHITE);
    } else {
      rl.DrawText("Try to close the window to get confirmation message!", 120, 200, 20, rl.LIGHTGRAY);
    }

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}