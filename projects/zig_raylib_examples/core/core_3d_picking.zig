//!zig-autodoc-section: core_3d_picking.Main
//! raylib_examples/core_3d_picking.zig
//!   Example - Picking in 3d mode.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h");
  @cInclude("stdlib.h");
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d picking");

  // Define the camera to look into our 3d world
  var camera: rl.Camera = undefined;
  camera.position = rl.Vector3{ .x = 10.0, .y = 10.0, .z = 10.0 }; // Camera position
  camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };      // Camera looking at point
  camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };          // Camera up vector (rotation towards target)
  camera.fovy = 45.0;                                              // Camera field-of-view Y
  camera.projection = rl.CAMERA_PERSPECTIVE;                      // Camera projection type

  const cubePosition = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
  const cubeSize = rl.Vector3{ .x = 2.0, .y = 2.0, .z = 2.0 };

  var ray: rl.Ray = undefined;                   // Picking line ray
  var collision: rl.RayCollision = undefined;   // Ray collision hit info

  rl.SetTargetFPS(60);                           // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {             // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsCursorHidden()) rl.UpdateCamera(&camera, rl.CAMERA_FIRST_PERSON);

    // Toggle camera controls
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
      if (rl.IsCursorHidden()) rl.EnableCursor()
      else rl.DisableCursor();
    }

    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
      if (!collision.hit) {
        ray = rl.GetScreenToWorldRay(rl.GetMousePosition(), camera);

        // Check collision between ray and box
        collision = rl.GetRayCollisionBox(ray,
          rl.BoundingBox{
            .min = rl.Vector3{ .x = cubePosition.x - cubeSize.x / 2, .y = cubePosition.y - cubeSize.y / 2, .z = cubePosition.z - cubeSize.z / 2 },
            .max = rl.Vector3{ .x = cubePosition.x + cubeSize.x / 2, .y = cubePosition.y + cubeSize.y / 2, .z = cubePosition.z + cubeSize.z / 2 },
          });
      } else {
        collision.hit = false;
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.BeginMode3D(camera);

    if (collision.hit) {
      rl.DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.RED);
      rl.DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.MAROON);
      rl.DrawCubeWires(cubePosition, cubeSize.x + 0.2, cubeSize.y + 0.2, cubeSize.z + 0.2, rl.GREEN);
    } else {
      rl.DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.GRAY);
      rl.DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.DARKGRAY);
    }

    rl.DrawRay(ray, rl.MAROON);
    rl.DrawGrid(10, 1.0);

    rl.EndMode3D();

    rl.DrawText("Try clicking on the box with your mouse!", 240, 10, 20, rl.DARKGRAY);

    if (collision.hit) {
      rl.DrawText("BOX SELECTED", toInt(toFloat(screenWidth - rl.MeasureText("BOX SELECTED", 30)) / 2.0), toInt(toFloat(screenHeight) * 0.1), 30, rl.GREEN);
    }

    rl.DrawText("Right click mouse to toggle camera controls", 10, 430, 10, rl.GRAY);

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