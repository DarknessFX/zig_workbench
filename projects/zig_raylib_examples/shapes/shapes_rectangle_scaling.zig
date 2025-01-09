//!zig-autodoc-section: shapes_rectangle_scaling.Main
//! raylib_examples/shapes_rectangle_scaling.zig
//!   Example - rectangle scaling by mouse.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - rectangle scaling by mouse
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
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const MOUSE_SCALE_MARK_SIZE = 12;
  var screenWidth: f32 = 800;
  var screenHeight: f32 = 450;

  ray.InitWindow(toInt(screenWidth), toInt(screenHeight), "raylib [shapes] example - rectangle scaling mouse");

  var rec = ray.Rectangle{ .x = 100, .y = 100, .width = 200, .height = 80 };

  var mousePosition = ray.Vector2{ .x = 0, .y = 0 };

  var mouseScaleReady = false;
  var mouseScaleMode = false;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    screenWidth = toFloat(ray.GetScreenWidth());
    screenHeight = toFloat(ray.GetScreenHeight());
    mousePosition = ray.GetMousePosition();

    if (ray.CheckCollisionPointRec(mousePosition, ray.Rectangle{ .x = rec.x + rec.width - MOUSE_SCALE_MARK_SIZE, .y = rec.y + rec.height - MOUSE_SCALE_MARK_SIZE, .width = toInt(MOUSE_SCALE_MARK_SIZE), .height = toInt(MOUSE_SCALE_MARK_SIZE) })) {
      mouseScaleReady = true;
      if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT)) mouseScaleMode = true;
    } else {
      mouseScaleReady = false;
    }

    if (mouseScaleMode) {
      mouseScaleReady = true;

      rec.width = mousePosition.x - rec.x;
      rec.height = mousePosition.y - rec.y;

      // Check minimum rec size
      if (rec.width < toInt(MOUSE_SCALE_MARK_SIZE)) rec.width = toInt(MOUSE_SCALE_MARK_SIZE);
      if (rec.height < toInt(MOUSE_SCALE_MARK_SIZE)) rec.height = toInt(MOUSE_SCALE_MARK_SIZE);
      
      // Check maximum rec size
      if (rec.width > screenWidth - rec.x) rec.width = screenWidth - rec.x;
      if (rec.height > screenHeight - rec.y) rec.height = screenHeight - rec.y;

      if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) mouseScaleMode = false;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("Scale rectangle dragging from bottom-right corner!", 10, 10, 20, ray.GRAY);

      ray.DrawRectangleRec(rec, ray.Fade(ray.GREEN, 0.5));

      if (mouseScaleReady) {
        ray.DrawRectangleLinesEx(rec, 1, ray.RED);
        ray.DrawTriangle(ray.Vector2{ .x = rec.x + rec.width - toInt(MOUSE_SCALE_MARK_SIZE), .y = rec.y + rec.height },
                         ray.Vector2{ .x = rec.x + rec.width, .y = rec.y + rec.height },
                         ray.Vector2{ .x = rec.x + rec.width, .y = rec.y + rec.height - toInt(MOUSE_SCALE_MARK_SIZE) }, ray.RED);
      }

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