//!zig-autodoc-section: audio_music_stream.Main
//! raylib_examples/audio_music_stream.zig
//!   Example - Music playing (streaming).
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

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - music playing (streaming)");

  rl.InitAudioDevice(); // Initialize audio device

  const music = rl.LoadMusicStream("audio/resources/country.mp3");

  rl.PlayMusicStream(music);

  var timePlayed: f32 = 0.0; // Time played normalized [0.0f..1.0f]
  var pause: bool = false; // Music playing paused

  rl.SetTargetFPS(30); // Set our game to run at 30 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateMusicStream(music); // Update music buffer with new stream data

    // Restart music playing (stop and play)
    if (rl.IsKeyPressed(rl.KEY_SPACE)) {
      rl.StopMusicStream(music);
      rl.PlayMusicStream(music);
    }

    // Pause/Resume music playing
    if (rl.IsKeyPressed(rl.KEY_P)) {
      pause = !pause;
      if (pause) rl.PauseMusicStream(music)
      else rl.ResumeMusicStream(music);
    }

    // Get normalized time played for current music stream
    timePlayed = rl.GetMusicTimePlayed(music) / rl.GetMusicTimeLength(music);

    if (timePlayed > 1.0) timePlayed = 1.0; // Make sure time played is no longer than music
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("MUSIC SHOULD BE PLAYING!", 255, 150, 20, rl.LIGHTGRAY);

    rl.DrawRectangle(200, 200, 400, 12, rl.LIGHTGRAY);
    rl.DrawRectangle(200, 200, toInt(timePlayed) * 400, 12, rl.MAROON);
    rl.DrawRectangleLines(200, 200, 400, 12, rl.GRAY);

    rl.DrawText("PRESS SPACE TO RESTART MUSIC", 215, 250, 20, rl.LIGHTGRAY);
    rl.DrawText("PRESS P TO PAUSE/RESUME MUSIC", 208, 280, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadMusicStream(music); // Unload music stream buffers from RAM

  rl.CloseAudioDevice(); // Close audio device (music streaming is automatically stopped)

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
