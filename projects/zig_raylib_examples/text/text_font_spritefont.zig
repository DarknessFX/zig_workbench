//!zig-autodoc-section: text_font_spritefont.Main
//! raylib_examples/text_font_spritefont.zig
//!   Example - Sprite font loading.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Sprite font loading
// *
// *   NOTE: Sprite fonts should be generated following this conventions:
// *
// *     - Characters must be ordered starting with character 32 (Space)
// *     - Every character must be contained within the same Rectangle height
// *     - Every character and every line must be separated by the same distance (margin/padding)
// *     - Rectangles must be defined by a MAGENTA color background
// *
// *   Following those constraints, a font can be provided just by an image,
// *   this is quite handy to avoid additional font descriptor files (like BMFonts use).
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
pub fn main() u8 {
// Initialization
  //
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - sprite font loading");

  const msg1 = "THIS IS A custom SPRITE FONT...";
  const msg2 = "...and this is ANOTHER CUSTOM font...";
  const msg3 = "...and a THIRD one! GREAT! :D";

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)
  const font1 = ray.LoadFont(getPath("text", "resources/custom_mecha.png"));          // Font loading
  const font2 = ray.LoadFont(getPath("text", "resources/custom_alagard.png"));        // Font loading
  const font3 = ray.LoadFont(getPath("text", "resources/custom_jupiter_crash.png"));  // Font loading

  const fontPosition1 = ray.Vector2{
    .x = toFloat(screenWidth) / 2.0 - ray.MeasureTextEx(font1, msg1, toFloat(font1.baseSize), -3).x / 2.0,
    .y = toFloat(screenHeight) / 2.0 - toFloat(font1.baseSize) / 2.0 - 80.0,
  };

  const fontPosition2 = ray.Vector2{
    .x = toFloat(screenWidth) / 2.0 - ray.MeasureTextEx(font2, msg2, toFloat(font2.baseSize), -2.0).x / 2.0,
    .y = toFloat(screenHeight) / 2.0 - toFloat(font2.baseSize) / 2.0 - 10.0,
  };

  const fontPosition3 = ray.Vector2{
    .x = toFloat(screenWidth) / 2.0 - ray.MeasureTextEx(font3, msg3, toFloat(font3.baseSize), 2.0).x / 2.0,
    .y = toFloat(screenHeight) / 2.0 - toFloat(font3.baseSize) / 2.0 + 50.0,
  };

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update variables here...
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTextEx(font1, msg1, fontPosition1, toFloat(font1.baseSize), -3, ray.WHITE);
      ray.DrawTextEx(font2, msg2, fontPosition2, toFloat(font2.baseSize), -2, ray.WHITE);
      ray.DrawTextEx(font3, msg3, fontPosition3, toFloat(font3.baseSize), 2, ray.WHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

  ray.UnloadFont(font1); // Font unloading
  ray.UnloadFont(font2); // Font unloading
  ray.UnloadFont(font3); // Font unloading

  ray.CloseWindow();     // Close window and OpenGL context
  //
  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}

inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
var cwd: []u8 = undefined;
inline fn getCwd() []u8 { return std.process.getCwdAlloc(std.heap.page_allocator) catch unreachable; }
inline fn getPath(folder: []const u8, file: []const u8) [*]const u8 { 
  if (cwd.len == 0) cwd = getCwd();
  std.fs.cwd().access(folder, .{ .mode = std.fs.File.OpenMode.read_only }) catch {
    return fmt("{s}/{s}", .{ cwd, file} ).ptr; 
  };
  return fmt("{s}/{s}/{s}", .{ cwd, folder, file} ).ptr; 
}
