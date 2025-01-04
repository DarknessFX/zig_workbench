//!zig-autodoc-section: audio_raw_stream.Main
//! raylib_examples/audio_raw_stream.zig
//!   Example - Raw audio streaming.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");
const math = @import("std").math;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h");
  @cInclude("stdlib.h");  
});

const MAX_SAMPLES = 512;
const MAX_SAMPLES_PER_UPDATE = 4096;

// Global state variables
var frequency: f32 = 440.0; // Cycles per second (hz)
var audioFrequency: f32 = 440.0; // Smoothed frequency
var oldFrequency: f32 = 1.0; // Previous frequency value
var sineIdx: f32 = 0.0; // Index for audio rendering

fn audioInputCallback(buffer: ?*anyopaque, frames: c_uint) callconv(.C) void {
  // Smooth frequency modulation
  audioFrequency = frequency + (audioFrequency - frequency) * 0.95;
  const incr = audioFrequency / 44100.0;

  // Cast buffer to short array and process samples
  var data: [*]f16 = @as(?[*]f16, @ptrCast(@alignCast(buffer.?))) orelse return;

  for (0..frames) |i| {
    data[i] = @floatCast(32000.0 * math.sin(2.0 * math.pi * sineIdx));
    sineIdx += incr;
    if (sineIdx > 1.0) sineIdx -= 1.0;
  }
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - raw audio streaming");

  rl.InitAudioDevice(); // Initialize audio device

  rl.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE);

  // Init raw audio stream (sample rate: 44100, sample size: 16bit-short, channels: 1-mono)
  const stream = rl.LoadAudioStream(44100, 16, 1);

  rl.SetAudioStreamCallback(stream, audioInputCallback);

  // Buffer for the single cycle waveform we are synthesizing
  const data = rl.RL_CALLOC(MAX_SAMPLES, @sizeOf(f16)) orelse return 1;
  
  // Frame buffer, describing the waveform when repeated over the course of a frame
  const writeBuf = rl.RL_CALLOC(MAX_SAMPLES_PER_UPDATE, @sizeOf(f16)) orelse return 2;

  rl.PlayAudioStream(stream); // Start processing stream buffer (no data loaded currently)

  // Position read in to determine next frequency
  var mousePosition = rl.Vector2{ .x = -100.0, .y = -100.0 };

  // Cycles per second (hz)
  // float frequency = 440.0f;

  // Previous value, used to test if sine needs to be rewritten, and to smoothly modulate frequency
  // float oldFrequency = 1.0f;

  // Cursor to read and copy the samples of the sine wave buffer
  //var readCursor: i32 = 0;

  // Computed size in samples of the sine wave
  var waveLength: i32 = 1;

  var position = rl.Vector2{ .x = 0, .y = 0 };

  rl.SetTargetFPS(30); // Set our game to run at 30 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------

    // Sample mouse input.
    mousePosition = rl.GetMousePosition();

    if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
      const fp = mousePosition.y;
      frequency = 40.0 + fp;

      const pan = mousePosition.x / toFloat(screenWidth);
      rl.SetAudioStreamPan(stream, pan);
    }

    // Rewrite the sine wave
    // Compute two cycles to allow the buffer padding, simplifying any modulation, resampling, etc.
    if (frequency != oldFrequency) {
      // Compute wavelength. Limit size in both directions.
      // int oldWavelength = waveLength;
      waveLength = toInt(22050.0 / frequency);
      if (waveLength > MAX_SAMPLES / 2) waveLength = MAX_SAMPLES / 2;
      if (waveLength < 1) waveLength = 1;

      var data_: [*]f16 = @as(?[*]f16, @ptrCast(@alignCast(data))) orelse return 3;
      // Write sine wave
      for (0..@intCast(waveLength * 2)) |i| {
        data_[i] =std.math.sin(((2.0 * std.math.pi * @as(f16, @floatFromInt(i))) / @as(f16, @floatFromInt(waveLength)))) * 32000.0;
      }

      // Make sure the rest of the line is flat
      for (@intCast(waveLength * 2)..MAX_SAMPLES) |j| {
        data_[j] = 0;
      }

      // Scale read cursor's position to minimize transition artifacts
      // readCursor = (int)(readCursor * ((float)waveLength / (float)oldWavelength));
      oldFrequency = frequency;
    }

    // Refill audio stream if required
    // if (rl.IsAudioStreamProcessed(stream)) {
    //   // Synthesize a buffer that is exactly the requested size
    //   var writeCursor: i32 = 0;
    //
    //   while (writeCursor < MAX_SAMPLES_PER_UPDATE) {
    //     // Start by trying to write the whole chunk at once
    //     var writeLength = MAX_SAMPLES_PER_UPDATE - writeCursor;
    //
    //     // Limit to the maximum readable size
    //     var readLength = waveLength - readCursor;
    //
    //     if (writeLength > readLength) writeLength = readLength;
    //
    //     // Write the slice
    //     std.mem.copy(u8, writeBuf + writeCursor, data + readCursor, writeLength * @sizeOf(i16));
    //
    //     // Update cursors and loop audio
    //     readCursor = (readCursor + writeLength) % waveLength;
    //
    //     writeCursor += writeLength;
    //   }
    //
    //   // Copy finished frame to audio stream
    //   rl.UpdateAudioStream(stream, writeBuf, MAX_SAMPLES_PER_UPDATE);
    // }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText(rl.TextFormat("sine frequency: %i", toInt(frequency)), rl.GetScreenWidth() - 220, 10, 20, rl.RED);
    rl.DrawText("click mouse button to change frequency or pan", 10, 10, 20, rl.DARKGRAY);

    // Draw the current buffer state proportionate to the screen
    const _data: [*]f16 = @as(?[*]f16, @ptrCast(@alignCast(data))) orelse return 3;
    for (0..screenWidth) |i| {
      position.x = @floatFromInt(i);
      position.y = 250.0 + 50.0 * (_data[i * MAX_SAMPLES / screenWidth]) / 32000.0;
      
      rl.DrawPixelV(position, rl.RED);
    }

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.RL_FREE(data);     // Unload sine wave data
  rl.RL_FREE(writeBuf); // Unload write buffer

  rl.UnloadAudioStream(stream); // Close raw audio stream and delete buffers from RAM
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
