//!zig-autodoc-section: core_input_virtual_controls.Main
//! raylib_examples/core_input_virtual_controls.zig
//!   Example - input virtual controls.
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

const BUTTON_NONE: c_int = -1;
const BUTTON_UP: c_int = 0;
const BUTTON_LEFT: c_int = 1;
const BUTTON_RIGHT: c_int = 2;
const BUTTON_DOWN: c_int = 3;
const BUTTON_MAX: usize = 4;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - input virtual controls");

  const padPosition: rl.Vector2 = .{ .x=100.0, .y=350.0 };
  const buttonRadius: f32 = 30.0;

  const buttonPositions: [BUTTON_MAX]rl.Vector2 = .{
    .{ .x = padPosition.x, .y = padPosition.y - buttonRadius * 1.5}, // Up
    .{ .x = padPosition.x - buttonRadius * 1.5, .y = padPosition.y}, // Left
    .{ .x = padPosition.x + buttonRadius * 1.5, .y = padPosition.y}, // Right
    .{ .x = padPosition.x, .y = padPosition.y + buttonRadius * 1.5}, // Down
  };

  const buttonLabels: [BUTTON_MAX][]const u8 = .{
    "Y", // Up
    "X", // Left
    "B", // Right
    "A", // Down
  };

  const buttonLabelColors: [BUTTON_MAX]rl.Color = .{
    rl.YELLOW, // Up
    rl.BLUE,   // Left
    rl.RED,    // Right
    rl.GREEN,  // Down
  };

  var pressedButton: c_int = BUTTON_NONE;
  var inputPosition: rl.Vector2 = .{ .x = 0, .y = 0 };

  var playerPosition: rl.Vector2 = .{ .x = toFloat(screenWidth) / 2.0, .y = toFloat(screenHeight) / 2.0 };
  const playerSpeed: f32 = 75.0;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //--------------------------------------------------------------------------

    if (rl.GetTouchPointCount() > 0) {
      // Use touch position
      inputPosition = rl.GetTouchPosition(0);
    } else {
      // Use mouse position
      inputPosition = rl.GetMousePosition();
    }

    // Reset pressed button to none
    pressedButton = BUTTON_NONE;

    // Make sure user is pressing left mouse button if they're from desktop
    if (rl.GetTouchPointCount() > 0 or (rl.GetTouchPointCount() == 0 and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT))) {
      // Find nearest D-Pad button to the input position
      for (0..BUTTON_MAX) |i| {
        const distX = @abs(buttonPositions[i].x - inputPosition.x);
        const distY = @abs(buttonPositions[i].y - inputPosition.y);

        if (distX + distY < buttonRadius) {
          pressedButton = @intCast(i);
          break;
        }
      }
    }

    // Move player according to pressed button
    switch (pressedButton) {
      BUTTON_UP => playerPosition.y -= playerSpeed * rl.GetFrameTime(),
      BUTTON_LEFT => playerPosition.x -= playerSpeed * rl.GetFrameTime(),
      BUTTON_RIGHT => playerPosition.x += playerSpeed * rl.GetFrameTime(),
      BUTTON_DOWN => playerPosition.y += playerSpeed * rl.GetFrameTime(),
      else => {},
    }
    //--------------------------------------------------------------------------

    // Draw
    //--------------------------------------------------------------------------

    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    // Draw world
    rl.DrawCircleV(playerPosition, 50, rl.MAROON);

    // Draw GUI
    for (0..BUTTON_MAX) |i| {
      rl.DrawCircleV(buttonPositions[i], buttonRadius, if (i == pressedButton) rl.DARKGRAY else rl.BLACK);
      rl.DrawText(buttonLabels[i].ptr, toInt(buttonPositions[i].x) - 7, toInt(buttonPositions[i].y) - 8, 20, buttonLabelColors[i]);
    }

    rl.DrawText("move the player with D-Pad buttons", 10, 10, 20, rl.DARKGRAY);

    rl.EndDrawing();
    //--------------------------------------------------------------------------

  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}