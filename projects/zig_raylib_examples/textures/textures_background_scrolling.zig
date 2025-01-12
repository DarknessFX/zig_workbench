//!zig-autodoc-section: textures_background_scrolling.Main
//! raylib_examples/textures_background_scrolling.zig
//!   Example - background scrolling.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Background scrolling
// *
// *   Example originally created with raylib 2.0, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2019-2024 Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/ray.h"); 
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - background scrolling");

  // NOTE: Be careful, background width must be equal or bigger than screen width
  // if not, texture should be draw more than two times for scrolling effect
  const background = ray.LoadTexture(getPath("textures", "resources/cyberpunk_street_background.png"));
  const midground = ray.LoadTexture(getPath("textures", "resources/cyberpunk_street_midground.png"));
  const foreground = ray.LoadTexture(getPath("textures", "resources/cyberpunk_street_foreground.png"));

  var scrollingBack: f32 = 0.0;
  var scrollingMid: f32 = 0.0;
  var scrollingFore: f32 = 0.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    scrollingBack -= 0.1;
    scrollingMid -= 0.5;
    scrollingFore -= 1.0;

    // NOTE: Texture is scaled twice its size, so it sould be considered on scrolling
    if (scrollingBack <= -toFloatC(background.width) * 2) scrollingBack = 0;
    if (scrollingMid <= -toFloatC(midground.width) * 2) scrollingMid = 0;
    if (scrollingFore <= -toFloatC(foreground.width) * 2) scrollingFore = 0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.GetColor(0x052c46ff));

      // Draw background image twice
      // NOTE: Texture is scaled twice its size
      ray.DrawTextureEx(background, ray.Vector2{ .x = scrollingBack, .y = 20 }, 0.0, 2.0, ray.WHITE);
      ray.DrawTextureEx(background, ray.Vector2{ .x = toFloatC(background.width) * 2 + scrollingBack, .y = 20 }, 0.0, 2.0, ray.WHITE);

      // Draw midground image twice
      ray.DrawTextureEx(midground, ray.Vector2{ .x = scrollingMid, .y = 20 }, 0.0, 2.0, ray.WHITE);
      ray.DrawTextureEx(midground, ray.Vector2{ .x = toFloatC(midground.width) * 2 + scrollingMid, .y = 20 }, 0.0, 2.0, ray.WHITE);

      // Draw foreground image twice
      ray.DrawTextureEx(foreground, ray.Vector2{ .x = scrollingFore, .y = 70 }, 0.0, 2.0, ray.WHITE);
      ray.DrawTextureEx(foreground, ray.Vector2{ .x = toFloatC(foreground.width) * 2 + scrollingFore, .y = 70 }, 0.0, 2.0, ray.WHITE);

      ray.DrawText("BACKGROUND SCROLLING & PARALLAX", 10, 10, 20, ray.RED);
      ray.DrawText("(c) Cyberpunk Street Environment by Luis Zuno (@ansimuz)", screenWidth - 330, screenHeight - 20, 10, ray.RAYWHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(background);  // Unload background texture
  ray.UnloadTexture(midground);   // Unload midground texture
  ray.UnloadTexture(foreground);  // Unload foreground texture

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