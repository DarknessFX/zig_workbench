//!zig-autodoc-section: core_2d_camera_mouse_zoom.Main
//! raylib_examples/core_2d_camera_mouse_zoom.zig
//!   Example - 2d camera mouse zoom.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h"); 
  @cInclude("rlgl.h");
  @cInclude("raymath.h");
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera mouse zoom");

  var camera = rl.Camera2D{
    .offset = .{ .x = 0.0, .y = 0.0 },
    .target = .{ .x = 0.0, .y = 0.0 },
    .rotation = 0.0,
    .zoom = 1.0,
  };

  var zoomMode: i32 = 0; // 0-Mouse Wheel, 1-Mouse Move

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsKeyPressed(rl.KEY_ONE)) zoomMode = 0
    else if (rl.IsKeyPressed(rl.KEY_TWO)) zoomMode = 1;

    // Translate based on mouse right click
    if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
      var delta = rl.GetMouseDelta();
      delta = rl.Vector2Scale(delta, -1.0 / camera.zoom);
      camera.target = rl.Vector2Add(camera.target, delta);
    }

    if (zoomMode == 0) {
      // Zoom based on mouse wheel
      const wheel = rl.GetMouseWheelMove();
      if (wheel != 0) {
        // Get the world point that is under the mouse
        const mouseWorldPos = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera);

        // Set the offset to where the mouse is
        camera.offset = rl.GetMousePosition();

        // Set the target to match the world space point
        camera.target = mouseWorldPos;

        // Zoom increment
        var scaleFactor = 1.0 + (0.25 * rl.fabsf(wheel));
        if (wheel < 0) scaleFactor = 1.0 / scaleFactor;
        camera.zoom = rl.Clamp(camera.zoom * scaleFactor, 0.125, 64.0);
      }
    } else {
      // Zoom based on mouse right click
      if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
        const mouseWorldPos = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera);
        camera.offset = rl.GetMousePosition();
        camera.target = mouseWorldPos;
      }
      if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_RIGHT)) {
        const deltaX = rl.GetMouseDelta().x;
        var scaleFactor = 1.0 + (0.01 * rl.fabsf(deltaX));
        if (deltaX < 0) scaleFactor = 1.0 / scaleFactor;
        camera.zoom = rl.Clamp(camera.zoom * scaleFactor, 0.125, 64.0);
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    rl.BeginMode2D(camera);
    rl.rlPushMatrix();
    rl.rlTranslatef(0, 25 * 50, 0);
    rl.rlRotatef(90, 1, 0, 0);
    rl.DrawGrid(100, 50);
    rl.rlPopMatrix();

    rl.DrawCircle(toInt(toFloat(rl.GetScreenWidth()) / 2.0), toInt(toFloat(rl.GetScreenHeight()) / 2.0), 50, rl.MAROON);
    rl.EndMode2D();

    rl.DrawCircleV(rl.GetMousePosition(), 4, rl.DARKGRAY);
    rl.DrawTextEx(
      rl.GetFontDefault(),
      rl.TextFormat("[%i, %i]", rl.GetMouseX(), rl.GetMouseY()),
      rl.Vector2Add(rl.GetMousePosition(), .{ .x = -44, .y = -24 }),
      20,
      2,
      rl.BLACK
    );

    rl.DrawText("[1][2] Select mouse zoom mode (Wheel or Move)", 20, 20, 20, rl.DARKGRAY);
    if (zoomMode == 0) rl.DrawText("Mouse left button drag to move, mouse wheel to zoom", 20, 50, 20, rl.DARKGRAY)
    else rl.DrawText("Mouse left button drag to move, mouse press and move to zoom", 20, 50, 20, rl.DARKGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}