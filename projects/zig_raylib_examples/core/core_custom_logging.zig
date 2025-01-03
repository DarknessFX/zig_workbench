//!zig-autodoc-section: core_custom_logging.Main
//! raylib_examples/core_custom_logging.zig
//!   Example - Custom logging.
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

// Custom logging function
fn CustomLog(msgType: i32, text: [*c]const u8, args: [*c]u8) callconv(.C) void {
  const stdio = @cImport({ @cInclude("stdio.h"); });
  const time = @cImport({ @cInclude("time.h"); });

  const now: time.time_t = time.time(null);
  const tm_info = time.localtime(&now);
  const timeStr_len = 20;
  var timeStr: [timeStr_len]u8 = undefined;
  _ = time.strftime(&timeStr, timeStr_len, "%Y-%m-%d %H:%M:%S", tm_info);
  std.debug.print("[{s}] ", .{timeStr});

  switch (msgType) {
    1 => std.debug.print("[INFO] : ", .{}),
    2 => std.debug.print("[ERROR]: ", .{}),
    3 => std.debug.print("[WARN] : ", .{}),
    4 => std.debug.print("[DEBUG]: ", .{}),
    else => {},
  }

  _ = stdio.vprintf(text, args);
  _ = stdio.printf("\n");
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  // Set custom logger
  rl.SetTraceLogCallback(CustomLog);

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - custom logging");

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("Check out the console output to see the custom logger in action!", 60, 200, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}