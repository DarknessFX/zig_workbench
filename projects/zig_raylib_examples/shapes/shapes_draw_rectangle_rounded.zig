//!zig-autodoc-section: core_automation_events.Main
//! raylib_examples/core_automation_events.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX


const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h");
  @cDefine("RAYGUI_IMPLEMENTATION","");
  @cInclude("raygui.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  var screenWidth:f32 = 800;
  var screenHeight:f32 = 450;

  ray.InitWindow(toInt(screenWidth), toInt(screenHeight), "raylib [shapes] example - draw rectangle rounded");

  var roundness: f32 = 0.2;
  var width: f32 = 200.0;
  var height: f32 = 100.0;
  var segments: f32 = 0.0;
  var lineThick: f32 = 1.0;

  var drawRect: bool = false;
  var drawRoundedRect: bool = true;
  var drawRoundedLines: bool = false;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    screenWidth = toFloat(ray.GetScreenWidth());
    screenHeight = toFloat(ray.GetScreenHeight());
    const rec = ray.Rectangle{ 
      .x = (screenWidth - width - 250) / 2.0, 
      .y = (screenHeight - height) / 2.0, .width = width, .height = height };
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawLine(560, 0, 560, ray.GetScreenHeight(), ray.Fade(ray.LIGHTGRAY, 0.6));
      ray.DrawRectangle(560, 0, ray.GetScreenWidth() - 500, ray.GetScreenHeight(), ray.Fade(ray.LIGHTGRAY, 0.3));

      if (drawRect) ray.DrawRectangleRec(rec, ray.Fade(ray.GOLD, 0.6));
      if (drawRoundedRect) ray.DrawRectangleRounded(rec, roundness, toInt(segments), ray.Fade(ray.MAROON, 0.2));
      if (drawRoundedLines) ray.DrawRectangleRoundedLinesEx(rec, roundness, toInt(segments), lineThick, ray.Fade(ray.MAROON, 0.4));

      // Draw GUI controls
      //------------------------------------------------------------------------------
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 640, .y = 40, .width = 105, .height = 20 }, "Width", ray.TextFormat("%.2f", width), &width, 0, screenWidth - 300.0);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 640, .y = 70, .width = 105, .height = 20 }, "Height", ray.TextFormat("%.2f", height), &height, 0, screenHeight - 50.0);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 640, .y = 140, .width = 105, .height = 20 }, "Roundness", ray.TextFormat("%.2f", roundness), &roundness, 0.0, 1.0);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 640, .y = 170, .width = 105, .height = 20 }, "Thickness", ray.TextFormat("%.2f", lineThick), &lineThick, 0, 20);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 640, .y = 240, .width = 105, .height = 20}, "Segments", ray.TextFormat("%.2f", segments), &segments, 0, 60);

      _ = ray.GuiCheckBox(ray.Rectangle{ .x = 640, .y = 320, .width = 20, .height = 20 }, "DrawRoundedRect", &drawRoundedRect);
      _ = ray.GuiCheckBox(ray.Rectangle{ .x = 640, .y = 350, .width = 20, .height = 20 }, "DrawRoundedLines", &drawRoundedLines);
      _ = ray.GuiCheckBox(ray.Rectangle{ .x = 640, .y = 380, .width = 20, .height = 20}, "DrawRect", &drawRect);
      //------------------------------------------------------------------------------

      ray.DrawText(ray.TextFormat("MODE: %s", if (segments >= 4) "MANUAL".ptr else "AUTO".ptr), 640, 280, 10, if (segments >= 4) ray.MAROON else ray.DARKGRAY);

      ray.DrawFPS(10, 10);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
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