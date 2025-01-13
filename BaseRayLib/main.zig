//!zig-autodoc-section: BaseRayLib.Main
//! BaseRayLib//main.zig :
//!   Template using RayLib and RayGUI.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib/include/raylib.h"); 
const ray = @cImport({ 
  @cInclude("lib/raylib/include/raylib.h");
});
const web = if (@import("builtin").target.os.tag == .emscripten) {
  @cImport({
    @cInclude("emscripten/emscripten.h");
  });
} else undefined;

pub fn main() !void {
  ray.InitWindow(512, 512, "Raylib WASM Example");

  while (!ray.WindowShouldClose()) {
    ray.BeginDrawing();
    ray.ClearBackground(ray.BLACK);
    ray.DrawText("Hello Raylib Windows+Web", 10, 10, 32, ray.GREEN);
    ray.EndDrawing();
  }

  ray.CloseWindow();
}