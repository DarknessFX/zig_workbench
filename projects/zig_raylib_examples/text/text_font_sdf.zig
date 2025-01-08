//!zig-autodoc-section: text_font_sdf.Main
//! raylib_examples/text_font_sdf.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Font SDF loading
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
  @cInclude("stdlib.h");
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //
  const screenWidth = 800;
  const screenHeight = 450;
  const GLSL_VERSION: c_int = 330;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - SDF fonts");

  const msg = "Signed Distance Fields";

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)

  // Loading file to memory
  var fileSize: c_int = 0;
  const fileData = ray.LoadFileData(getPath("text", "resources/anonymous_pro_bold.ttf"), &fileSize);

  // Default font generation from TTF font
  var fontDefault = ray.Font{ .baseSize = 16, .glyphCount = 95 };

  // Loading font data from memory data
  // Parameters > font size: 16, no glyphs array provided (0), glyphs count: 95 (autogenerate chars array)
  fontDefault.glyphs = ray.LoadFontData(fileData, fileSize, 16, 0, 95, ray.FONT_DEFAULT);
  // Parameters > glyphs count: 95, font size: 16, glyphs padding in image: 4 px, pack method: 0 (default)
  var atlas = ray.GenImageFontAtlas(fontDefault.glyphs, &fontDefault.recs, 95, 16, 4, 0);
  fontDefault.texture = ray.LoadTextureFromImage(atlas);
  ray.UnloadImage(atlas);

  // SDF font generation from TTF font
  var fontSDF = ray.Font{ .baseSize = 16, .glyphCount = 95 };
  // Parameters > font size: 16, no glyphs array provided (0), glyphs count: 0 (defaults to 95)
  fontSDF.glyphs = ray.LoadFontData(fileData, fileSize, 16, 0, 0, ray.FONT_SDF);
  // Parameters > glyphs count: 95, font size: 16, glyphs padding in image: 0 px, pack method: 1 (Skyline algorythm)
  atlas = ray.GenImageFontAtlas(fontSDF.glyphs, &fontSDF.recs, 95, 16, 0, 1);
  fontSDF.texture = ray.LoadTextureFromImage(atlas);
  ray.UnloadImage(atlas);

  ray.UnloadFileData(fileData); // Free memory from loaded file

  // Load SDF required shader (we use default vertex shader)
  const shader = ray.LoadShader(0, ray.TextFormat(getPath("tet", "resources/shaders/glsl%d/sdf.fs"), GLSL_VERSION));
  ray.SetTextureFilter(fontSDF.texture, ray.TEXTURE_FILTER_BILINEAR); // Required for SDF font

  var fontPosition = ray.Vector2{ .x = 40.0, .y = toFloat(screenHeight) / 2.0 - 50.0 };
  var textSize = ray.Vector2{ .x = 0.0, .y = 0.0 };
  var fontSize: f32 = 16.0;
  var currentFont: c_int = 0; // 0 - fontDefault, 1 - fontSDF

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    fontSize += ray.GetMouseWheelMove() * 8.0;

    if (fontSize < 6.0) fontSize = 6.0;

    if (ray.IsKeyDown(ray.KEY_SPACE)) currentFont = 1
    else currentFont = 0;

    if (currentFont == 0) textSize = ray.MeasureTextEx(fontDefault, msg, fontSize, 0.0)
    else textSize = ray.MeasureTextEx(fontSDF, msg, fontSize, 0.0);

    fontPosition.x = toFloat(ray.GetScreenWidth()) / 2.0 - textSize.x / 2.0;
    fontPosition.y = toFloat(ray.GetScreenHeight()) / 2.0 - textSize.y / 2.0 + 80.0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      if (currentFont == 1) {
        // NOTE: SDF fonts require a custom SDf shader to compute fragment color
        ray.BeginShaderMode(shader);    // Activate SDF font shader
          ray.DrawTextEx(fontSDF, msg, fontPosition, fontSize, 0.0, ray.BLACK);
        ray.EndShaderMode();            // Activate our default shader for next drawings

        ray.DrawTexture(fontSDF.texture, 10, 10, ray.BLACK);
      } else {
        ray.DrawTextEx(fontDefault, msg, fontPosition, fontSize, 0.0, ray.BLACK);
        ray.DrawTexture(fontDefault.texture, 10, 10, ray.BLACK);
      }

      if (currentFont == 1) ray.DrawText("SDF!", 320, 20, 80, ray.RED)
      else ray.DrawText("default font", 315, 40, 30, ray.GRAY);

      ray.DrawText("FONT SIZE: 16.0", ray.GetScreenWidth() - 240, 20, 20, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("RENDER SIZE: %02.02f", fontSize), ray.GetScreenWidth() - 240, 50, 20, ray.DARKGRAY);
      ray.DrawText("Use MOUSE WHEEL to SCALE TEXT!", ray.GetScreenWidth() - 240, 90, 10, ray.DARKGRAY);

      ray.DrawText("HOLD SPACE to USE SDF FONT VERSION!", 340, ray.GetScreenHeight() - 30, 20, ray.MAROON);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

  ray.UnloadFont(fontDefault); // Default font unloading
  ray.UnloadFont(fontSDF);     // SDF font unloading

  ray.UnloadShader(shader);    // Unload SDF shader

  ray.CloseWindow();           // Close window and OpenGL context
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