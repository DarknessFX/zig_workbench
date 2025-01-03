//!zig-autodoc-section: core_2d_camera_split_screen.Main
//! raylib_examples/core_2d_camera_split_screen.zig
//!   Example - 2d camera split screen.
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

const PLAYER_SIZE: f32 = 40.0;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 440;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera split screen");

  var player1 = rl.Rectangle{ .x = 200, .y = 200, .width = PLAYER_SIZE, .height = PLAYER_SIZE };
  var player2 = rl.Rectangle{ .x = 250, .y = 200, .width = PLAYER_SIZE, .height = PLAYER_SIZE };

  var camera1 = rl.Camera2D{};
  camera1.target = rl.Vector2{ .x = player1.x, .y = player1.y };
  camera1.offset = rl.Vector2{ .x = 200.0, .y = 200.0 };
  camera1.rotation = 0.0;
  camera1.zoom = 1.0;

  var camera2 = rl.Camera2D{};
  camera2.target = rl.Vector2{ .x = player2.x, .y = player2.y };
  camera2.offset = rl.Vector2{ .x = 200.0, .y = 200.0 };
  camera2.rotation = 0.0;
  camera2.zoom = 1.0;

  const screenCamera1 = rl.LoadRenderTexture(screenWidth / 2, screenHeight);
  const screenCamera2 = rl.LoadRenderTexture(screenWidth / 2, screenHeight);

  // Build a flipped rectangle the size of the split view to use for drawing later
  const splitScreenRect = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = toFloat(screenCamera1.texture.width), .height = toFloat(-screenCamera1.texture.height) };

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsKeyDown(rl.KEY_S)) player1.y += 3.0
    else if (rl.IsKeyDown(rl.KEY_W)) player1.y -= 3.0;
    if (rl.IsKeyDown(rl.KEY_D)) player1.x += 3.0
    else if (rl.IsKeyDown(rl.KEY_A)) player1.x -= 3.0;

    if (rl.IsKeyDown(rl.KEY_UP)) player2.y -= 3.0
    else if (rl.IsKeyDown(rl.KEY_DOWN)) player2.y += 3.0;
    if (rl.IsKeyDown(rl.KEY_RIGHT)) player2.x += 3.0
    else if (rl.IsKeyDown(rl.KEY_LEFT)) player2.x -= 3.0;

    camera1.target = rl.Vector2{ .x = player1.x, .y = player1.y };
    camera2.target = rl.Vector2{ .x = player2.x, .y = player2.y };

    const fscreenWidth: f32 = @floatFromInt(rl.GetScreenWidth());
    const fscreenHeight: f32 = @floatFromInt(rl.GetScreenHeight());
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginTextureMode(screenCamera1);
      rl.ClearBackground(rl.RAYWHITE);

      rl.BeginMode2D(camera1);

        // Draw full scene with first camera
        for (0..@intCast(toInt(fscreenWidth / PLAYER_SIZE + 1.0))) |i| {
          const fi: f32 = @floatFromInt(i);
          rl.DrawLineV(rl.Vector2{ .x = PLAYER_SIZE * fi, .y = 0 }, rl.Vector2{ .x = PLAYER_SIZE * fi, .y = screenHeight }, rl.LIGHTGRAY);
        }

        for (0..@intCast(toInt(fscreenHeight / PLAYER_SIZE + 1.0))) |i| {
          const fi: f32 = @floatFromInt(i);
          rl.DrawLineV(rl.Vector2{ .x = 0, .y = PLAYER_SIZE * fi }, rl.Vector2{ .x = screenWidth, .y = PLAYER_SIZE * fi }, rl.LIGHTGRAY);
        }

        for (0..@intCast(toInt(fscreenWidth / PLAYER_SIZE))) |i| {
          const fi: f32 = @floatFromInt(i);
          for (0..@intCast(toInt(screenHeight / PLAYER_SIZE))) |j| {
            const fj: f32 = @floatFromInt(j);
            rl.DrawText(rl.TextFormat("[%i,%i]", i, j), toInt(10.0 + PLAYER_SIZE * fi), toInt(15.0 + PLAYER_SIZE * fj), 10, rl.LIGHTGRAY);
          }
        }

        rl.DrawRectangleRec(player1, rl.RED);
        rl.DrawRectangleRec(player2, rl.BLUE);
      rl.EndMode2D();

      rl.DrawRectangle(0, 0, toInt(fscreenWidth / 2.0), 30, rl.Fade(rl.RAYWHITE, 0.6));
      rl.DrawText("PLAYER1: W/S/A/D to move", 10, 10, 10, rl.MAROON);

    rl.EndTextureMode();

    rl.BeginTextureMode(screenCamera2);
      rl.ClearBackground(rl.RAYWHITE);

      rl.BeginMode2D(camera2);

        // Draw full scene with second camera
        for (0..@intCast(toInt(screenWidth / PLAYER_SIZE + 1))) |i| {
          const fi: f32 = @floatFromInt(i);
          rl.DrawLineV(rl.Vector2{ .x = PLAYER_SIZE * fi, .y = 0.0 }, rl.Vector2{ .x = PLAYER_SIZE * fi, .y = screenHeight }, rl.LIGHTGRAY);
        }

        for (0..@intCast(toInt(screenHeight / PLAYER_SIZE + 1))) |i| {
          const fi: f32 = @floatFromInt(i);
          rl.DrawLineV(rl.Vector2{ .x = 0.0, .y = PLAYER_SIZE * fi }, rl.Vector2{ .x = screenWidth, .y = PLAYER_SIZE * fi }, rl.LIGHTGRAY);
        }

        for (0..@intCast(toInt(screenWidth / PLAYER_SIZE))) |i| {
          const fi: f32 = @floatFromInt(i);
          for (0..@intCast(toInt(screenHeight / PLAYER_SIZE))) |j| {
            const fj: f32 = @floatFromInt(j);
            rl.DrawText(rl.TextFormat("[%i,%i]", i, j), toInt(10.0 + PLAYER_SIZE * fi), toInt(15.0 + PLAYER_SIZE * fj), 10, rl.LIGHTGRAY);
          }
        }

        rl.DrawRectangleRec(player1, rl.RED);
        rl.DrawRectangleRec(player2, rl.BLUE);
        
      rl.EndMode2D();

      rl.DrawRectangle(0, 0, toInt(fscreenWidth / 2.0), 30, rl.Fade(rl.RAYWHITE, 0.6));
      rl.DrawText("PLAYER2: UP/DOWN/LEFT/RIGHT to move", 10, 10, 10, rl.DARKBLUE);

    rl.EndTextureMode();

    // Draw both views render textures to the screen side by side
    rl.BeginDrawing();
      rl.ClearBackground(rl.BLACK);

      rl.DrawTextureRec(screenCamera1.texture, splitScreenRect, rl.Vector2{ .x = 0, .y = 0 }, rl.WHITE);
      rl.DrawTextureRec(screenCamera2.texture, splitScreenRect, rl.Vector2{ .x = screenWidth / 2.0, .y = 0 }, rl.WHITE);

      rl.DrawRectangle(toInt(fscreenWidth / 2.0) - 2, 0, 4, rl.GetScreenHeight(), rl.LIGHTGRAY);
    rl.EndDrawing();
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadRenderTexture(screenCamera1); // Unload render texture
  rl.UnloadRenderTexture(screenCamera2); // Unload render texture

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}
