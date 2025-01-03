//!zig-autodoc-section: core_3d_camera_split_screen.Main
//! raylib_examples/core_3d_camera_split_screen.zig
//!   Example - 3d cmaera split screen.
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera split screen");

  // Setup player 1 camera and screen
  var cameraPlayer1 = rl.Camera{};
  cameraPlayer1.fovy = 45.0;
  cameraPlayer1.up.y = 1.0;
  cameraPlayer1.target.y = 1.0;
  cameraPlayer1.position.z = -3.0;
  cameraPlayer1.position.y = 1.0;

  const screenPlayer1 = rl.LoadRenderTexture(screenWidth / 2, screenHeight);

  // Setup player two camera and screen
  var cameraPlayer2 = rl.Camera{};
  cameraPlayer2.fovy = 45.0;
  cameraPlayer2.up.y = 1.0;
  cameraPlayer2.target.y = 3.0;
  cameraPlayer2.position.x = -3.0;
  cameraPlayer2.position.y = 3.0;

  const screenPlayer2 = rl.LoadRenderTexture(screenWidth / 2, screenHeight);

  // Build a flipped rectangle the size of the split view to use for drawing later
  const splitScreenRect = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = toFloat(screenPlayer1.texture.width), .height = toFloat(-screenPlayer1.texture.height) };

  // Grid data
  const count = 5;
  const spacing = 4;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // If anyone moves this frame, how far will they move based on the time since the last frame
    // this moves things at 10 world units per second, regardless of the actual FPS
    const offsetThisFrame = 10.0 * rl.GetFrameTime();

    // Move Player1 forward and backwards (no turning)
    if (rl.IsKeyDown(rl.KEY_W)) {
      cameraPlayer1.position.z += offsetThisFrame;
      cameraPlayer1.target.z += offsetThisFrame;
    } else if (rl.IsKeyDown(rl.KEY_S)) {
      cameraPlayer1.position.z -= offsetThisFrame;
      cameraPlayer1.target.z -= offsetThisFrame;
    }

    // Move Player2 forward and backwards (no turning)
    if (rl.IsKeyDown(rl.KEY_UP)) {
      cameraPlayer2.position.x += offsetThisFrame;
      cameraPlayer2.target.x += offsetThisFrame;
    } else if (rl.IsKeyDown(rl.KEY_DOWN)) {
      cameraPlayer2.position.x -= offsetThisFrame;
      cameraPlayer2.target.x -= offsetThisFrame;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    // Draw Player1 view to the render texture
    rl.BeginTextureMode(screenPlayer1);
      rl.ClearBackground(rl.SKYBLUE);

      rl.BeginMode3D(cameraPlayer1);

        // Draw scene: grid of cube trees on a plane to make a "world"
        rl.DrawPlane(rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.Vector2{ .x = 50, .y = 50 }, rl.BEIGE); // Simple world plane

        var x1: f32 = -count * spacing;
        while (x1 <= count * spacing) : (x1 += spacing) {
          var z1: f32 = -count * spacing;
          while (z1 <= count * spacing) : (z1 += spacing) {
            rl.DrawCube(rl.Vector3{ .x = x1, .y = 1.5, .z = z1 }, 1, 1, 1, rl.LIME);
            rl.DrawCube(rl.Vector3{ .x = x1, .y = 0.5, .z = z1 }, 0.25, 1, 0.25, rl.BROWN);
          }
        }

        // Draw a cube at each player's position
        rl.DrawCube(cameraPlayer1.position, 1, 1, 1, rl.RED);
        rl.DrawCube(cameraPlayer2.position, 1, 1, 1, rl.BLUE);
        
      rl.EndMode3D();

      rl.DrawRectangle(0, 0, toInt(toFloat(rl.GetScreenWidth()) / 2.0), 40, rl.Fade(rl.RAYWHITE, 0.8));
      rl.DrawText("PLAYER1: W/S to move", 10, 10, 20, rl.MAROON);

    rl.EndTextureMode();

    // Draw Player2 view to the render texture
    rl.BeginTextureMode(screenPlayer2);
      rl.ClearBackground(rl.SKYBLUE);

      rl.BeginMode3D(cameraPlayer2);

        // Draw scene: grid of cube trees on a plane to make a "world"
        rl.DrawPlane(rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.Vector2{ .x = 50, .y = 50 }, rl.BEIGE); // Simple world plane

        var x2: f32 = -count * spacing;
        while (x2 <= count * spacing) : (x2 += spacing) {
          var z2: f32 = -count * spacing;
          while (z2 <= count * spacing) : (z2 += spacing) {
            rl.DrawCube(rl.Vector3{ .x = x2, .y = 1.5, .z = z2 }, 1, 1, 1, rl.LIME);
            rl.DrawCube(rl.Vector3{ .x = x2, .y = 0.5, .z = z2 }, 0.25, 1, 0.25, rl.BROWN);
          }
        }


        // Draw a cube at each player's position
        rl.DrawCube(cameraPlayer1.position, 1, 1, 1, rl.RED);
        rl.DrawCube(cameraPlayer2.position, 1, 1, 1, rl.BLUE);
        
      rl.EndMode3D();

      rl.DrawRectangle(0, 0, toInt(toFloat(rl.GetScreenWidth()) / 2.0), 40, rl.Fade(rl.RAYWHITE, 0.8));
      rl.DrawText("PLAYER2: UP/DOWN to move", 10, 10, 20, rl.DARKBLUE);

    rl.EndTextureMode();

    // Draw both views render textures to the screen side by side
    rl.BeginDrawing();
      rl.ClearBackground(rl.BLACK);

      rl.DrawTextureRec(screenPlayer1.texture, splitScreenRect, rl.Vector2{ .x = 0.0, .y = 0.0 }, rl.WHITE);
      rl.DrawTextureRec(screenPlayer2.texture, splitScreenRect, rl.Vector2{ .x = screenWidth / 2.0, .y = 0.0 }, rl.WHITE);

      rl.DrawRectangle(toInt(toFloat(rl.GetScreenWidth()) / 2.0) - 2, 0, 4, rl.GetScreenHeight(), rl.LIGHTGRAY);
    rl.EndDrawing();
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadRenderTexture(screenPlayer1); // Unload render texture
  rl.UnloadRenderTexture(screenPlayer2); // Unload render texture

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}
