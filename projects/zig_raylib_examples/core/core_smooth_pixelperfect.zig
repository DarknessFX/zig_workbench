//!zig-autodoc-section: core_smooth_pixelperfect.Main
//! raylib_examples/core_smooth_pixelperfect.zig
//!   Example - Smooth Pixel-perfect camera.
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
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  const virtualScreenWidth: c_int = 160;
  const virtualScreenHeight: c_int = 90;

  const virtualRatio: f32 = toFloat(screenWidth) / toFloat(virtualScreenWidth);

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - smooth pixel-perfect camera");

  var worldSpaceCamera: rl.Camera2D = undefined;  // Game world camera
  worldSpaceCamera.zoom = 1.0;

  var screenSpaceCamera: rl.Camera2D = undefined; // Smoothing camera
  screenSpaceCamera.zoom = 1.0;

  const target = rl.LoadRenderTexture(virtualScreenWidth, virtualScreenHeight); // This is where we'll draw all our objects.

  const rec01: rl.Rectangle = .{ .x=70.0, .y=35.0, .width=20.0, .height=20.0 };
  const rec02: rl.Rectangle = .{ .x=90.0, .y=55.0, .width=30.0, .height=10.0 };
  const rec03: rl.Rectangle = .{ .x=80.0, .y=65.0, .width=15.0, .height=25.0 };

  // The target's height is flipped (in the source Rectangle), due to OpenGL reasons
  const sourceRec: rl.Rectangle = .{ .x=0.0, .y=0.0, .width=toFloat(target.texture.width), .height=toFloat(-target.texture.height)};
  const destRec: rl.Rectangle = .{ .x=-virtualRatio, .y=-virtualRatio, .width=screenWidth + (virtualRatio * 2), .height=screenHeight + (virtualRatio * 2) };

  const origin: rl.Vector2 = .{ .x=0.0, .y=0.0 };

  var rotation: f32 = 0.0;

  var cameraX: f32 = 0.0;
  var cameraY: f32 = 0.0;

  rl.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rotation += 60.0 * rl.GetFrameTime();   // Rotate the rectangles, 60 degrees per second

    // Make the camera move to demonstrate the effect
    cameraX = @floatCast((std.math.sin(rl.GetTime()) * 50.0) - 10.0);
    cameraY = @floatCast(std.math.cos(rl.GetTime()) * 30.0);

    // Set the camera's target to the values computed above
    screenSpaceCamera.target = rl.Vector2{ .x=cameraX, .y=cameraY };

    // Round worldSpace coordinates, keep decimals into screenSpace coordinates
    worldSpaceCamera.target.x = std.math.trunc(screenSpaceCamera.target.x);
    screenSpaceCamera.target.x -= worldSpaceCamera.target.x;
    screenSpaceCamera.target.x *= virtualRatio;

    worldSpaceCamera.target.y = std.math.trunc(screenSpaceCamera.target.y);
    screenSpaceCamera.target.y -= worldSpaceCamera.target.y;
    screenSpaceCamera.target.y *= virtualRatio;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginTextureMode(target);
      rl.ClearBackground(rl.RAYWHITE);

      rl.BeginMode2D(worldSpaceCamera);
        rl.DrawRectanglePro(rec01, origin, rotation, rl.BLACK);
        rl.DrawRectanglePro(rec02, origin, -rotation, rl.RED);
        rl.DrawRectanglePro(rec03, origin, rotation + 45.0, rl.BLUE);
      rl.EndMode2D();
    rl.EndTextureMode();

    rl.BeginDrawing();
      rl.ClearBackground(rl.RED);

      rl.BeginMode2D(screenSpaceCamera);
        rl.DrawTexturePro(target.texture, sourceRec, destRec, origin, 0.0, rl.WHITE);
      rl.EndMode2D();

      rl.DrawText(rl.TextFormat("Screen resolution: %ix%i", screenWidth, screenHeight), 10, 10, 20, rl.DARKBLUE);
      rl.DrawText(rl.TextFormat("World resolution: %ix%i", virtualScreenWidth, virtualScreenHeight), 10, 40, 20, rl.DARKGREEN);
      rl.DrawFPS(screenWidth - 95, 10);
    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadRenderTexture(target);    // Unload render texture

  rl.CloseWindow();                  // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}