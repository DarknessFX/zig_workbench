//!zig-autodoc-section: textures_srcrec_dstrec.Main
//! raylib_examples/textures_srcrec_dstrec.zig
//!   Example - Texture source and destination.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Texture source and destination rectangles
// *
// *   Example originally created with raylib 1.3, last time updated with raylib 1.3
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
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] examples - texture source and destination rectangles");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)

  const scarfy = ray.LoadTexture(getPath("textures", "resources/scarfy.png"));        // Texture loading

  const frameWidth: f32 = toFloat(@divTrunc(scarfy.width, 6));
  const frameHeight: f32 = toFloat(scarfy.height);

  // Source rectangle (part of the texture to use for drawing)
  const sourceRec = ray.Rectangle{ .x = 0.0, .y = 0.0, .width = frameWidth, .height = frameHeight };

  // Destination rectangle (screen rectangle where drawing part of texture)
  const destRec = ray.Rectangle{ 
    .x = toFloat(screenWidth) / 2.0, 
    .y = toFloat(screenHeight) / 2.0, 
    .width = frameWidth * 2.0, 
    .height = frameHeight * 2.0 
  };

  // Origin of the texture (rotation/scale point), it's relative to destination rectangle size
  const origin = ray.Vector2{ .x = frameWidth, .y = frameHeight };

  var rotation: i32 = 0;

  ray.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    rotation += 1;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      // NOTE: Using DrawTexturePro() we can easily rotate and scale the part of the texture we draw
      // sourceRec defines the part of the texture we use for drawing
      // destRec defines the rectangle where our texture part will fit (scaling it to fit)
      // origin defines the point of the texture used as reference for rotation and scaling
      // rotation defines the texture rotation (using origin as rotation point)
      ray.DrawTexturePro(scarfy, sourceRec, destRec, origin, toFloat(rotation), ray.WHITE);

      ray.DrawLine(toInt(destRec.x), 0, toInt(destRec.x), screenHeight, ray.GRAY);
      ray.DrawLine(0, toInt(destRec.y), screenWidth, toInt(destRec.y), ray.GRAY);

      ray.DrawText("(c) Scarfy sprite by Eiden Marsal", screenWidth - 200, screenHeight - 20, 10, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(scarfy);        // Texture unloading

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