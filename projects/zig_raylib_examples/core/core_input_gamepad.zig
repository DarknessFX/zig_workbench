//!zig-autodoc-section: core_input_gamepad.Main
//! raylib_examples/core_input_gamepad.zig
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
});

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }

const XBOX_ALIAS_1 = "xbox";
const XBOX_ALIAS_2 = "x-box";
const PS_ALIAS = "playstation";

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);  // Set MSAA 4X hint before windows creation

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - gamepad input");

  const cwd = std.process.getCwd(std.heap.page_allocator.alloc(u8, 256) catch unreachable) catch unreachable;
  const res1 = fmt("{s}\\core\\{s}", .{ cwd, "resources/ps3.png" });
  const res2 = fmt("{s}\\core\\{s}", .{ cwd, "resources/xbox.png" });
  const texPs3Pad = rl.LoadTexture(res1.ptr);
  const texXboxPad = rl.LoadTexture(res2.ptr);

  // Set axis deadzones
  const leftStickDeadzoneX = 0.1;
  const leftStickDeadzoneY = 0.1;
  const rightStickDeadzoneX = 0.1;
  const rightStickDeadzoneY = 0.1;
  const leftTriggerDeadzone = -0.9;
  const rightTriggerDeadzone = -0.9;

  rl.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  var gamepad: i32 = 0; // which gamepad to display

  // Main game loop
  while (!rl.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // ...
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    if (rl.IsKeyPressed(rl.KEY_LEFT) and gamepad > 0) gamepad -= 1;
    if (rl.IsKeyPressed(rl.KEY_RIGHT)) gamepad += 1;

    if (rl.IsGamepadAvailable(gamepad)) {
      rl.DrawText(rl.TextFormat("GP%d: %s", gamepad, rl.GetGamepadName(gamepad)), 10, 10, 10, rl.BLACK);

      // Get axis values
      var leftStickX = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_LEFT_X);
      var leftStickY = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_LEFT_Y);
      var rightStickX = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_RIGHT_X);
      var rightStickY = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_RIGHT_Y);
      var leftTrigger = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_LEFT_TRIGGER);
      var rightTrigger = rl.GetGamepadAxisMovement(gamepad, rl.GAMEPAD_AXIS_RIGHT_TRIGGER);

      // Calculate deadzones
      if (leftStickX > -leftStickDeadzoneX and leftStickX < leftStickDeadzoneX) leftStickX = 0.0;
      if (leftStickY > -leftStickDeadzoneY and leftStickY < leftStickDeadzoneY) leftStickY = 0.0;
      if (rightStickX > -rightStickDeadzoneX and rightStickX < rightStickDeadzoneX) rightStickX = 0.0;
      if (rightStickY > -rightStickDeadzoneY and rightStickY < rightStickDeadzoneY) rightStickY = 0.0;
      if (leftTrigger < leftTriggerDeadzone) leftTrigger = -1.0;
      if (rightTrigger < rightTriggerDeadzone) rightTrigger = -1.0;

      if (rl.TextFindIndex(rl.TextToLower(rl.GetGamepadName(gamepad)), XBOX_ALIAS_1) > -1 or rl.TextFindIndex(rl.TextToLower(rl.GetGamepadName(gamepad)), XBOX_ALIAS_2) > -1) {
        rl.DrawTexture(texXboxPad, 0, 0, rl.DARKGRAY);

        // Draw buttons: xbox home
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE)) rl.DrawCircle(394, 89, 19, rl.RED);

        // Draw buttons: basic
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE_RIGHT)) rl.DrawCircle(436, 150, 9, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE_LEFT)) rl.DrawCircle(352, 150, 9, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) rl.DrawCircle(501, 151, 15, rl.BLUE);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) rl.DrawCircle(536, 187, 15, rl.LIME);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) rl.DrawCircle(572, 151, 15, rl.MAROON);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_UP)) rl.DrawCircle(536, 115, 15, rl.GOLD);

        // Draw buttons: d-pad
        rl.DrawRectangle(317, 202, 19, 71, rl.BLACK);
        rl.DrawRectangle(293, 228, 69, 19, rl.BLACK);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_UP)) rl.DrawRectangle(317, 202, 19, 26, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) rl.DrawRectangle(317, 202 + 45, 19, 26, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) rl.DrawRectangle(292, 228, 25, 19, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) rl.DrawRectangle(292 + 44, 228, 26, 19, rl.RED);

        // Draw buttons: left-right back
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_TRIGGER_1)) rl.DrawCircle(259, 61, 20, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) rl.DrawCircle(536, 61, 20, rl.RED);

        // Draw axis: left joystick
        var leftGamepadColor = rl.BLACK;
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_THUMB)) leftGamepadColor = rl.RED;
        rl.DrawCircle(259, 152, 39, rl.BLACK);
        rl.DrawCircle(259, 152, 34, rl.LIGHTGRAY);
        rl.DrawCircle(259 + toInt(leftStickX * 20), 152 + toInt(leftStickY * 20), 25, leftGamepadColor);

        // Draw axis: right joystick
        var rightGamepadColor = rl.BLACK;
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_THUMB)) rightGamepadColor = rl.RED;
        rl.DrawCircle(461, 237, 38, rl.BLACK);
        rl.DrawCircle(461, 237, 33, rl.LIGHTGRAY);
        rl.DrawCircle(461 + toInt(rightStickX * 20), 237 + toInt(rightStickY * 20), 25, rightGamepadColor);

        // Draw axis: left-right triggers
        rl.DrawRectangle(170, 30, 15, 70, rl.GRAY);
        rl.DrawRectangle(604, 30, 15, 70, rl.GRAY);
        rl.DrawRectangle(170, 30, 15, toInt(((1.0 + leftTrigger) / 2.0) * 70), rl.RED);
        rl.DrawRectangle(604, 30, 15, toInt(((1.0 + rightTrigger) / 2.0) * 70), rl.RED);
      } else if (rl.TextFindIndex(rl.TextToLower(rl.GetGamepadName(gamepad)), PS_ALIAS) > -1) {
        rl.DrawTexture(texPs3Pad, 0, 0, rl.DARKGRAY);

        // Draw buttons: ps
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE)) rl.DrawCircle(396, 222, 13, rl.RED);

        // Draw buttons: basic
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE_LEFT)) rl.DrawRectangle(328, 170, 32, 13, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_MIDDLE_RIGHT)) rl.DrawTriangle(rl.Vector2{ .x = 436, .y = 168 }, rl.Vector2{ .x = 436, .y = 185 }, rl.Vector2{ .x = 464, .y = 177 }, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_UP)) rl.DrawCircle(557, 144, 13, rl.LIME);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) rl.DrawCircle(586, 173, 13, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) rl.DrawCircle(557, 203, 13, rl.VIOLET);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) rl.DrawCircle(527, 173, 13, rl.PINK);

        // Draw buttons: d-pad
        rl.DrawRectangle(225, 132, 24, 84, rl.BLACK);
        rl.DrawRectangle(195, 161, 84, 25, rl.BLACK);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_UP)) rl.DrawRectangle(225, 132, 24, 29, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) rl.DrawRectangle(225, 132 + 54, 24, 30, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) rl.DrawRectangle(195, 161, 30, 25, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) rl.DrawRectangle(195 + 54, 161, 30, 25, rl.RED);

        // Draw buttons: left-right back buttons
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_LEFT_TRIGGER_1)) rl.DrawCircle(198, 81, 20, rl.RED);
        if (rl.IsGamepadButtonDown(gamepad, rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) rl.DrawCircle(507, 81, 20, rl.RED);

        // Draw axis: left joystick
        rl.DrawCircle(227, 206, 38, rl.BLACK);
        rl.DrawCircle(227, 206, 33, rl.LIGHTGRAY);
        rl.DrawCircle(227 + toInt(leftStickX * 20), 206 + toInt(leftStickY * 20), 25, rl.BLACK);

        // Draw axis: right joystick
        rl.DrawCircle(544, 216, 38, rl.BLACK);
        rl.DrawCircle(544, 216, 33, rl.LIGHTGRAY);
        rl.DrawCircle(544 + toInt(rightStickX * 20), 216 + toInt(rightStickY * 20), 25, rl.BLACK);

        // Draw axis: left-right triggers
        rl.DrawRectangle(122, 58, 15, 65, rl.GRAY);
        rl.DrawRectangle(603, 58, 15, 65, rl.GRAY);
        rl.DrawRectangle(122, 58, 15, toInt(((1 + leftTrigger) / 2) * 65), rl.RED);
        rl.DrawRectangle(603, 58, 15, toInt(((1 + rightTrigger) / 2) * 65), rl.RED);
      }
    }

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadTexture(texPs3Pad);  // Unload texture
  rl.UnloadTexture(texXboxPad);  // Unload texture

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}
