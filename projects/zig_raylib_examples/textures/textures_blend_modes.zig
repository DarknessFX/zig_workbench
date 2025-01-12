//!zig-autodoc-section: textures_blend_modes.Main
//! raylib_examples/textures_blend_modes.zig
//!   Example - blend modes.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - blend modes
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 3.5, last time updated with raylib 3.5
// *
// *   Example contributed by Karlo Licudine (@accidentalrebel) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2020-2024 Karlo Licudine (@accidentalrebel)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - blend modes");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  const bgImage = ray.LoadImage(getPath("textures", "resources/cyberpunk_street_background.png"));     // Loaded in CPU memory (RAM)
  const bgTexture = ray.LoadTextureFromImage(bgImage);          // Image converted to texture, GPU memory (VRAM)

  const fgImage = ray.LoadImage(getPath("textures", "resources/cyberpunk_street_foreground.png"));     // Loaded in CPU memory (RAM)
  const fgTexture = ray.LoadTextureFromImage(fgImage);          // Image converted to texture, GPU memory (VRAM)

  // Once image has been converted to texture and uploaded to VRAM, it can be unloaded from RAM
  ray.UnloadImage(bgImage);
  ray.UnloadImage(fgImage);

  const blendCountMax: c_int = 4;
  var blendMode: c_int = 0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsKeyPressed(ray.KEY_SPACE)) {
      if (blendMode >= (blendCountMax - 1)) blendMode = 0
      else blendMode += 1;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(bgTexture, toInt(toFloatC(screenWidth) / 2 - toFloatC(bgTexture.width) / 2), toInt(toFloatC(screenHeight) / 2 - toFloatC(bgTexture.height) / 2), ray.WHITE);

      // Apply the blend mode and then draw the foreground texture
      ray.BeginBlendMode(blendMode);
        ray.DrawTexture(fgTexture, toInt(toFloatC(screenWidth) / 2 - toFloatC(fgTexture.width) / 2), toInt(toFloatC(screenHeight) / 2 - toFloatC(fgTexture.height) / 2), ray.WHITE);
      ray.EndBlendMode();

      // Draw the texts
      ray.DrawText("Press SPACE to change blend modes.", 310, 350, 10, ray.GRAY);

      switch (blendMode) {
        ray.BLEND_ALPHA => ray.DrawText("Current: BLEND_ALPHA", (screenWidth / 2) - 60, 370, 10, ray.GRAY),
        ray.BLEND_ADDITIVE => ray.DrawText("Current: BLEND_ADDITIVE", (screenWidth / 2) - 60, 370, 10, ray.GRAY),
        ray.BLEND_MULTIPLIED => ray.DrawText("Current: BLEND_MULTIPLIED", (screenWidth / 2) - 60, 370, 10, ray.GRAY),
        ray.BLEND_ADD_COLORS =>  ray.DrawText("Current: BLEND_ADD_COLORS", (screenWidth / 2) - 60, 370, 10, ray.GRAY), 
        else => {}
      }

      ray.DrawText("(c) Cyberpunk Street Environment by Luis Zuno (@ansimuz)", screenWidth - 330, screenHeight - 20, 10, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(fgTexture); // Unload foreground texture
  ray.UnloadTexture(bgTexture); // Unload background texture

  ray.CloseWindow();            // Close window and OpenGL context
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