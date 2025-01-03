//!zig-autodoc-section: core_input_multitouch.Main
//! raylib_examples/core_input_multitouch.zig
//!   Example - Input multitouch.
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
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}

const MAX_TOUCH_POINTS = 10;
//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - input multitouch");

  var touchPositions: [MAX_TOUCH_POINTS]rl.Vector2 = undefined;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    var tCount: usize = @as(usize, @intCast(rl.GetTouchPointCount()));
    // Clamp touch points available ( set the maximum touch points allowed )
    if (tCount > MAX_TOUCH_POINTS) tCount = MAX_TOUCH_POINTS;
    // Get touch points positions
    for (0..tCount) |i| {
      touchPositions[i] = rl.GetTouchPosition(@as(c_int, @intCast(i)));
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    for (0..tCount) |i| {
      // Make sure point is not (0, 0) as this means there is no touch for it
      if (touchPositions[i].x > 0 and touchPositions[i].y > 0) {
        // Draw circle and touch index number
        rl.DrawCircleV(touchPositions[i], 34, rl.ORANGE);
        rl.DrawText(rl.TextFormat("{}", i), toInt(touchPositions[i].x - 10.0), toInt(touchPositions[i].y - 70.0), 40, rl.BLACK);
      }
    }

    rl.DrawText("touch the screen at multiple locations to get multiple balls", 10, 10, 20, rl.DARKGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}