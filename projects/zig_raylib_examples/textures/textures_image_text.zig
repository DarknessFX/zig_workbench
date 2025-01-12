//!zig-autodoc-section: textures_image_text.Main
//! raylib_examples/textures_image_text.zig
//!   Example - Image text drawing using TTF generated font.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [texture] example - Image text drawing using TTF generated font
// *
// *   Example originally created with raylib 1.8, last time updated with raylib 4.0
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2017-2024 Ramon Santamaria (@raysan5)
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
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [texture] example - image text drawing");

  var parrots = ray.LoadImage(getPath("textures", "resources/parrots.png")); // Load image in CPU memory (RAM)

  // TTF Font loading with custom generation parameters
  const font = ray.LoadFontEx(getPath("textures", "resources/KAISG.ttf"), 64, 0, 0);

  // Draw over image using custom font
  ray.ImageDrawTextEx(&parrots, font, "[Parrots font drawing]", 
    ray.Vector2{ .x = 20.0, .y = 20.0 }, 
    toFloat(font.baseSize), 0.0, ray.RED);

  const texture = ray.LoadTextureFromImage(parrots);  // Image converted to texture, uploaded to GPU memory (VRAM)
  ray.UnloadImage(parrots);   // Once image has been converted to texture and uploaded to VRAM, it can be unloaded from RAM

  const position = ray.Vector2{
    .x = toFloat(@divTrunc(screenWidth, 2) - @divTrunc(texture.width, 2)), 
    .y = toFloat(@divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2) - 20) };

  var showFont = false;

  ray.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsKeyDown(ray.KEY_SPACE)) showFont = true
    else showFont = false;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      if (!showFont)
      {
        // Draw texture with text already drawn inside
        ray.DrawTextureV(texture, position, ray.WHITE);

        // Draw text directly using sprite font
        ray.DrawTextEx(font, "[Parrots font drawing]", ray.Vector2{ 
          .x = position.x + 20,
          .y = position.y + 20 + 280 
        }, toFloat(font.baseSize), 0.0, ray.WHITE);
      }
      else ray.DrawTexture(font.texture, @divTrunc(screenWidth, 2) - @divTrunc(font.texture.width, 2), 50, ray.BLACK);

      ray.DrawText("PRESS SPACE to SHOW FONT ATLAS USED", 290, 420, 10, ray.DARKGRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture);     // Texture unloading

  ray.UnloadFont(font);           // Unload custom font

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