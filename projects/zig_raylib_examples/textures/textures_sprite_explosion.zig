//!zig-autodoc-section: textures_sprite_explosion.Main
//! raylib_examples/textures_sprite_explosion.zig
//!   Example - sprite explosion.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - sprite explosion
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 3.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2019-2024 Anata and Ramon Santamaria (@raysan5)
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
  const NUM_FRAMES_PER_LINE: c_int = 5;
  const NUM_LINES: c_int = 5;

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - sprite explosion");

  ray.InitAudioDevice();

  // Load explosion sound
  const fxBoom = ray.LoadSound(getPath("textures", "resources/boom.wav"));

  // Load explosion texture
  const explosion = ray.LoadTexture(getPath("textures", "resources/explosion.png"));

  // Init variables for animation
  const frameWidth: f32 = toFloat(explosion.width) / toFloat(NUM_FRAMES_PER_LINE);   // Sprite one frame rectangle width
  const frameHeight: f32 = toFloat(explosion.height) / toFloat(NUM_LINES);           // Sprite one frame rectangle height
  var currentFrame: i32 = 0;
  var currentLine: i32 = 0;

  var frameRec = ray.Rectangle{ .x = 0, .y = 0, .width = frameWidth, .height = frameHeight };
  var position = ray.Vector2{ .x = 0.0, .y = 0.0 };

  var active: bool = false;
  var framesCounter: i32 = 0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------

    // Check for mouse button pressed and activate explosion (if not active)
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT) and !active)
    {
      position = ray.GetMousePosition();
      active = true;

      position.x -= frameWidth / 2.0;
      position.y -= frameHeight / 2.0;

      ray.PlaySound(fxBoom);
    }

    // Compute explosion animation frames
    if (active)
    {
      framesCounter += 1;

      if (framesCounter > 2)
      {
        currentFrame += 1;

        if (currentFrame >= NUM_FRAMES_PER_LINE)
        {
          currentFrame = 0;
          currentLine += 1;

          if (currentLine >= NUM_LINES)
          {
            currentLine = 0;
            active = false;
          }
        }

        framesCounter = 0;
      }
    }

    frameRec.x = frameWidth * toFloat(currentFrame);
    frameRec.y = frameHeight * toFloat(currentLine);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      // Draw explosion required frame rectangle
      if (active) ray.DrawTextureRec(explosion, frameRec, position, ray.WHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(explosion);   // Unload texture
  ray.UnloadSound(fxBoom);        // Unload sound

  ray.CloseAudioDevice();

  ray.CloseWindow();              // Close window and OpenGL context
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