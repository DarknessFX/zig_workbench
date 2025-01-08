//!zig-autodoc-section: text_rectangle_bounds.Main
//! raylib_examples/text_rectangle_bounds.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Rectangle bounds
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 4.0
// *
// *   Example contributed by Vlad Adrian (@demizdor) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2018-2024 Vlad Adrian (@demizdor) and Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
});

// Draw text using font inside rectangle limits with support for text selection
fn DrawTextBoxed(font: ray.Font, text: [*:0]const u8, rec: ray.Rectangle, fontSize: f32, spacing: f32, wordWrap: bool, tint: ray.Color) void {
  DrawTextBoxedSelectable(font, text, rec, fontSize, spacing, wordWrap, tint, 0, 0, ray.WHITE, ray.WHITE);
}

// Draw text using font inside rectangle limits with support for text selection
fn DrawTextBoxedSelectable(font: ray.Font, text: [*:0]const u8, rec: ray.Rectangle, fontSize: f32, spacing: f32, wordWrap: bool, tint: ray.Color, selectStart: i32, selectLength: i32, selectTint: ray.Color, selectBackTint: ray.Color) void {
  _ = wordWrap; _ = tint;
  var selectX: f32 = 0;
  var selectY: f32 = 0;
  const lineHeight = fontSize + spacing;
  var line: i32 = 0;
  var start: usize = 0;
  var end: usize = 0;
  var i: usize = 0;
  const selectEnd = selectStart + selectLength;

  // Find start point for selection
  while (i < selectStart) : (i += 1) {
    if (text[i] == 0) break;
    if (text[i] == '\n') {
      line += 1;
      start = i + 1;
    }
  }

  // Find end point for selection
  i = @intCast(selectStart);
  while (i < selectEnd) : (i += 1) {
    if (text[i] == 0) break;
    if (text[i] == '\n') {
      end = i;
      selectX = ray.MeasureTextEx(font, text[start..end].ptr, fontSize, spacing).x;
      selectY = rec.y + toFloat(line) * lineHeight;
      ray.DrawRectangle(toInt(rec.x), toInt(selectY), toInt(selectX), toInt(lineHeight), selectBackTint);
      ray.DrawTextEx(font, text[start..end].ptr, ray.Vector2{ .x = rec.x, .y = selectY }, fontSize, spacing, selectTint);
      line += 1;
      start = i + 1;
    }
  }

  // Draw last line of text
  end = i;
  selectX = ray.MeasureTextEx(font, text[start..end].ptr, fontSize, spacing).x;
  selectY = rec.y + toFloat(line) * lineHeight;
  ray.DrawRectangle(toInt(rec.x), toInt(selectY), toInt(selectX), toInt(lineHeight), selectBackTint);
  ray.DrawTextEx(font, text[start..end].ptr, ray.Vector2{ .x = rec.x, .y = selectY }, fontSize, spacing, selectTint);
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - draw text inside a rectangle");

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)
  const font = ray.LoadFontEx(getPath("text", "resources/KAISG.ttf"), 64, 0, 250);

  // Sets the texture filter for font texture to GL_LINEAR (bilinear filtering)
  ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_BILINEAR);

  const msg = "Text cannot escape\tthis container\t...word wrap also works when active so here's a long text for testing.";

  const rec = ray.Rectangle{ .x = 200, .y = 100, .width = 300, .height = 200 };
  const fontSize = 20.0;
  const spacing = 2.0;
  const wordWrap = true;

  // Selection variables to be used in the future
  const selectStart: i32 = 0;
  const selectLength: i32 = 0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawRectangleLines(toInt(rec.x), toInt(rec.y), toInt(rec.width), toInt(rec.height), ray.RED);

      DrawTextBoxed(font, msg, rec, fontSize, spacing, wordWrap, ray.BLACK);

      // Draw text selection example
      DrawTextBoxedSelectable(font, msg, ray.Rectangle{ .x = 200, .y = 320, .width = 300, .height = 160 }, fontSize, spacing, wordWrap, ray.BLACK, selectStart, selectLength, ray.LIME, ray.DARKBLUE);

      ray.DrawText("Hold down LEFT mouse button to drag a text selection rectangle!", 340, 25, 20, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadFont(font);     // Unload TTF font

  ray.CloseWindow();        // Close window and OpenGL context
  //----------------------------------------------------------------------------------

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