//!zig-autodoc-section: textures_image_generation.Main
//! raylib_examples/textures_image_generation.zig
//!   Example - Procedural images generation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Procedural images generation
// *
// *   Example originally created with raylib 1.8, last time updated with raylib 1.8
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2O17-2024 Wilhem Barbier (@nounoursheureux) and Ramon Santamaria (@raysan5)
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
  const NUM_TEXTURES = 9;      // Currently we have 8 generation algorithms but some have multiple purposes (Linear and Square Gradients)

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - procedural images generation");

  const verticalGradient = ray.GenImageGradientLinear(screenWidth, screenHeight, 0, ray.RED, ray.BLUE);
  const horizontalGradient = ray.GenImageGradientLinear(screenWidth, screenHeight, 90, ray.RED, ray.BLUE);
  const diagonalGradient = ray.GenImageGradientLinear(screenWidth, screenHeight, 45, ray.RED, ray.BLUE);
  const radialGradient = ray.GenImageGradientRadial(screenWidth, screenHeight, 0.0, ray.WHITE, ray.BLACK);
  const squareGradient = ray.GenImageGradientSquare(screenWidth, screenHeight, 0.0, ray.WHITE, ray.BLACK);
  const checked = ray.GenImageChecked(screenWidth, screenHeight, 32, 32, ray.RED, ray.BLUE);
  const whiteNoise = ray.GenImageWhiteNoise(screenWidth, screenHeight, 0.5);
  const perlinNoise = ray.GenImagePerlinNoise(screenWidth, screenHeight, 50, 50, 4.0);
  const cellular = ray.GenImageCellular(screenWidth, screenHeight, 32);

  var textures: [NUM_TEXTURES]ray.Texture2D = undefined;

  textures[0] = ray.LoadTextureFromImage(verticalGradient);
  textures[1] = ray.LoadTextureFromImage(horizontalGradient);
  textures[2] = ray.LoadTextureFromImage(diagonalGradient);
  textures[3] = ray.LoadTextureFromImage(radialGradient);
  textures[4] = ray.LoadTextureFromImage(squareGradient);
  textures[5] = ray.LoadTextureFromImage(checked);
  textures[6] = ray.LoadTextureFromImage(whiteNoise);
  textures[7] = ray.LoadTextureFromImage(perlinNoise);
  textures[8] = ray.LoadTextureFromImage(cellular);

  // Unload image data (CPU RAM)
  ray.UnloadImage(verticalGradient);
  ray.UnloadImage(horizontalGradient);
  ray.UnloadImage(diagonalGradient);
  ray.UnloadImage(radialGradient);
  ray.UnloadImage(squareGradient);
  ray.UnloadImage(checked);
  ray.UnloadImage(whiteNoise);
  ray.UnloadImage(perlinNoise);
  ray.UnloadImage(cellular);

  var currentTexture: i32 = 0;

  ray.SetTargetFPS(60);
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())
  {
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT) or ray.IsKeyPressed(ray.KEY_RIGHT))
    {
      currentTexture = @mod(currentTexture + 1, NUM_TEXTURES); // Cycle between the textures
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(textures[@intCast(currentTexture)], 0, 0, ray.WHITE);

      ray.DrawRectangle(30, 400, 325, 30, ray.Fade(ray.SKYBLUE, 0.5));
      ray.DrawRectangleLines(30, 400, 325, 30, ray.Fade(ray.WHITE, 0.5));
      ray.DrawText("MOUSE LEFT BUTTON to CYCLE PROCEDURAL TEXTURES", 40, 410, 10, ray.WHITE);

      switch(currentTexture) {
        0 => ray.DrawText("VERTICAL GRADIENT", 560, 10, 20, ray.RAYWHITE),
        1 => ray.DrawText("HORIZONTAL GRADIENT", 540, 10, 20, ray.RAYWHITE),
        2 => ray.DrawText("DIAGONAL GRADIENT", 540, 10, 20, ray.RAYWHITE),
        3 => ray.DrawText("RADIAL GRADIENT", 580, 10, 20, ray.LIGHTGRAY),
        4 => ray.DrawText("SQUARE GRADIENT", 580, 10, 20, ray.LIGHTGRAY),
        5 => ray.DrawText("CHECKED", 680, 10, 20, ray.RAYWHITE),
        6 => ray.DrawText("WHITE NOISE", 640, 10, 20, ray.RED),
        7 => ray.DrawText("PERLIN NOISE", 640, 10, 20, ray.RED),
        8 => ray.DrawText("CELLULAR", 670, 10, 20, ray.RAYWHITE),
        else => {},
      }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------

  // Unload textures data (GPU VRAM)
  for (0..textures.len) |i| {
    ray.UnloadTexture(textures[i]);
  }

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