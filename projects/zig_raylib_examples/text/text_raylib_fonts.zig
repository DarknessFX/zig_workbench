//!zig-autodoc-section: text_raylib_fonts.Main
//! raylib_examples/text_raylib_fonts.zig
//!   Example - raylib fonts loading.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - raylib fonts loading
// *
// *   NOTE: raylib is distributed with some free to use fonts (even for commercial pourposes!)
// *         To view details and credits for those fonts, check raylib license file
// *
// *   Example originally created with raylib 1.7, last time updated with raylib 3.7
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
pub fn main() u8 {
// Initialization
  //
  const screenWidth = 800;
  const screenHeight = 450;
  const MAX_FONTS = 8;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - raylib fonts");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  var fonts: [MAX_FONTS]ray.Font = undefined;

  fonts[0] = ray.LoadFont(getPath("text", "resources/fonts/alagard.png"));
  fonts[1] = ray.LoadFont(getPath("text", "resources/fonts/pixelplay.png"));
  fonts[2] = ray.LoadFont(getPath("text", "resources/fonts/mecha.png"));
  fonts[3] = ray.LoadFont(getPath("text", "resources/fonts/setback.png"));
  fonts[4] = ray.LoadFont(getPath("text", "resources/fonts/romulus.png"));
  fonts[5] = ray.LoadFont(getPath("text", "resources/fonts/pixantiqua.png"));
  fonts[6] = ray.LoadFont(getPath("text", "resources/fonts/alpha_beta.png"));
  fonts[7] = ray.LoadFont(getPath("text", "resources/fonts/jupiter_crash.png"));

  const messages = [_][*c]const u8{
    "ALAGARD FONT designed by Hewett Tsoi",
    "PIXELPLAY FONT designed by Aleksander Shevchuk",
    "MECHA FONT designed by Captain Falcon",
    "SETBACK FONT designed by Brian Kent (AEnigma)",
    "ROMULUS FONT designed by Hewett Tsoi",
    "PIXANTIQUA FONT designed by Gerhard Grossmann",
    "ALPHA_BETA FONT designed by Brian Kent (AEnigma)",
    "JUPITER_CRASH FONT designed by Brian Kent (AEnigma)",
  };

  const spacings = [_]i32{ 2, 4, 8, 4, 3, 4, 4, 1 };

  var positions: [MAX_FONTS]ray.Vector2 = undefined;

  for (0..MAX_FONTS) |i| {
    positions[i] = ray.Vector2{
      .x = toFloat(screenWidth) / 2.0 - ray.MeasureTextEx(fonts[i], messages[i], toFloat(fonts[i].baseSize) * 2.0, toFloat(spacings[i])).x / 2.0,
      .y = 60.0 + toFloat(fonts[i].baseSize) + toFloat(45) * @as(f32, @floatFromInt(i)),
    };
  }

  // Small Y position corrections
  positions[3].y += 8.0;
  positions[4].y += 2.0;
  positions[7].y -= 8.0;

  const colors = [_]ray.Color{
    ray.MAROON, ray.ORANGE, ray.DARKGREEN, ray.DARKBLUE, ray.DARKPURPLE, ray.LIME, ray.GOLD, ray.RED,
  };

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("free fonts included with raylib", 250, 20, 20, ray.DARKGRAY);
      ray.DrawLine(220, 50, 590, 50, ray.DARKGRAY);

      for (0..MAX_FONTS) |i| {
        ray.DrawTextEx(fonts[i], messages[i], positions[i], toFloat(fonts[i].baseSize) * 2.0, toFloat(spacings[i]), colors[i]);
      }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

  // Fonts unloading
  for (0..MAX_FONTS) |i| ray.UnloadFont(fonts[i]);

  ray.CloseWindow(); // Close window and OpenGL context
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