//!zig-autodoc-section: textures_sprite_button.Main
//! raylib_examples/textures_sprite_button.zig
//!   Example - sprite button.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - sprite button
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2019-2024 Ramon Santamaria (@raysan5)
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
  const NUM_FRAMES: c_int = 3;       // Number of frames (rectangles) for the button sprite texture

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - sprite button");

  ray.InitAudioDevice();      // Initialize audio device

  const fxButton = ray.LoadSound(getPath("textures", "resources/buttonfx.wav"));   // Load button sound
  const button = ray.LoadTexture(getPath("textures", "resources/button.png")); // Load button texture

  // Define frame rectangle for drawing
  const frameHeight: f32 = toFloat(button.height) / toFloat(NUM_FRAMES);
  var sourceRec = ray.Rectangle{ .x = 0, .y = 0, .width = toFloat(button.width), .height = frameHeight };

  // Define button bounds on screen
  const btnBounds = ray.Rectangle{ 
    .x = toFloat(screenWidth) / 2.0 - toFloat(button.width) / 2.0, 
    .y = toFloat(screenHeight) / 2.0 - toFloat(button.height) / toFloat(NUM_FRAMES) / 2.0, 
    .width = toFloat(button.width), 
    .height = frameHeight 
  };

  var btnState: i32 = 0;               // Button state: 0-NORMAL, 1-MOUSE_HOVER, 2-PRESSED
  var btnAction: bool = false;         // Button action should be activated

  var mousePoint = ray.Vector2{ .x = 0.0, .y = 0.0 };

  ray.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    mousePoint = ray.GetMousePosition();
    btnAction = false;

    // Check button state
    if (ray.CheckCollisionPointRec(mousePoint, btnBounds))
    {
      if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) btnState = 2
      else btnState = 1;

      if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) btnAction = true;
    }
    else btnState = 0;

    if (btnAction)
    {
      ray.PlaySound(fxButton);

      // TODO: Any desired action
    }

    // Calculate button frame rectangle to draw depending on button state
    sourceRec.y =toFloat(btnState) * frameHeight;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTextureRec(button, sourceRec, ray.Vector2{ .x = btnBounds.x, .y = btnBounds.y }, ray.WHITE); // Draw button frame

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(button);  // Unload button texture
  ray.UnloadSound(fxButton);  // Unload sound

  ray.CloseAudioDevice();     // Close audio device

  ray.CloseWindow();          // Close window and OpenGL context
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