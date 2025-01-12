//!zig-autodoc-section: textures_sprite_anim.Main
//! raylib_examples/textures_sprite_anim.zig
//!   Example - Sprite animation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Sprite animation
// *
// *   Example originally created with raylib 1.3, last time updated with raylib 1.3
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2014-2024 Ramon Santamaria (@raysan5)
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
  const MAX_FRAME_SPEED: c_int = 15;
  const MIN_FRAME_SPEED: c_int = 1;

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [texture] example - sprite anim");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  const scarfy = ray.LoadTexture(getPath("textures", "resources/scarfy.png"));        // Texture loading

  const position = ray.Vector2{ .x = 350.0, .y = 280.0 };
  var frameRec = ray.Rectangle{ .x = 0.0, .y = 0.0, .width = toFloatC(scarfy.width) / 6.0, .height = toFloatC(scarfy.height) };
  var currentFrame: i32 = 0;

  var framesCounter: i32 = 0;
  var framesSpeed: i32 = 8;            // Number of spritesheet frames shown by second

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    framesCounter += 1;

    if (framesCounter >= @divTrunc(60, framesSpeed))
    {
      framesCounter = 0;
      currentFrame += 1;

      if (currentFrame > 5) currentFrame = 0;

      frameRec.x = toFloat(currentFrame) * toFloat(scarfy.width) / 6.0;
    }

    // Control frames speed
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) framesSpeed += 1
    else if (ray.IsKeyPressed(ray.KEY_LEFT)) framesSpeed -= 1;

    if (framesSpeed > MAX_FRAME_SPEED) framesSpeed = MAX_FRAME_SPEED
    else if (framesSpeed < MIN_FRAME_SPEED) framesSpeed = MIN_FRAME_SPEED;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(scarfy, 15, 40, ray.WHITE);
      ray.DrawRectangleLines(15, 40, scarfy.width, scarfy.height, ray.LIME);
      ray.DrawRectangleLines(15 + toInt(frameRec.x), 40 + toInt(frameRec.y), toInt(frameRec.width), toInt(frameRec.height), ray.RED);

      ray.DrawText("FRAME SPEED: ", 165, 210, 10, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("%02i FPS", framesSpeed), 575, 210, 10, ray.DARKGRAY);
      ray.DrawText("PRESS RIGHT/LEFT KEYS to CHANGE SPEED!", 290, 240, 10, ray.DARKGRAY);

      for (0..MAX_FRAME_SPEED) |i|
      {
        if (i < @as(usize, @intCast(framesSpeed))) 
          ray.DrawRectangle(250 + 21 * @as(i32, @intCast(i)), 205, 20, 20, ray.RED);
        ray.DrawRectangleLines(250 + 21 * @as(i32, @intCast(i)), 205, 20, 20, ray.MAROON);
      }

      ray.DrawTextureRec(scarfy, frameRec, position, ray.WHITE);  // Draw part of the texture

      ray.DrawText("(c) Scarfy sprite by Eiden Marsal", screenWidth - 200, screenHeight - 20, 10, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(scarfy);       // Texture unloading

  ray.CloseWindow();                // Close window and OpenGL context
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