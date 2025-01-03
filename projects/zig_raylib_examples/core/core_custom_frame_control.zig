//!zig-autodoc-section: core_custom_frame_control.Main
//! raylib_examples/core_custom_frame_control.zig
//!   Example - custom frame control.
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
  var screenWidth: c_int = 800;
  var screenHeight: c_int = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - custom frame control");

  // Custom timming variables
  var previousTime: f64 = rl.GetTime();    // Previous time measure
  var currentTime: f64 = 0.0;              // Current time measure
  var updateDrawTime: f64 = 0.0;           // Update + Draw time
  var waitTime: f64 = 0.0;                 // Wait time (if target fps required)
  var deltaTime: f64 = 0.0;                // Frame time (Update + Draw + Wait time)
  var timeCounter: f64 = 0.0;              // Accumulative time counter (seconds)

  var position: f32 = 0.0;                 // Circle position
  var pause = false;                       // Pause control flag

  var targetFPS: c_int = 60;               // Our initial target fps
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {    // Detect window close button or ESC key
    // Helper to avoid keep convering to floats or ints.
    screenWidth = rl.GetScreenWidth();
    screenHeight = rl.GetScreenHeight();
    const fScreenWidth: f32 = toFloat(rl.GetScreenWidth());
    const fScreenHeight: f32 = toFloat(rl.GetScreenHeight());
    const iPosition: c_int = toInt(position);

    // Update
    //----------------------------------------------------------------------------------
    rl.PollInputEvents();             // Poll input events (SUPPORT_CUSTOM_FRAME_CONTROL)

    if (rl.IsKeyPressed(rl.KEY_SPACE)) pause = !pause;

    if (rl.IsKeyPressed(rl.KEY_UP)) targetFPS += 20
    else if (rl.IsKeyPressed(rl.KEY_DOWN)) targetFPS -= 20;

    if (targetFPS < 0) targetFPS = 0;

    if (!pause) {
      position += @floatCast(200.0 * deltaTime);  // We move at 200 pixels per second
      if (position >= fScreenWidth) position = 0;
      timeCounter += deltaTime;     // We count time (seconds)
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    for (0..@intCast(@divFloor(screenWidth, 200))) |idx| {
      const i: c_int = @intCast(idx);
      rl.DrawRectangle(200 * i, 0, 1, screenHeight, rl.SKYBLUE);
    }

    rl.DrawCircle(iPosition, toInt(fScreenHeight / 2.0) - 25, 50, rl.RED);

    rl.DrawText(rl.TextFormat("%03.0f ms", timeCounter * 1000.0), iPosition - 40, toInt(fScreenWidth / 2.0) - 100, 20, rl.MAROON);
    rl.DrawText(rl.TextFormat("PosX: %03.0f", position), iPosition - 50, toInt(fScreenWidth / 2.0) - 60, 20, rl.BLACK);

    const fdeltaTime: f32 = @floatCast(1.0 / deltaTime);

    rl.DrawText("Circle is moving at a constant 200 pixels/sec,\nindependently of the frame rate.", 10, 10, 20, rl.DARKGRAY);
    rl.DrawText("PRESS SPACE to PAUSE MOVEMENT", 10, screenHeight - 60, 20, rl.GRAY);
    rl.DrawText("PRESS UP | DOWN to CHANGE TARGET FPS", 10, screenHeight - 30, 20, rl.GRAY);
    rl.DrawText(rl.TextFormat("TARGET FPS: %i", targetFPS), screenWidth - 220, 10, 20, rl.LIME);
    rl.DrawText(rl.TextFormat("CURRENT FPS: %i", fdeltaTime ), screenWidth - 220, 40, 20, rl.GREEN);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------

    // NOTE: In case raylib is configured to SUPPORT_CUSTOM_FRAME_CONTROL,
    // Events polling, screen buffer swap and frame time control must be managed by the user

    //rl.SwapScreenBuffer();           // Flip the back buffer to screen (front buffer)

    currentTime = rl.GetTime();
    updateDrawTime = currentTime - previousTime;

    if (targetFPS > 0) {             // We want a fixed frame rate
      waitTime = @as(f64, @floatCast(1.0 / toFloat(targetFPS))) - updateDrawTime;
      if (waitTime > 0.0) {
        rl.WaitTime(waitTime);
        currentTime = rl.GetTime();
        deltaTime = currentTime - previousTime;
      }
    } else {
      deltaTime = updateDrawTime;  // Framerate could be variable
    }

    previousTime = currentTime;
    //std.debug.print("{d}\n", .{deltaTime});
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow();       // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}