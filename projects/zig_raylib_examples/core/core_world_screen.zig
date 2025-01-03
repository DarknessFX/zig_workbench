//!zig-autodoc-section: core_world_screen.Main
//! raylib_examples/core_world_screen.zig
//!   Example - World to screen.
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
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - core world screen");

  // Define the camera to look into our 3d world
  var camera: rl.Camera = undefined;
  camera.position = rl.Vector3{ .x = 10.0, .y = 10.0, .z = 10.0 }; // Camera position
  camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };      // Camera looking at point
  camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };          // Camera up vector (rotation towards target)
  camera.fovy = 45.0;                                              // Camera field-of-view Y
  camera.projection = rl.CAMERA_PERSPECTIVE;                       // Camera projection type

  const cubePosition = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
  var cubeScreenPosition = rl.Vector2{ .x = 0.0, .y = 0.0 };

  rl.DisableCursor(); // Limit cursor to relative movement inside the window

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateCamera(&camera, rl.CAMERA_THIRD_PERSON);

    // Calculate cube screen space position (with a little offset to be in top)
    cubeScreenPosition = rl.GetWorldToScreen(
      rl.Vector3{ .x = cubePosition.x, .y = cubePosition.y + 2.5, .z = cubePosition.z },
      camera,
    );
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

    rl.DrawText(
      "Enemy: 100 / 100",
      toInt(toFloat(toInt(cubeScreenPosition.x) - rl.MeasureText("Enemy: 100/100", 20)) / 2.0),
      toInt(cubeScreenPosition.y),
      20,
      rl.BLACK,
    );

    rl.DrawText(
      rl.TextFormat(
        "Cube position in screen space coordinates: [%i, %i]",
        toInt(cubeScreenPosition.x),
        toInt(cubeScreenPosition.y),
      ),
      10,
      10,
      20,
      rl.LIME,
    );

    rl.DrawText("Text 2d should be always on top of the cube", 10, 40, 20, rl.GRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}