//!zig-autodoc-section: core_window_flags.Main
//! rl_examples/core_window_flags.zig
//!   Example - window flags.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/rl_examples/lib/rl.h"); 
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
  //---------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  // Possible window flags
  // /*
  // FLAG_VSYNC_HINT
  // FLAG_FULLSCREEN_MODE    -> not working properly -> wrong scaling!
  // FLAG_WINDOW_RESIZABLE
  // FLAG_WINDOW_UNDECORATED
  // FLAG_WINDOW_TRANSPARENT
  // FLAG_WINDOW_HIDDEN
  // FLAG_WINDOW_MINIMIZED   -> Not supported on window creation
  // FLAG_WINDOW_MAXIMIZED   -> Not supported on window creation
  // FLAG_WINDOW_UNFOCUSED
  // FLAG_WINDOW_TOPMOST
  // FLAG_WINDOW_HIGHDPI     -> errors after minimize-resize, fb size is recalculated
  // FLAG_WINDOW_ALWAYS_RUN
  // FLAG_MSAA_4X_HINT
  // */

  // Set configuration flags for window creation
  // SetConfigFlags(FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT | FLAG_WINDOW_HIGHDPI);
  rl.InitWindow(screenWidth, screenHeight, "rl [core] example - window flags");

  var ballPosition = rl.Vector2{ .x = toFloat(rl.GetScreenWidth()) / 2.0, .y = toFloat(rl.GetScreenHeight()) / 2.0 };
  var ballSpeed = rl.Vector2{ .x = 5.0, .y = 4.0 };
  const ballRadius = 20.0;

  var framesCounter: i32 = 0;

  // Main game loop
  while (!rl.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //-----------------------------------------------------
    if (rl.IsKeyPressed(rl.KEY_F)) rl.ToggleFullscreen();  // modifies window size when scaling!

    if (rl.IsKeyPressed(rl.KEY_R)) {
      if (rl.IsWindowState(rl.FLAG_WINDOW_RESIZABLE)) rl.ClearWindowState(rl.FLAG_WINDOW_RESIZABLE)
      else rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    }

    if (rl.IsKeyPressed(rl.KEY_D)) {
      if (rl.IsWindowState(rl.FLAG_WINDOW_UNDECORATED)) rl.ClearWindowState(rl.FLAG_WINDOW_UNDECORATED)
      else rl.SetWindowState(rl.FLAG_WINDOW_UNDECORATED);
    }

    if (rl.IsKeyPressed(rl.KEY_H)) {
      if (!rl.IsWindowState(rl.FLAG_WINDOW_HIDDEN)) rl.SetWindowState(rl.FLAG_WINDOW_HIDDEN);

      framesCounter = 0;
    }

    if (rl.IsWindowState(rl.FLAG_WINDOW_HIDDEN)) {
      framesCounter += 1;
      if (framesCounter >= 240) rl.ClearWindowState(rl.FLAG_WINDOW_HIDDEN); // Show window after 3 seconds
    }

    if (rl.IsKeyPressed(rl.KEY_N)) {
      if (!rl.IsWindowState(rl.FLAG_WINDOW_MINIMIZED)) rl.MinimizeWindow();

      framesCounter = 0;
    }

    if (rl.IsWindowState(rl.FLAG_WINDOW_MINIMIZED)) {
      framesCounter += 1;
      if (framesCounter >= 240) rl.RestoreWindow(); // Restore window after 3 seconds
    }

    if (rl.IsKeyPressed(rl.KEY_M)) {
      // NOTE: Requires FLAG_WINDOW_RESIZABLE enabled!
      if (rl.IsWindowState(rl.FLAG_WINDOW_MAXIMIZED)) rl.RestoreWindow()
      else rl.MaximizeWindow();
    }

    if (rl.IsKeyPressed(rl.KEY_U)) {
      if (rl.IsWindowState(rl.FLAG_WINDOW_UNFOCUSED)) rl.ClearWindowState(rl.FLAG_WINDOW_UNFOCUSED)
      else rl.SetWindowState(rl.FLAG_WINDOW_UNFOCUSED);
    }

    if (rl.IsKeyPressed(rl.KEY_T)) {
      if (rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST)) rl.ClearWindowState(rl.FLAG_WINDOW_TOPMOST)
      else rl.SetWindowState(rl.FLAG_WINDOW_TOPMOST);
    }

    if (rl.IsKeyPressed(rl.KEY_A)) {
      if (rl.IsWindowState(rl.FLAG_WINDOW_ALWAYS_RUN)) rl.ClearWindowState(rl.FLAG_WINDOW_ALWAYS_RUN)
      else rl.SetWindowState(rl.FLAG_WINDOW_ALWAYS_RUN);
    }

    if (rl.IsKeyPressed(rl.KEY_V)) {
      if (rl.IsWindowState(rl.FLAG_VSYNC_HINT)) rl.ClearWindowState(rl.FLAG_VSYNC_HINT)
      else rl.SetWindowState(rl.FLAG_VSYNC_HINT);
    }

    // Bouncing ball logic
    ballPosition.x += ballSpeed.x;
    ballPosition.y += ballSpeed.y;
    if ((ballPosition.x >= (toFloat(rl.GetScreenWidth()) - ballRadius)) or (ballPosition.x <= ballRadius)) ballSpeed.x *= -1.0;
    if ((ballPosition.y >= (toFloat(rl.GetScreenHeight()) - ballRadius)) or (ballPosition.y <= ballRadius)) ballSpeed.y *= -1.0;
    //-----------------------------------------------------

    // Draw
    //-----------------------------------------------------
    rl.BeginDrawing();

    if (rl.IsWindowState(rl.FLAG_WINDOW_TRANSPARENT)) rl.ClearBackground(rl.BLANK)
    else rl.ClearBackground(rl.RAYWHITE);

    rl.DrawCircleV(ballPosition, ballRadius, rl.MAROON);
    rl.DrawRectangleLinesEx(rl.Rectangle{ .x = 0, .y = 0, .width = toFloat(rl.GetScreenWidth()), .height = toFloat(rl.GetScreenHeight()) }, 4, rl.RAYWHITE);

    rl.DrawCircleV(rl.GetMousePosition(), 10, rl.DARKBLUE);

    rl.DrawFPS(10, 10);

    rl.DrawText(rl.TextFormat("Screen Size: [%i, %i]", rl.GetScreenWidth(), rl.GetScreenHeight()), 10, 40, 10, rl.GREEN);

    // Draw window state info
    rl.DrawText("Following flags can be set after window creation:", 10, 60, 10, rl.GRAY);
    if (rl.IsWindowState(rl.FLAG_FULLSCREEN_MODE)) rl.DrawText("[F] FLAG_FULLSCREEN_MODE: on", 10, 80, 10, rl.LIME)
    else rl.DrawText("[F] FLAG_FULLSCREEN_MODE: off", 10, 80, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_RESIZABLE)) rl.DrawText("[R] FLAG_WINDOW_RESIZABLE: on", 10, 100, 10, rl.LIME)
    else rl.DrawText("[R] FLAG_WINDOW_RESIZABLE: off", 10, 100, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_UNDECORATED)) rl.DrawText("[D] FLAG_WINDOW_UNDECORATED: on", 10, 120, 10, rl.LIME)
    else rl.DrawText("[D] FLAG_WINDOW_UNDECORATED: off", 10, 120, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_HIDDEN)) rl.DrawText("[H] FLAG_WINDOW_HIDDEN: on", 10, 140, 10, rl.LIME)
    else rl.DrawText("[H] FLAG_WINDOW_HIDDEN: off", 10, 140, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_MINIMIZED)) rl.DrawText("[N] FLAG_WINDOW_MINIMIZED: on", 10, 160, 10, rl.LIME)
    else rl.DrawText("[N] FLAG_WINDOW_MINIMIZED: off", 10, 160, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_MAXIMIZED)) rl.DrawText("[M] FLAG_WINDOW_MAXIMIZED: on", 10, 180, 10, rl.LIME)
    else rl.DrawText("[M] FLAG_WINDOW_MAXIMIZED: off", 10, 180, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_UNFOCUSED)) rl.DrawText("[G] FLAG_WINDOW_UNFOCUSED: on", 10, 200, 10, rl.LIME)
    else rl.DrawText("[U] FLAG_WINDOW_UNFOCUSED: off", 10, 200, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST)) rl.DrawText("[T] FLAG_WINDOW_TOPMOST: on", 10, 220, 10, rl.LIME)
    else rl.DrawText("[T] FLAG_WINDOW_TOPMOST: off", 10, 220, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_ALWAYS_RUN)) rl.DrawText("[A] FLAG_WINDOW_ALWAYS_RUN: on", 10, 240, 10, rl.LIME)
    else rl.DrawText("[A] FLAG_WINDOW_ALWAYS_RUN: off", 10, 240, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_VSYNC_HINT)) rl.DrawText("[V] FLAG_VSYNC_HINT: on", 10, 260, 10, rl.LIME)
    else rl.DrawText("[V] FLAG_VSYNC_HINT: off", 10, 260, 10, rl.MAROON);

    rl.DrawText("Following flags can only be set before window creation:", 10, 300, 10, rl.GRAY);
    if (rl.IsWindowState(rl.FLAG_WINDOW_HIGHDPI)) rl.DrawText("FLAG_WINDOW_HIGHDPI: on", 10, 320, 10, rl.LIME)
    else rl.DrawText("FLAG_WINDOW_HIGHDPI: off", 10, 320, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_WINDOW_TRANSPARENT)) rl.DrawText("FLAG_WINDOW_TRANSPARENT: on", 10, 340, 10, rl.LIME)
    else rl.DrawText("FLAG_WINDOW_TRANSPARENT: off", 10, 340, 10, rl.MAROON);
    if (rl.IsWindowState(rl.FLAG_MSAA_4X_HINT)) rl.DrawText("FLAG_MSAA_4X_HINT: on", 10, 360, 10, rl.LIME)
    else rl.DrawText("FLAG_MSAA_4X_HINT: off", 10, 360, 10, rl.MAROON);

    rl.EndDrawing();
    //-----------------------------------------------------
  }

  // De-Initialization
  //---------------------------------------------------------
  rl.CloseWindow();        // Close window and OpenGL context
  //---------------------------------------------------------

  return 0;
}
