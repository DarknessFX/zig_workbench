//!zig-autodoc-section: core_3d_camera_first_person.Main
//! raylib_examples/core_3d_camera_first_person.zig
//!   Example - 3d camera first person.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h");
  @cInclude("rcamera.h");
});

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}

const MAX_COLUMNS: c_int = 20;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera first person");

  // Define the camera to look into our 3d world (position, target, up vector)
  var camera = rl.Camera{};
  camera.position = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 4.0 };    // Camera position
  camera.target = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 0.0 };      // Camera looking at point
  camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };          // Camera up vector (rotation towards target)
  camera.fovy = 60.0;                                              // Camera field-of-view Y
  camera.projection = rl.CAMERA_PERSPECTIVE;                        // Camera projection type

  var cameraMode = rl.CAMERA_FIRST_PERSON;

  // Generates some random columns
  var heights: [MAX_COLUMNS]f32 = undefined;
  var positions: [MAX_COLUMNS]rl.Vector3 = undefined;
  var colors: [MAX_COLUMNS]rl.Color = undefined;

  for (0..MAX_COLUMNS) |i| {
    heights[i] = toFloat(rl.GetRandomValue(1, 12));
    positions[i] = rl.Vector3{ .x = toFloat(rl.GetRandomValue(-15, 15)),
                               .y = heights[i] / 2.0,
                               .z = toFloat(rl.GetRandomValue(-15, 15)) };
    colors[i] = rl.Color{
      .r = toU8(rl.GetRandomValue(20, 255)),
      .g = toU8(rl.GetRandomValue(10, 55)),
      .b = 30,
      .a = 255,
    };
  }

  rl.DisableCursor();                    // Limit cursor to relative movement inside the window

  rl.SetTargetFPS(60);                   // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {      // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // Switch camera mode
    if (rl.IsKeyPressed(rl.KEY_ONE)) {
      cameraMode = rl.CAMERA_FREE;
      camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Reset roll
    }

    if (rl.IsKeyPressed(rl.KEY_TWO)) {
      cameraMode = rl.CAMERA_FIRST_PERSON;
      camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Reset roll
    }

    if (rl.IsKeyPressed(rl.KEY_THREE)) {
      cameraMode = rl.CAMERA_THIRD_PERSON;
      camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Reset roll
    }

    if (rl.IsKeyPressed(rl.KEY_FOUR)) {
      cameraMode = rl.CAMERA_ORBITAL;
      camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Reset roll
    }

    // Switch camera projection
    if (rl.IsKeyPressed(rl.KEY_P)) {
      if (camera.projection == rl.CAMERA_PERSPECTIVE) {
        // Create isometric view
        cameraMode = rl.CAMERA_THIRD_PERSON;
        // Note: The target distance is related to the render distance in the orthographic projection
        camera.position = rl.Vector3{ .x = 0.0, .y = 2.0, .z = -100.0 };
        camera.target = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 0.0 };
        camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
        camera.projection = rl.CAMERA_ORTHOGRAPHIC;
        camera.fovy = 20.0; // near plane width in CAMERA_ORTHOGRAPHIC
        rl.CameraYaw(&camera, -135 * rl.DEG2RAD, true);
        rl.CameraPitch(&camera, -45 * rl.DEG2RAD, true, true, false);
      } else if (camera.projection == rl.CAMERA_ORTHOGRAPHIC) {
        // Reset to default view
        cameraMode = rl.CAMERA_THIRD_PERSON;
        camera.position = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 10.0 };
        camera.target = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 0.0 };
        camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
        camera.projection = rl.CAMERA_PERSPECTIVE;
        camera.fovy = 60.0;
      }
    }

    // Update camera computes movement internally depending on the camera mode
    // Some default standard keyboard/mouse inputs are hardcoded to simplify use
    // For advanced camera controls, it's recommended to compute camera movement manually
    rl.UpdateCamera(&camera, cameraMode);                  // Update camera
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.BeginMode3D(camera);

    rl.DrawPlane(rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.Vector2{ .x = 32.0, .y = 32.0 }, rl.LIGHTGRAY); // Draw ground
    rl.DrawCube(rl.Vector3{ .x = -16.0, .y = 2.5, .z = 0.0 }, 1.0, 5.0, 32.0, rl.BLUE);     // Draw a blue wall
    rl.DrawCube(rl.Vector3{ .x = 16.0, .y = 2.5, .z = 0.0 }, 1.0, 5.0, 32.0, rl.LIME);      // Draw a green wall
    rl.DrawCube(rl.Vector3{ .x = 0.0, .y = 2.5, .z = 16.0 }, 32.0, 5.0, 1.0, rl.GOLD);      // Draw a yellow wall

    // Draw some cubes around
    for (0..MAX_COLUMNS) |i| {
      rl.DrawCube(positions[i], 2.0, heights[i], 2.0, colors[i]);
      rl.DrawCubeWires(positions[i], 2.0, heights[i], 2.0, rl.MAROON);
    }

    // Draw player cube
    if (cameraMode == rl.CAMERA_THIRD_PERSON) {
      rl.DrawCube(camera.target, 0.5, 0.5, 0.5, rl.PURPLE);
      rl.DrawCubeWires(camera.target, 0.5, 0.5, 0.5, rl.DARKPURPLE);
    }

    rl.EndMode3D();

    // Draw info boxes
    rl.DrawRectangle(5, 5, 330, 100, rl.Fade(rl.SKYBLUE, 0.5));
    rl.DrawRectangleLines(5, 5, 330, 100, rl.BLUE);

    rl.DrawText("Camera controls:", 15, 15, 10, rl.BLACK);
    rl.DrawText("- Move keys: W, A, S, D, Space, Left-Ctrl", 15, 30, 10, rl.BLACK);
    rl.DrawText("- Look around: arrow keys or mouse", 15, 45, 10, rl.BLACK);
    rl.DrawText("- Camera mode keys: 1, 2, 3, 4", 15, 60, 10, rl.BLACK);
    rl.DrawText("- Zoom keys: num-plus, num-minus or mouse scroll", 15, 75, 10, rl.BLACK);
    rl.DrawText("- Camera projection key: P", 15, 90, 10, rl.BLACK);

    rl.DrawRectangle(600, 5, 195, 100, rl.Fade(rl.SKYBLUE, 0.5));
    rl.DrawRectangleLines(600, 5, 195, 100, rl.BLUE);

    const cameraStatus = @as([*c]const u8, @ptrCast(
      if (cameraMode == rl.CAMERA_FREE) "FREE" 
      else if (cameraMode == rl.CAMERA_FIRST_PERSON) "FIRST_PERSON"
      else if (cameraMode == rl.CAMERA_THIRD_PERSON) "THIRD_PERSON"
      else if (cameraMode == rl.CAMERA_ORBITAL) "ORBITAL" 
      else "CUSTOM"));

    rl.DrawText("Camera status:", 610, 15, 10, rl.BLACK);
    rl.DrawText(rl.TextFormat("- Mode: %s", cameraStatus),
      610, 30, 10, rl.BLACK
    );
    const projectionStatus = @as([*c]const u8, @ptrCast(
      if (camera.projection == rl.CAMERA_PERSPECTIVE) "PERSPECTIVE" 
      else if (camera.projection == rl.CAMERA_ORTHOGRAPHIC) "ORTHOGRAPHIC"
      else "CUSTOM"));
    rl.DrawText(
      rl.TextFormat("- Projection: %s", projectionStatus),
      610, 45, 10, rl.BLACK
    );
    rl.DrawText(
      rl.TextFormat("- Position: (%06.3f, %06.3f, %06.3f)", camera.position.x, camera.position.y, camera.position.z),
      610, 60, 10, rl.BLACK
    );
    rl.DrawText(
      rl.TextFormat("- Target: (%06.3f, %06.3f, %06.3f)", camera.target.x, camera.target.y, camera.target.z),
      610, 75, 10, rl.BLACK
    );
    rl.DrawText(
      rl.TextFormat("- Up: (%06.3f, %06.3f, %06.3f)", camera.up.x, camera.up.y, camera.up.z),
      610, 90, 10, rl.BLACK
    );

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}