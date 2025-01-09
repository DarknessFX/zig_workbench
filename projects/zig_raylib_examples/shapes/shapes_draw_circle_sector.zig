//!zig-autodoc-section: shapes_draw_circle_sector.Main
//! raylib_examples/shapes_draw_circle_sector.zig
//!   Example - draw circle sector.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - draw circle sector (with gui options)
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 2.5
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
  @cDefine("RAYGUI_IMPLEMENTATION","");
  @cInclude("raygui.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  var screenWidth: f32 = 800;
  var screenHeight: f32 = 450;

  ray.InitWindow(toInt(screenWidth), toInt(screenHeight), "raylib [shapes] example - draw circle sector");

  const center = ray.Vector2{ .x = (screenWidth - 300.0) / 2.0, .y = screenHeight / 2.0 };

  var outerRadius: f32 = 180.0;
  var startAngle: f32 = 0.0;
  var endAngle: f32 = 180.0;
  var segments: f32 = 10.0;
  var minSegments: f32 = 4.0;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    screenWidth = toFloat(ray.GetScreenHeight());
    screenHeight = toFloat(ray.GetScreenHeight());
    //----------------------------------------------------------------------------------
    // NOTE: All variables update happens inside GUI control functions
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawLine(500, 0, 500, toInt(screenWidth), ray.Fade(ray.LIGHTGRAY, 0.6));
      ray.DrawRectangle(500, 0, toInt(screenWidth - 500.0), toInt(screenHeight), ray.Fade(ray.LIGHTGRAY, 0.3));

      ray.DrawCircleSector(center, outerRadius, startAngle, endAngle, toInt(segments), ray.Fade(ray.MAROON, 0.3));
      ray.DrawCircleSectorLines(center, outerRadius, startAngle, endAngle, toInt(segments), ray.Fade(ray.MAROON, 0.6));

      // Draw GUI controls
      //------------------------------------------------------------------------------
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 600, .y = 40, .width = 120, .height = 20}, "StartAngle", ray.TextFormat("%.2f", startAngle), &startAngle, 0, 720);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 600, .y = 70, .width = 120, .height = 20}, "EndAngle", ray.TextFormat("%.2f", endAngle), &endAngle, 0, 720);

      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 600, .y = 140, .width = 120, .height = 20}, "Radius", ray.TextFormat("%.2f", outerRadius), &outerRadius, 0, 200);
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 600, .y = 170, .width = 120, .height = 20}, "Segments", ray.TextFormat("%.2f", segments), &segments, 0, 100);
      //------------------------------------------------------------------------------

      minSegments = @floor(@ceil((endAngle - startAngle) / 90.0));
      ray.DrawText(ray.TextFormat("MODE: %s", if (segments >= minSegments) "MANUAL".ptr else "AUTO".ptr), 600, 200, 10, if (segments >= minSegments) ray.MAROON else ray.DARKGRAY);

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