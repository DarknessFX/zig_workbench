//!zig-autodoc-section: text_input_box.Main
//! raylib_examples/text_input_box.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Input Box
// *
// *   Example originally created with raylib 1.7, last time updated with raylib 3.5
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
  const MAX_INPUT_CHARS: c_int = 9;
  
  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - input box");

  var name = [_]u8{0} ** (MAX_INPUT_CHARS + 1); // NOTE: One extra space required for null terminator char '\0'
  var letterCount: i32 = 0;

  const textBox = ray.Rectangle{
    .x = toFloat(screenWidth) / 2.0 - 100.0,
    .y = 180.0,
    .width = 225.0,
    .height = 50.0,
  };
  var mouseOnText = false;

  var framesCounter: i32 = 0;

  ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //

  // Main game loop
  while (!ray.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (ray.CheckCollisionPointRec(ray.GetMousePosition(), textBox)) mouseOnText = true
    else mouseOnText = false;

    if (mouseOnText) {
      // Set the window's cursor to the I-Beam
      ray.SetMouseCursor(ray.MOUSE_CURSOR_IBEAM);

      // Get char pressed (unicode character) on the queue
      var key = ray.GetCharPressed();

      // Check if more characters have been pressed on the same frame
      while (key > 0) {
        // NOTE: Only allow keys in range [32..125]
        if (key >= 32 and key <= 125 and letterCount < MAX_INPUT_CHARS) {
          name[@intCast(letterCount)] = @intCast(key);
          name[@intCast(letterCount + 1)] = 0; // Add null terminator at the end of the string.
          letterCount += 1;
        }

        key = ray.GetCharPressed(); // Check next character in the queue
      }

      if (ray.IsKeyPressed(ray.KEY_BACKSPACE)) {
        letterCount -= 1;
        if (letterCount < 0) letterCount = 0;
        name[@intCast(letterCount)] = 0;
      }
    } else ray.SetMouseCursor(ray.MOUSE_CURSOR_DEFAULT);

    if (mouseOnText) framesCounter += 1
    else framesCounter = 0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("PLACE MOUSE OVER INPUT BOX!", 240, 140, 20, ray.GRAY);

      ray.DrawRectangleRec(textBox, ray.LIGHTGRAY);
      if (mouseOnText) ray.DrawRectangleLines(toInt(textBox.x), toInt(textBox.y), toInt(textBox.width), toInt(textBox.height), ray.RED)
      else ray.DrawRectangleLines(toInt(textBox.x), toInt(textBox.y), toInt(textBox.width), toInt(textBox.height), ray.DARKGRAY);

      ray.DrawText(name[0..], toInt(textBox.x) + 5, toInt(textBox.y) + 8, 40, ray.MAROON);

      ray.DrawText(ray.TextFormat("INPUT CHARS: %d/%d", letterCount, MAX_INPUT_CHARS), 315, 250, 20, ray.DARKGRAY);

      if (mouseOnText) {
        if (letterCount < MAX_INPUT_CHARS) {
          // Draw blinking underscore char
          if (@mod(@divFloor(toFloat(framesCounter), 20.0), 2) == 0) ray.DrawText("_", toInt(textBox.x) + 8 + ray.MeasureText(name[0..], 40), toInt(textBox.y) + 12, 40, ray.MAROON);
        } else ray.DrawText("Press BACKSPACE to delete chars...", 230, 300, 20, ray.GRAY);
      }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //

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