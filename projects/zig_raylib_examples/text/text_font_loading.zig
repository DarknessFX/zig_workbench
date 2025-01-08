//!zig-autodoc-section: text_font_loading.Main
//! raylib_examples/text_font_loading.zig
//!   Example - Font loading.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Font loading
// *
// *   NOTE: raylib can load fonts from multiple input file formats:
// *
// *     - TTF/OTF > Sprite font atlas is generated on loading, user can configure
// *                 some of the generation parameters (size, characters to include)
// *     - BMFonts > Angel code font fileformat, sprite font image must be provided
// *                 together with the .fnt file, font generation cna not be configured
// *     - XNA Spritefont > Sprite font image, following XNA Spritefont conventions,
// *                 Characters in image must follow some spacing and order rules
// *
// *   Example originally created with raylib 1.4, last time updated with raylib 3.0
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2016-2024 Ramon Santamaria (@raysan5)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - font loading");

  // Define characters to draw
  const msg = 
    "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI\n" ++
    "JKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmn\n" ++
    "opqrstuvwxyz{|}~¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓ\n" ++
    "ÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷\n" ++
    "øùúûüýþÿ";

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)

  // BMFont (AngelCode) : Font data and image atlas have been generated using external program
  const fontBm = ray.LoadFont(getPath("text", "resources/pixantiqua.fnt"));

  // TTF font : Font data and atlas are generated directly from TTF
  // NOTE: We define a font base size of 32 pixels tall and up-to 250 characters
  const fontTtf = ray.LoadFontEx(getPath("text", "resources/pixantiqua.ttf"), 32, 0, 250);

  ray.SetTextLineSpacing(16); // Set line spacing for multiline text (when line breaks are included '\n')

  var useTtf = false;

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    useTtf = ray.IsKeyDown(ray.KEY_SPACE);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("Hold SPACE to use TTF generated font", 20, 20, 20, ray.LIGHTGRAY);

      if (!useTtf) {
        ray.DrawTextEx(fontBm, msg, ray.Vector2{ .x = 20.0, .y = 100.0 }, toFloat(fontBm.baseSize), 2, ray.MAROON);
        ray.DrawText("Using BMFont (Angelcode) imported", 20, ray.GetScreenHeight() - 30, 20, ray.GRAY);
      } else {
        ray.DrawTextEx(fontTtf, msg, ray.Vector2{ .x = 20.0, .y = 100.0 }, toFloat(fontTtf.baseSize), 2, ray.LIME);
        ray.DrawText("Using TTF font generated", 20, ray.GetScreenHeight() - 30, 20, ray.GRAY);
      }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

  ray.UnloadFont(fontBm); // AngelCode Font unloading
  ray.UnloadFont(fontTtf); // TTF Font unloading

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
