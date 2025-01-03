//!zig-autodoc-section: core_input_gamepad_info.Main
//! raylib_examples/core_input_gamepad_info.zig
//!   Example - Gamepad information.
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

  rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT); // Set MSAA 4X hint before window creation

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - gamepad information");

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    var y: i32 = 5;
    for (0..3) |i_| { // MAX_GAMEPADS = 4
      const i: c_int = @intCast(i_);
      if (rl.IsGamepadAvailable(i)) {
        rl.DrawText(rl.TextFormat("Gamepad name: %s", rl.GetGamepadName(i)), 10, y, 10, rl.BLACK);
        y += 11;
        rl.DrawText(rl.TextFormat("\tAxis count:   %d", rl.GetGamepadAxisCount(i)), 10, y, 10, rl.BLACK);
        y += 11;

        const axis_u: usize = @intCast(rl.GetGamepadAxisCount(i));
        for (0..axis_u) |axis_| {
          const axis: c_int = @intCast(axis_);
          rl.DrawText(rl.TextFormat("\tAxis %d = %f", axis, rl.GetGamepadAxisMovement(i, axis)), 10, y, 10, rl.BLACK);
          y += 11;
        }

        for (0..32) |button_| {
          const button: c_int = @intCast(button_);
          rl.DrawText(rl.TextFormat("\tButton %d = %d", button, rl.IsGamepadButtonDown(i, button)), 10, y, 10, rl.BLACK);
          y += 11;
        }
      }
    }

    rl.DrawFPS(rl.GetScreenWidth() - 100, 100);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}