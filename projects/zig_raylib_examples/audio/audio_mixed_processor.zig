//!zig-autodoc-section: audio_mixed_processor.Main
//! raylib_examples/audio_mixed_processor.zig
//!   Example - processing mixed output.
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
var exponent: f32 = 1.0; // Audio exponentiation value
var averageVolume: [400]f32 = [_]f32{ 0 } ** 400; // Average volume history

//------------------------------------------------------------------------------------
// Audio processing function
//------------------------------------------------------------------------------------
fn ProcessAudio(buffer: ?*anyopaque, frames: c_uint) callconv(.C) void {
  const samples: [*]f32 = @as([*]f32, @ptrCast(@alignCast(buffer.?)));
  var average: f32 = 0.0; // Temporary average volume

  var frame: c_uint = 0;
  var left: *f32 = undefined;
  var right: *f32 = undefined;
  while (frame < frames) {
    left = &samples[frame * 2];
    right = &samples[frame * 2 + 1];

    const left_scale: f32 = if (left.* < 0.0) -1.0 else 1.0;
    const right_scale: f32 = if (left.* < 0.0) -1.0 else 1.0;
    left.* = std.math.pow(f32, @abs(left.*), exponent) * left_scale;
    right.* = std.math.pow(f32, @abs(right.*), exponent) * right_scale;

    average += @abs(left.*) / @as(f32, @floatFromInt(frames));
    average += @abs(right.*) / @as(f32, @floatFromInt(frames));

    frame += 1;
  }

  // Moving history to the left
  for (0..399) |i| averageVolume[i] = averageVolume[i + 1];

  averageVolume[399] = average; // Adding last average value
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - processing mixed output");

  rl.InitAudioDevice(); // Initialize audio device

  rl.AttachAudioMixedProcessor(ProcessAudio);

  const music = rl.LoadMusicStream("audio/resources/country.mp3");
  const sound = rl.LoadSound("audio/resources/coin.wav");

  rl.PlayMusicStream(music);

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateMusicStream(music); // Update music buffer with new stream data

    // Modify processing variables
    if (rl.IsKeyPressed(rl.KEY_LEFT)) exponent -= 0.05;
    if (rl.IsKeyPressed(rl.KEY_RIGHT)) exponent += 0.05;

    if (exponent <= 0.5) exponent = 0.5;
    if (exponent >= 3.0) exponent = 3.0;

    if (rl.IsKeyPressed(rl.KEY_SPACE)) rl.PlaySound(sound);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("MUSIC SHOULD BE PLAYING!", 255, 150, 20, rl.LIGHTGRAY);

    rl.DrawText(rl.TextFormat("EXPONENT = %.2f", exponent), 215, 180, 20, rl.LIGHTGRAY);

    rl.DrawRectangle(199, 199, 402, 34, rl.LIGHTGRAY);
    for (0..400) |i| {
      const ci: c_int = @intCast(i);
      rl.DrawLine(
        201 +% ci, 
        232 -% (toInt(averageVolume[i]) *% 32), 
        201 +% ci, 232, rl.MAROON);
    }
    rl.DrawRectangleLines(199, 199, 402, 34, rl.GRAY);

    rl.DrawText("PRESS SPACE TO PLAY OTHER SOUND", 200, 250, 20, rl.LIGHTGRAY);
    rl.DrawText("USE LEFT AND RIGHT ARROWS TO ALTER DISTORTION", 140, 280, 20, rl.LIGHTGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadMusicStream(music); // Unload music stream buffers from RAM

  rl.DetachAudioMixedProcessor(ProcessAudio); // Disconnect audio processor

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
