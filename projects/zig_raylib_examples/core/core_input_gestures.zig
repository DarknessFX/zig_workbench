//!zig-autodoc-section: core_2d_camera.Main
//! raylib_examples/core_2d_camera.zig
//!   Example - 2D Camera system.
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
  const MAX_GESTURE_STRINGS: usize = 20;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - input gestures");

  var touchPosition: rl.Vector2 = .{ .x = 0, .y = 0 };
  const touchArea: rl.Rectangle = .{ .x = 220, .y = 10, .width = toFloat(screenWidth) - 230.0, .height = toFloat(screenHeight) - 20.0 };

  var gesturesCount: usize = 0;
  const gestureStrings: [MAX_GESTURE_STRINGS][*c]u8 = std.mem.zeroes([MAX_GESTURE_STRINGS][*c]u8);

  var currentGesture = rl.GESTURE_NONE;
  var lastGesture = rl.GESTURE_NONE;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    lastGesture = currentGesture;
    currentGesture = rl.GetGestureDetected();
    touchPosition = rl.GetTouchPosition(0);

    if (rl.CheckCollisionPointRec(touchPosition, touchArea) and currentGesture != rl.GESTURE_NONE) {
      if (currentGesture != lastGesture) {
        // Store gesture string
        switch (currentGesture) {
          rl.GESTURE_TAP => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE TAP"); },
          rl.GESTURE_DOUBLETAP => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE DOUBLETAP"); },
          rl.GESTURE_HOLD => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE HOLD"); },
          rl.GESTURE_DRAG => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE DRAG"); },
          rl.GESTURE_SWIPE_RIGHT => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE RIGHT"); },
          rl.GESTURE_SWIPE_LEFT => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE LEFT"); },
          rl.GESTURE_SWIPE_UP => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE UP"); },
          rl.GESTURE_SWIPE_DOWN => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE DOWN"); },
          rl.GESTURE_PINCH_IN => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE PINCH IN"); },
          rl.GESTURE_PINCH_OUT => { _ = rl.TextCopy(gestureStrings[gesturesCount], "GESTURE PINCH OUT"); },
          else => {},
        }

        gesturesCount += 1;

        // Reset gestures strings
        if (gesturesCount >= MAX_GESTURE_STRINGS) {
          for (0..MAX_GESTURE_STRINGS) |i| {
            _ = rl.TextCopy(gestureStrings[i], '0');
          }
          gesturesCount = 0;
        }
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

      rl.ClearBackground(rl.RAYWHITE);

      rl.DrawRectangleRec(touchArea, rl.GRAY);
      rl.DrawRectangle(225, 15, screenWidth - 240, screenHeight - 30, rl.RAYWHITE);

      rl.DrawText("GESTURES TEST AREA", screenWidth - 270, screenHeight - 40, 20, rl.Fade(rl.GRAY, 0.5));

      for (0..MAX_GESTURE_STRINGS) |i| {
        if (i % 2 == 0) rl.DrawRectangle(10, @intCast(30 + 20 * i), 200, 20, rl.Fade(rl.LIGHTGRAY, 0.5))
        else rl.DrawRectangle(10, @intCast(30 + 20 * i), 200, 20, rl.Fade(rl.LIGHTGRAY, 0.3));

        if (gesturesCount > 0) {
          if (i < gesturesCount - 1) rl.DrawText(gestureStrings[i], 35, @intCast(36 + 20 * i), 10, rl.DARKGRAY)
          else rl.DrawText(gestureStrings[i], 35, @intCast(36 + 20 * i), 10, rl.MAROON);
        }
      }

      rl.DrawRectangleLines(10, 29, 200, screenHeight - 50, rl.GRAY);
      rl.DrawText("DETECTED GESTURES", 50, 15, 10, rl.GRAY);

      if (currentGesture != rl.GESTURE_NONE) rl.DrawCircleV(touchPosition, 30, rl.MAROON);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}