//!zig-autodoc-section: Base.Main
//! Base//main.zig :
//!   Template for a console program.

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib.h"); 
const rl = @cImport({
  @cInclude("lib/raylib/raylib.h");
});
const gl = @cImport({
  @cInclude("lib/raylib/rlgl.h");
});
const rm = @cImport({
  @cInclude("lib/raylib/raymath.h");
});

const WINDOW_WIDTH: usize  = 1280;
const WINDOW_HEIGHT: usize = 720;

/// Main function
pub fn main() void {
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "rllib [core] example - basic window");

  while (!rl.WindowShouldClose())
  {
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);
    rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
    rl.EndDrawing();
  }

  rl.CloseWindow();
}

// ============================================================================
// Helpers
//

// ============================================================================
// Tests
//
