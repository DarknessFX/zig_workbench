//!zig-autodoc-section: audio_sound_loading.Main
//! raylib_examples/audio_sound_loading.zig
//!   Example - Sound loading and playing.
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

const PLAYER_SIZE: f32 = 40.0;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - sound loading and playing");

  rl.InitAudioDevice(); // Initialize audio device

  const fxWav = rl.LoadSound(getPath("audio/resources/sound.wav"));  // Load WAV audio file
  const fxOgg = rl.LoadSound(getPath("audio/resources/target.ogg")); // Load OGG audio file

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsKeyPressed(rl.KEY_SPACE)) rl.PlaySound(fxWav); // Play WAV sound
    if (rl.IsKeyPressed(rl.KEY_ENTER)) rl.PlaySound(fxOgg); // Play OGG sound
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("Press SPACE to PLAY the WAV sound!", 200, 180, 20, rl.LIGHTGRAY);
    rl.DrawText("Press ENTER to PLAY the OGG sound!", 200, 220, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadSound(fxWav); // Unload sound data
  rl.UnloadSound(fxOgg); // Unload sound data

  rl.CloseAudioDevice(); // Close audio device

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
fn getPath(file: []const u8) [*c]const u8 {
  // Get current folder
  const cwd: []u8 = std.process.getCwd(
    std.heap.page_allocator.alloc(u8, 256) catch unreachable)
    catch unreachable;
  defer std.heap.page_allocator.free(cwd);
  var file_fix = file[0..];
  while (std.mem.indexOf(u8, file_fix, "/")) |idx| {
    const file_pre = file_fix[0..idx];
    const file_pos = file_fix[idx + 1..];
    file_fix = std.mem.join(
      std.heap.page_allocator, 
      "\\", 
      &[_][]const u8{ file_pre, file_pos }) catch unreachable;
  }
  defer std.heap.page_allocator.free(file_fix);
  return @ptrCast(std.fs.path.join(std.heap.page_allocator, &.{ cwd, file_fix }) catch unreachable);
}
