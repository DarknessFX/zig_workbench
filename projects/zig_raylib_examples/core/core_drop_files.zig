//!zig-autodoc-section: core_drop_files.Main
//! raylib_examples/core_drop_files.zig
//!   Example - Windows drop files.
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

const MAX_FILEPATH_RECORDED: c_int = 4096;
const MAX_FILEPATH_SIZE: c_int = 2048;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - drop files");

  var filePathCounter: i32 = 0;
  var filePaths: [MAX_FILEPATH_RECORDED][*c]u8 = undefined;

  // // Allocate space for file paths
  for (0..@intCast(filePathCounter)) |idx| {
    filePaths[idx] = @ptrCast(rl.RL_CALLOC(MAX_FILEPATH_SIZE, 1));
  }

  // Allocate space for the required file paths
  for (0..MAX_FILEPATH_RECORDED) |i| {
    filePaths[i] = @ptrCast(std.heap.page_allocator.alloc(u8, MAX_FILEPATH_SIZE) catch unreachable);
  }

  rl.SetTargetFPS(60);

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    if (rl.IsFileDropped()) {
      const droppedFiles = rl.LoadDroppedFiles();

      const offset: usize = @intCast(filePathCounter);
      for (0..droppedFiles.count) |idx| {
        if (filePathCounter < MAX_FILEPATH_RECORDED - 1) {
          _ = rl.TextCopy(filePaths[offset + idx], droppedFiles.paths[idx]);
          filePathCounter += 1;
        }
      }

      rl.UnloadDroppedFiles(droppedFiles);
    }

    // Draw
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    if (filePathCounter == 0) {
      rl.DrawText("Drop your files to this window!", 100, 40, 20, rl.DARKGRAY);
    } else {
      rl.DrawText("Dropped files:", 100, 40, 20, rl.DARKGRAY);

      for (0..@intCast(filePathCounter)) |idx| {
        const i: i32 = @intCast(idx);
        if (@mod(i, 2) == 0) {
          rl.DrawRectangle(0, 85 + 40 * i, screenWidth, 40, rl.Fade(rl.LIGHTGRAY, 0.5));
        } else {
          rl.DrawRectangle(0, 85 + 40 * i, screenWidth, 40, rl.Fade(rl.LIGHTGRAY, 0.3));
        }
        rl.DrawText(filePaths[idx], 120, 100 + 40 * i, 10, rl.GRAY);
      }

      rl.DrawText("Drop new files...", 100, 110 + 40 * filePathCounter, 20, rl.DARKGRAY);
    }

    rl.EndDrawing();
  }

  // De-Initialization
  // for (0..@intCast(filePathCounter)) |idx| {
  //  C
  //   rl.RL_FREE(filePaths[idx]);
  //  Zig
  //   std.heap.page_allocator.free(filePaths[idx]);
  // }

  rl.CloseWindow();
  return 0;
}