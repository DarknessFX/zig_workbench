//!zig-autodoc-section: audio_stream_effects.Main
//! raylib_examples/audio_stream_effects.zig
//!   Example - Music stream processing effects.
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


//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
const delayBufferSize: u32 = 48000 * 2; // 1 second delay (device sampleRate * channels)
var delayBuffer: ?[*]f32 = null;
var delayReadIndex: u32 = 2;
var delayWriteIndex: u32 = 0;

pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - stream effects");
  rl.InitAudioDevice(); // Initialize audio device

  const music = rl.LoadMusicStream("audio/resources/country.mp3");

  // Allocate buffer for the delay effect
  delayBuffer = @as(?[*]f32, @ptrCast(@alignCast(
    rl.RL_CALLOC(delayBufferSize, @sizeOf(f32)).?)));

  rl.PlayMusicStream(music);

  var timePlayed: f32 = 0.0;       // Time played normalized [0.0f..1.0f]
  var pause = false;               // Music playing paused
  var enableEffectLPF = false;     // Enable effect low-pass-filter
  var enableEffectDelay = false;   // Enable effect delay (1 second)

  rl.SetTargetFPS(60);             // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {
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

    // Add/Remove effect: lowpass filter
    if (rl.IsKeyPressed(rl.KEY_F)) {
      enableEffectLPF = !enableEffectLPF;
      if (enableEffectLPF) rl.AttachAudioStreamProcessor(music.stream, audioProcessEffectLPF)
      else rl.DetachAudioStreamProcessor(music.stream, audioProcessEffectLPF);
    }

    // Add/Remove effect: delay
    if (rl.IsKeyPressed(rl.KEY_D)) {
      enableEffectDelay = !enableEffectDelay;
      if (enableEffectDelay) rl.AttachAudioStreamProcessor(music.stream, audioProcessEffectDelay)
      else rl.DetachAudioStreamProcessor(music.stream, audioProcessEffectDelay);
    }

    // Get normalized time played for current music stream
    timePlayed = rl.GetMusicTimePlayed(music) / rl.GetMusicTimeLength(music);

    if (timePlayed > 1.0) timePlayed = 1.0; // Make sure time played is no longer than music
    //----------------------------------------------------------------------------------
    // Draw
    //----------------------------------------------------------------------------------
    const enableEffectLPF_text: []const u8 = if (enableEffectLPF) "ON" else "OFF";
    const enableEffectDelay_text: []const u8 = if (enableEffectDelay) "ON" else "OFF";

    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("MUSIC SHOULD BE PLAYING!", 245, 150, 20, rl.LIGHTGRAY);
    rl.DrawRectangle(200, 180, 400, 12, rl.LIGHTGRAY);
    rl.DrawRectangle(200, 180, toInt(timePlayed * 400.0), 12, rl.MAROON);
    rl.DrawRectangleLines(200, 180, 400, 12, rl.GRAY);
    rl.DrawText("PRESS SPACE TO RESTART MUSIC", 215, 230, 20, rl.LIGHTGRAY);
    rl.DrawText("PRESS P TO PAUSE/RESUME MUSIC", 208, 260, 20, rl.LIGHTGRAY);
    rl.DrawText(
      rl.TextFormat("PRESS F TO TOGGLE LPF EFFECT: %s", enableEffectLPF_text.ptr),
      200, 320, 20, rl.GRAY
    );
    rl.DrawText(
      rl.TextFormat("PRESS D TO TOGGLE DELAY EFFECT: %s", enableEffectDelay_text.ptr),
      180, 350, 20, rl.GRAY
    );

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadMusicStream(music); // Unload music stream buffers from RAM

  rl.CloseAudioDevice(); // Close audio device (music streaming is automatically stopped)

  if (delayBuffer != null)  {
    rl.RL_FREE(delayBuffer);
    delayBuffer = null;
  }

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Module Functions Definition
//------------------------------------------------------------------------------------
fn audioProcessEffectLPF(buffer: ?*anyopaque, frames: c_uint) callconv(.C) void {
  // Static state variables for the lowpass filter
  var low = [_]f32{ 0.0, 0.0 } ** 1; // static float low[2] = { 0.0f, 0.0f };
  const cutoff: f32 = 70.0 / 44100.0; // 70 Hz lowpass filter
  const k: f32 = cutoff / (cutoff + 0.1591549431); // RC filter formula

  // Converts the buffer data before using it
  const data: [*]f32 = @as(?[*]f32, @ptrCast(@alignCast(buffer.?))) orelse return;

  var i: usize = 0;
  while (i < frames * 2) : (i += 2) {
    const l = data[i];
    const r = data[i + 1];

    // Apply lowpass filter to left and right channels
    low[0] += k * (l - low[0]);
    low[1] += k * (r - low[1]);

    // Update the buffer with filtered values
    data[i] = low[0];
    data[i + 1] = low[1];
  }
}

fn audioProcessEffectDelay(buffer: ?*anyopaque, frames: c_uint) callconv(.C) void {
  if (delayBuffer == null) return;
  const delayBuffer_ = delayBuffer.?;
  var i: usize = 0;
  while (i < frames * 2) : (i += 2) {
    // Read delay buffer values for left and right channels
    const leftDelay = delayBuffer_[delayReadIndex]; // ERROR: Reading buffer -> WHY??? Maybe thread related???
    delayReadIndex = (delayReadIndex + 1) % delayBufferSize;
    const rightDelay = delayBuffer_[delayReadIndex];
    delayReadIndex = (delayReadIndex + 1) % delayBufferSize;

    // Apply delay effect to buffer
    const data: [*]f32 = @as(?[*]f32, @ptrCast(@alignCast(buffer.?))) orelse return;
    data[i] = 0.5 * data[i] + 0.5 * leftDelay;
    data[i + 1] = 0.5 * data[i + 1] + 0.5 * rightDelay;

    // Write current buffer values into delay buffer
    delayBuffer_[delayWriteIndex] = data[i];
    delayWriteIndex = (delayWriteIndex + 1) % delayBufferSize;
    delayBuffer_[delayWriteIndex] = data[i + 1];
    delayWriteIndex = (delayWriteIndex + 1) % delayBufferSize;
  }
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
