//!zig-autodoc-section: audio_sound_multi.Main
//! raylib_examples/audio_sound_multi.zig
//!   Example - playing sound multiple times.
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
const MAX_SOUNDS: i32 = 10;
var soundArray: [MAX_SOUNDS]rl.Sound = undefined;
var currentSound: usize = 0;

pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - playing sound multiple times");

  rl.InitAudioDevice(); // Initialize audio device

  // Load the sound list
  soundArray[0] = rl.LoadSound(getPath("audio/resources/sound.wav")); // Load WAV audio file into the first slot as the 'source' sound
  for (0..MAX_SOUNDS) |i| {
    soundArray[i] = rl.LoadSoundAlias(soundArray[0]); // Load an alias of the sound into slots 1-9
  }
  currentSound = 0; // Set the sound list to the start

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (rl.IsKeyPressed(rl.KEY_SPACE)) {
      rl.PlaySound(soundArray[currentSound]); // Play the next open sound slot
      currentSound += 1; // Increment the sound slot
      if (currentSound >= MAX_SOUNDS) {
        currentSound = 0; // If the sound slot is out of bounds, go back to 0
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("Press SPACE to PLAY a WAV sound!", 200, 180, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  for (0..MAX_SOUNDS) |i| {
    rl.UnloadSoundAlias(soundArray[i]); // Unload sound aliases
  }
  rl.UnloadSound(soundArray[0]); // Unload source sound data

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
