//!zig-autodoc-section: core_3d_camera_mode.Main
//! raylib_examples/core_3d_camera_mode.zig
//!   Example - Initialize 3d camera mode.
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera mode");

  // Define the camera to look into our 3d world
  const camera = rl.Camera3D{
    .position = rl.Vector3{ .x = 0.0, .y = 10.0, .z = 10.0 }, // Camera position
    .target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },     // Camera looking at point
    .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },         // Camera up vector (rotation towards target)
    .fovy = 45.0,                                            // Camera field-of-view Y
    .projection = rl.CAMERA_PERSPECTIVE,                     // Camera mode type
  };

  const cubePosition = rl.Vector3{
    .x = 0.0,
    .y = 0.0,
    .z = 0.0,
  };

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

    rl.BeginMode3D(camera);

    rl.DrawCube(cubePosition, 2.0, 2.0, 2.0, rl.RED);
    rl.DrawCubeWires(cubePosition, 2.0, 2.0, 2.0, rl.MAROON);

    rl.DrawGrid(10, 1.0);

    rl.EndMode3D();

    rl.DrawText("Welcome to the third dimension!", 10, 40, 20, rl.DARKGRAY);

    rl.DrawFPS(10, 10);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}