//!zig-autodoc-section: core_random_values.Main
//! raylib_examples/core_random_values.zig
//!   Example - Generate random values.
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - generate random values");

  // rl.SetRandomSeed(0xaabbccff); // Set a custom random seed if desired, by default: "time(NULL)"

  var randValue: i32 = rl.GetRandomValue(-8, 5); // Get a random integer number between -8 and 5 (both included)

  var framesCounter: u32 = 0; // Variable used to count frames

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    framesCounter += 1;

    // Every two seconds (120 frames) a new random value is generated
    if ((framesCounter / 120) % 2 == 1) {
      randValue = rl.GetRandomValue(-8, 5);
      framesCounter = 0;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("Every 2 seconds a new random value is generated:", 130, 100, 20, rl.MAROON);

    rl.DrawText(rl.TextFormat("%i", randValue), 360, 180, 80, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}