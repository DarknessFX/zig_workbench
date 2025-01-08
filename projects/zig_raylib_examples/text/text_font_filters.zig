//!zig-autodoc-section: text_font_filters.Main
//! raylib_examples/text_font_filters.zig
//!   Example - Font filters.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Font filters
// *
// *   NOTE: After font loading, font texture atlas filter could be configured for a softer
// *   display of the font when scaling it to different sizes, that way, it's not required
// *   to generate multiple fonts at multiple sizes (as long as the scaling is not very different)
// *
// *   Example originally created with raylib 1.3, last time updated with raylib 4.2
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
pub fn main() u8 {
// Initialization
  //
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - font filters");

  const msg = "Loaded Font";

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)

  // TTF Font loading with custom generation parameters
  var font = ray.LoadFontEx(getPath("text", "resources/KAISG.ttf"), 96, 0, 0);

  // Generate mipmap levels to use trilinear filtering
  // NOTE: On 2D drawing it won't be noticeable, it looks like FILTER_BILINEAR
  ray.GenTextureMipmaps(&font.texture);

  var fontSize = toFloat(font.baseSize);
  var fontPosition = ray.Vector2{ .x = 40.0, .y = toFloat(screenHeight) / 2.0 - 80.0 };
  var textSize = ray.Vector2{ .x = 0.0, .y = 0.0 };

  // Setup texture scaling filter
  ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_POINT);
  var currentFontFilter: i32 = 0; // TEXTURE_FILTER_POINT

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    fontSize += ray.GetMouseWheelMove() * 4.0;

    // Choose font texture filter method
    if (ray.IsKeyPressed(ray.KEY_ONE)) {
      ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_POINT);
      currentFontFilter = 0;
    } else if (ray.IsKeyPressed(ray.KEY_TWO)) {
      ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_BILINEAR);
      currentFontFilter = 1;
    } else if (ray.IsKeyPressed(ray.KEY_THREE)) {
      // NOTE: Trilinear filter won't be noticed on 2D drawing
      ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_TRILINEAR);
      currentFontFilter = 2;
    }

    textSize = ray.MeasureTextEx(font, msg, fontSize, 0.0);

    if (ray.IsKeyDown(ray.KEY_LEFT)) fontPosition.x -= 10.0
    else if (ray.IsKeyDown(ray.KEY_RIGHT)) fontPosition.x += 10.0;

    // Load a dropped TTF file dynamically (at current fontSize)
    if (ray.IsFileDropped()) {
      const droppedFiles = ray.LoadDroppedFiles();

      // NOTE: We only support first ttf file dropped
      if (ray.IsFileExtension(droppedFiles.paths[0], ".ttf")) {
        ray.UnloadFont(font);
        font = ray.LoadFontEx(droppedFiles.paths[0], toInt(fontSize), 0, 0);
      }
      
      ray.UnloadDroppedFiles(droppedFiles); // Unload filepaths from memory
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("Use mouse wheel to change font size", 20, 20, 10, ray.GRAY);
      ray.DrawText("Use KEY_RIGHT and KEY_LEFT to move text", 20, 40, 10, ray.GRAY);
      ray.DrawText("Use 1, 2, 3 to change texture filter", 20, 60, 10, ray.GRAY);
      ray.DrawText("Drop a new TTF font for dynamic loading", 20, 80, 10, ray.DARKGRAY);

      ray.DrawTextEx(font, msg, fontPosition, fontSize, 0.0, ray.BLACK);

      // TODO: It seems texSize measurement is not accurate due to chars offsets...
      //ray.DrawRectangleLines(toInt(fontPosition.x), toInt(fontPosition.y), toInt(textSize.x), toInt(textSize.y), ray.RED);

      ray.DrawRectangle(0, screenHeight - 80, screenWidth, 80, ray.LIGHTGRAY);
      ray.DrawText(ray.TextFormat("Font size: %02.02f", fontSize), 20, screenHeight - 50, 10, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("Text size: [%02.02f, %02.02f]", textSize.x, textSize.y), 20, screenHeight - 30, 10, ray.DARKGRAY);
      ray.DrawText("CURRENT TEXTURE FILTER:", 250, 400, 20, ray.GRAY);

      if (currentFontFilter == 0) ray.DrawText("POINT", 570, 400, 20, ray.BLACK)
      else if (currentFontFilter == 1) ray.DrawText("BILINEAR", 570, 400, 20, ray.BLACK)
      else if (currentFontFilter == 2) ray.DrawText("TRILINEAR", 570, 400, 20, ray.BLACK);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

  ray.UnloadFont(font); // Font unloading

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