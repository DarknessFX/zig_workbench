//!zig-autodoc-section: shapes_colors_palette.Main
//! raylib_examples/shapes_colors_palette.zig
//!   Example - colors palette.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - Colors palette
// *
// *   Example originally created with raylib 1.0, last time updated with raylib 2.5
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
pub fn main() !u8 {
  const MAX_COLORS_COUNT: c_int = 21;          // Number of colors available

  // Initialization
  //--------------------------------------------------------------------------------------
  var screenWidth: f32 = 800.0;
  var screenHeight: f32 = 450.0;

  ray.InitWindow(@intFromFloat(screenWidth), @intFromFloat(screenHeight), "raylib [shapes] example - colors palette");

  const colors = [_]ray.Color{
    ray.DARKGRAY, ray.MAROON, ray.ORANGE, ray.DARKGREEN, ray.DARKBLUE, ray.DARKPURPLE, ray.DARKBROWN,
    ray.GRAY, ray.RED, ray.GOLD, ray.LIME, ray.BLUE, ray.VIOLET, ray.BROWN, ray.LIGHTGRAY, ray.PINK, ray.YELLOW,
    ray.GREEN, ray.SKYBLUE, ray.PURPLE, ray.BEIGE
  };

  const colorNames = [_][]const u8{
    "DARKGRAY", "MAROON", "ORANGE", "DARKGREEN", "DARKBLUE", "DARKPURPLE",
    "DARKBROWN", "GRAY", "RED", "GOLD", "LIME", "BLUE", "VIOLET", "BROWN",
    "LIGHTGRAY", "PINK", "YELLOW", "GREEN", "SKYBLUE", "PURPLE", "BEIGE"
  };

  var colorsRecs = [_]ray.Rectangle{ray.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 }} ** MAX_COLORS_COUNT;     // Rectangles array

  // Fills colorsRecs data (for every rectangle)
  for (0..MAX_COLORS_COUNT) |i| {
    colorsRecs[i].x = 20.0 + 100.0 * @mod(@as(f32, @floatFromInt(i)) , 7) + 10.0 * @as(f32, @floatFromInt(i % 7));
    colorsRecs[i].y = 80.0 + 100.0 * @divExact(@as(f32, @floatFromInt(i)), 7) + 10.0 * @as(f32, @floatFromInt(i / 7));
    colorsRecs[i].width = 100.0;
    colorsRecs[i].height = 100.0;
  }

  var colorState = [_]i32{0} ** MAX_COLORS_COUNT;           // Color state: 0-DEFAULT, 1-MOUSE_HOVER

  var mousePoint = ray.Vector2{ .x = 0.0, .y = 0.0 };

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    screenWidth = @floatFromInt(ray.GetScreenWidth());
    screenHeight = @floatFromInt(ray.GetScreenHeight());
    // Update
    //----------------------------------------------------------------------------------
    mousePoint = ray.GetMousePosition();

    for (0..MAX_COLORS_COUNT) |i| {
      if (ray.CheckCollisionPointRec(mousePoint, colorsRecs[i])) colorState[i] = 1
      else colorState[i] = 0;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("raylib colors palette", 28, 42, 20, ray.BLACK);
      ray.DrawText("press SPACE to see all colors", @intFromFloat(screenWidth - 180.0), @intFromFloat(screenHeight - 40.0), 10, ray.GRAY);

      for (0..MAX_COLORS_COUNT) |i| {    // Draw all rectangles
        ray.DrawRectangleRec(colorsRecs[i], ray.Fade(colors[i], if (colorState[i] != 0) 0.6 else 1.0));

        if (ray.IsKeyDown(ray.KEY_SPACE) or colorState[i] != 0) {
          ray.DrawRectangle(toInt(colorsRecs[i].x), toInt(colorsRecs[i].y + colorsRecs[i].height - 26.0), toInt(colorsRecs[i].width), 20, ray.BLACK);
          ray.DrawRectangleLinesEx(colorsRecs[i], 6, ray.Fade(ray.BLACK, 0.3));
          ray.DrawText(fmtC("{s}", .{colorNames[i]}),
            toInt(colorsRecs[i].x + colorsRecs[i].width - toFloatC(ray.MeasureText(fmtC("{s}", .{colorNames[i]}), 10)) - 12.0),
            toInt(colorsRecs[i].y + colorsRecs[i].height - 20.0), 10, colors[i]);
        }
      }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
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