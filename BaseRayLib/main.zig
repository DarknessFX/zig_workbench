//!zig-autodoc-section: BaseRayLib.Main
//! BaseRayLib//main.zig :
//!   Template using RayLib and RayGUI.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib/include/raylib.h"); 
const ray = @cImport({ 
  @cInclude("lib/raylib/include/raylib.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !void {
  ray.InitWindow(1280, 720, "Raylib");

  switch (@import("builtin").target.cpu.arch) {
    .wasm32 => { 
      const web = @cImport({ @cInclude("emscripten/emscripten.h"); });
      web.emscripten_set_main_loop(webLoop, 60, true); 
    },
    else => { loop(); },
  }

  ray.CloseWindow();
}

//#endregion ==================================================================
//#region MARK: LOOP
//=============================================================================
fn loop() callconv(.c) void {
  while (!ray.WindowShouldClose()) {
    ray.BeginDrawing();
    ray.ClearBackground(ray.BLACK);
    ray.DrawText("Hello Raylib Windows+Web", 10, 10, 32, ray.GREEN);
    ray.EndDrawing();
  }
}

fn webLoop() callconv(.c) void {
  ray.BeginDrawing();
  ray.ClearBackground(ray.BLACK);
  ray.DrawText("Hello Raylib Windows+Web", 10, 10, 32, ray.GREEN);
  ray.EndDrawing();
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================



//#endregion ==================================================================
//=============================================================================