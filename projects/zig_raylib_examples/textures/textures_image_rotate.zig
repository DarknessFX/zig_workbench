//!zig-autodoc-section: textures_image_rotate.Main
//! raylib_examples/textures_image_rotate.zig
//!   Example - Image Rotation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Image Rotation
// *
// *   Example originally created with raylib 1.0, last time updated with raylib 1.0
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
  const NUM_TEXTURES: c_int = 3;

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - texture rotation");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  var image45 = ray.LoadImage(getPath("textures", "resources/raylib_logo.png"));
  var image90 = ray.LoadImage(getPath("textures", "resources/raylib_logo.png"));
  var imageNeg90 = ray.LoadImage(getPath("textures", "resources/raylib_logo.png"));

  ray.ImageRotate(&image45, 45);
  ray.ImageRotate(&image90, 90);
  ray.ImageRotate(&imageNeg90, -90);

  var textures: [NUM_TEXTURES]ray.Texture2D = undefined;

  textures[0] = ray.LoadTextureFromImage(image45);
  textures[1] = ray.LoadTextureFromImage(image90);
  textures[2] = ray.LoadTextureFromImage(imageNeg90);

  var currentTexture: i32 = 0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT) or ray.IsKeyPressed(ray.KEY_RIGHT))
    {
      currentTexture = @mod(currentTexture + 1, NUM_TEXTURES); // Cycle between the textures
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(textures[@intCast(currentTexture)], 
        @divTrunc(screenWidth, 2) - @divTrunc(textures[@intCast(currentTexture)].width, 2), 
        @divTrunc(screenHeight, 2) - @divTrunc(textures[@intCast(currentTexture)].height, 2), ray.WHITE);

      ray.DrawText("Press LEFT MOUSE BUTTON to rotate the image clockwise", 250, 420, 10, ray.DARKGRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  for (0..textures.len) |i| {
    ray.UnloadTexture(textures[i]);
  }

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