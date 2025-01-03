//!zig-autodoc-section: core_3d_camera_free.Main
//! raylib_examples/core_3d_camera_free.zig
//!   Example - Initialize 3d camera free.
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera free");

  // Define the camera to look into our 3d world
  var camera: rl.Camera3D = undefined;
  camera.position = rl.Vector3{ .x = 10.0, .y = 10.0, .z = 10.0 }; // Camera position
  camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };    // Camera looking at point
  camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };        // Camera up vector (rotation towards target)
  camera.fovy = 45.0;                                              // Camera field-of-view Y
  camera.projection = rl.CAMERA_PERSPECTIVE;                       // Camera projection type

  const cubePosition = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };

  rl.DisableCursor(); // Limit cursor to relative movement inside the window

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateCamera(&camera, rl.CAMERA_FREE);

    if (rl.IsKeyPressed('Z')) camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
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

    rl.DrawRectangle(10, 10, 320, 93, rl.Fade(rl.SKYBLUE, 0.5));
    rl.DrawRectangleLines(10, 10, 320, 93, rl.BLUE);

    rl.DrawText("Free camera default controls:", 20, 20, 10, rl.BLACK);
    rl.DrawText("- Mouse Wheel to Zoom in-out", 40, 40, 10, rl.DARKGRAY);
    rl.DrawText("- Mouse Wheel Pressed to Pan", 40, 60, 10, rl.DARKGRAY);
    rl.DrawText("- Z to zoom to (0, 0, 0)", 40, 80, 10, rl.DARKGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}