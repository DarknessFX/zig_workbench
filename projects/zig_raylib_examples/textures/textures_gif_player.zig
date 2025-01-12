//!zig-autodoc-section: textures_gif_player.Main
//! raylib_examples/textures_gif_player.zig
//!   Example - gif playing.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - gif playing
// *
// *   Example originally created with raylib 4.2, last time updated with raylib 4.2
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2021-2024 Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  const MAX_FRAME_DELAY = 20;
  const MIN_FRAME_DELAY = 1;

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - gif playing");

  var animFrames: i32 = 0;

  // Load all GIF animation frames into a single Image
  // NOTE: GIF data is always loaded as RGBA (32bit) by default
  // NOTE: Frames are just appended one after another in image.data memory
  const imScarfyAnim = ray.LoadImageAnim(getPath("textures", "resources/scarfy_run.gif"), &animFrames);

  // Load texture from image
  // NOTE: We will update this texture when required with next frame data
  // WARNING: It's not recommended to use this technique for sprites animation,
  // use spritesheets instead, like illustrated in textures_sprite_anim example
  const texScarfyAnim = ray.LoadTextureFromImage(imScarfyAnim);

  var nextFrameDataOffset: u32 = 0;  // Current byte offset to next frame in image.data

  var currentAnimFrame: i32 = 0;       // Current animation frame to load and draw
  var frameDelay: i32 = 8;             // Frame delay to switch between animation frames
  var frameCounter: i32 = 0;           // General frames counter

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    frameCounter += 1;
    if (frameCounter >= frameDelay)
    {
      // Move to next frame
      // NOTE: If final frame is reached we return to first frame
      currentAnimFrame += 1;
      if (currentAnimFrame >= animFrames) currentAnimFrame = 0;

      // Get memory offset position for next frame data in image.data
      nextFrameDataOffset = @intCast(imScarfyAnim.width * imScarfyAnim.height * 4 * currentAnimFrame);

      // Update GPU texture data with next frame image data
      // WARNING: Data size (frame size) and pixel format must match already created texture
      ray.UpdateTexture(texScarfyAnim, @as([*]u8, @ptrCast(imScarfyAnim.data)) + nextFrameDataOffset);

      frameCounter = 0;
    }

    // Control frames delay
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) frameDelay += 1
    else if (ray.IsKeyPressed(ray.KEY_LEFT)) frameDelay -= 1;

    if (frameDelay > MAX_FRAME_DELAY) frameDelay = MAX_FRAME_DELAY
    else if (frameDelay < MIN_FRAME_DELAY) frameDelay = MIN_FRAME_DELAY;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText(ray.TextFormat("TOTAL GIF FRAMES:  %02i", animFrames), 50, 30, 20, ray.LIGHTGRAY);
      ray.DrawText(ray.TextFormat("CURRENT FRAME: %02i", currentAnimFrame), 50, 60, 20, ray.GRAY);
      ray.DrawText(ray.TextFormat("CURRENT FRAME IMAGE.DATA OFFSET: %02i", nextFrameDataOffset), 50, 90, 20, ray.GRAY);

      ray.DrawText("FRAMES DELAY: ", 100, 305, 10, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("%02i frames", frameDelay), 620, 305, 10, ray.DARKGRAY);
      ray.DrawText("PRESS RIGHT/LEFT KEYS to CHANGE SPEED!", 290, 350, 10, ray.DARKGRAY);

      var i: i32 = 0;
      while (i < MAX_FRAME_DELAY) : (i += 1)
      {
        if (i < frameDelay) ray.DrawRectangle(190 + 21*i, 300, 20, 20, ray.RED);
        ray.DrawRectangleLines(190 + 21*i, 300, 20, 20, ray.MAROON);
      }

      ray.DrawTexture(texScarfyAnim, @divTrunc(ray.GetScreenWidth(), 2) - @divTrunc(texScarfyAnim.width, 2), 140, ray.WHITE);

      ray.DrawText("(c) Scarfy sprite by Eiden Marsal", screenWidth - 200, screenHeight - 20, 10, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texScarfyAnim);   // Unload texture
  ray.UnloadImage(imScarfyAnim);      // Unload image (contains all frames)

  ray.CloseWindow();                  // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toFloatC(value: c_int) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}
inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
inline fn fmtC(comptime format: []const u8, args: anytype) [:0]u8 {  return std.fmt.allocPrintZ(std.heap.page_allocator, format, args) catch unreachable; }

var cwd: []u8 = undefined;
inline fn getCwd() []u8 { return std.process.getCwdAlloc(std.heap.page_allocator) catch unreachable; }
inline fn getPath(folder: []const u8, file: []const u8) [*]const u8 { 
  if (cwd.len == 0) cwd = getCwd();
  std.fs.cwd().access(folder, .{ .mode = std.fs.File.OpenMode.read_only }) catch {
    return fmt("{s}/{s}", .{ cwd, file} ).ptr; 
  };
  return fmt("{s}/{s}/{s}", .{ cwd, folder, file} ).ptr; 
}