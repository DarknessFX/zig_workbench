//!zig-autodoc-section: Base.Main
//! Base//main.zig :
//!   Template for a console program.

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("D:/workbench/Zig/BaseRayLib/lib/raylib/raylib.h"); 
});
const gl = @cImport({ @cInclude("D:/workbench/Zig/BaseRayLib/lib/raylib/rlgl.h"); });
const rm = @cImport({ @cInclude("D:/workbench/Zig/BaseRayLib/lib/raylib/raymath.h"); });
const ui = @cImport({ 
  @cDefine("RAYGUI_IMPLEMENTATION","");
  @cInclude("D:/workbench/Zig/BaseRayLib/lib/raylib/raygui.h"); 
});

const WINDOW_WIDTH: usize  = 1280;
const WINDOW_HEIGHT: usize = 720;

/// Main function
pub fn main() void {
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raylib [core] example + raygui - basic window");
  rl.SetTargetFPS(60);

  var showMessageBox: bool = true;

  while (!rl.WindowShouldClose())
  {
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    if (ui.GuiButton(ui.Rectangle{ .x=24, .y=24, .width=120,.height=30 }, "#191#Show Message") != 0) showMessageBox = true;

    if (showMessageBox) {
      const result: c_int = ui.GuiMessageBox(ui.Rectangle{ .x=85, .y=70, .width=250,.height=100 },
        "#191#Message Box", "Hi! This is a message!", "Nice;Cool");
      if (result >= 0) showMessageBox = false;
    }

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
