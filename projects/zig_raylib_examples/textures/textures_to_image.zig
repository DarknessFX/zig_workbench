//!zig-autodoc-section: textures_to_image.Main
//! raylib_examples/textures_to_image.zig
//!   Example - Retrieve image data from texture.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Retrieve image data from texture: LoadImageFromTexture()
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 1.3, last time updated with raylib 4.0
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2015-2024 Ramon Santamaria (@raysan5)
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
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - texture to image");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)

  var image = ray.LoadImage(getPath("textures", "resources/raylib_logo.png"));  // Load image data into CPU memory (RAM)
  var texture = ray.LoadTextureFromImage(image);       // Image converted to texture, GPU memory (RAM -> VRAM)
  ray.UnloadImage(image);                                    // Unload image data from CPU memory (RAM)

  image = ray.LoadImageFromTexture(texture);                 // Load image from GPU texture (VRAM -> RAM)
  ray.UnloadTexture(texture);                                // Unload texture from GPU memory (VRAM)

  texture = ray.LoadTextureFromImage(image);                 // Recreate texture from retrieved image data (RAM -> VRAM)
  ray.UnloadImage(image);                                    // Unload retrieved image data from CPU memory (RAM)

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(texture, 
        @divTrunc(screenWidth, 2) - @divTrunc(texture.width, 2), 
        @divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2), ray.WHITE);

      ray.DrawText("this IS a texture loaded from an image!", 300, 370, 10, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture);       // Texture unloading

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