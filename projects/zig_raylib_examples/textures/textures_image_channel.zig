//!zig-autodoc-section: textures_image_channel.Main
//! raylib_examples/textures_image_channel.zig
//!   Example - extract channel from image.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Retrive image channel (mask)
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 5.1-dev, last time updated with raylib 5.1-dev
// *
// *   Example contributed by Bruno Cabral (github.com/brccabral) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2024-2024 Bruno Cabral (github.com/brccabral) and Ramon Santamaria (@raysan5)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - extract channel from image");

  const fudesumiImage = ray.LoadImage(getPath("textures", "resources/fudesumi.png"));

  var imageAlpha = ray.ImageFromChannel(fudesumiImage, 3);
  ray.ImageAlphaMask(&imageAlpha, imageAlpha);

  var imageRed = ray.ImageFromChannel(fudesumiImage, 0);
  ray.ImageAlphaMask(&imageRed, imageAlpha);

  var imageGreen = ray.ImageFromChannel(fudesumiImage, 1);
  ray.ImageAlphaMask(&imageGreen, imageAlpha);

  var imageBlue = ray.ImageFromChannel(fudesumiImage, 2);
  ray.ImageAlphaMask(&imageBlue, imageAlpha);

  const backgroundImage = ray.GenImageChecked(screenWidth, screenHeight, screenWidth/20, screenHeight/20, ray.ORANGE, ray.YELLOW);

  const fudesumiTexture = ray.LoadTextureFromImage(fudesumiImage);
  const textureAlpha = ray.LoadTextureFromImage(imageAlpha);
  const textureRed = ray.LoadTextureFromImage(imageRed);
  const textureGreen = ray.LoadTextureFromImage(imageGreen);
  const textureBlue = ray.LoadTextureFromImage(imageBlue);
  const backgroundTexture = ray.LoadTextureFromImage(backgroundImage);

  ray.UnloadImage(fudesumiImage);
  ray.UnloadImage(imageAlpha);
  ray.UnloadImage(imageRed);
  ray.UnloadImage(imageGreen);
  ray.UnloadImage(imageBlue);
  ray.UnloadImage(backgroundImage);

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second

  const fudesumiRec = ray.Rectangle{ .x = 0, .y = 0, .width = toFloatC(fudesumiImage.width), .height = toFloatC(fudesumiImage.height) };
  const fudesumiPos = ray.Rectangle{ .x = 50, .y = 10, .width = toFloatC(fudesumiImage.width) * 0.8, .height = toFloatC(fudesumiImage.height) * 0.8 };
  const redPos = ray.Rectangle{ .x = 410, .y = 10, .width = fudesumiPos.width / 2.0, .height = fudesumiPos.height / 2.0 };
  const greenPos = ray.Rectangle{ .x = 600, .y = 10, .width = fudesumiPos.width / 2.0, .height = fudesumiPos.height / 2.0 };
  const bluePos = ray.Rectangle{ .x = 410, .y = 230, .width = fudesumiPos.width / 2.0, .height = fudesumiPos.height / 2.0 };
  const alphaPos = ray.Rectangle{ .x = 600, .y = 230, .width = fudesumiPos.width / 2.0, .height = fudesumiPos.height / 2.0 };

  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.DrawTexture(backgroundTexture, 0, 0, ray.WHITE);
      ray.DrawTexturePro(fudesumiTexture, fudesumiRec, fudesumiPos, ray.Vector2{ .x = 0, .y = 0 }, 0, ray.WHITE);

      ray.DrawTexturePro(textureRed, fudesumiRec, redPos, ray.Vector2{ .x = 0, .y = 0 }, 0, ray.RED);
      ray.DrawTexturePro(textureGreen, fudesumiRec, greenPos, ray.Vector2{ .x = 0, .y = 0 }, 0, ray.GREEN);
      ray.DrawTexturePro(textureBlue, fudesumiRec, bluePos, ray.Vector2{ .x = 0, .y = 0 }, 0, ray.BLUE);
      ray.DrawTexturePro(textureAlpha, fudesumiRec, alphaPos, ray.Vector2{ .x = 0, .y = 0 }, 0, ray.WHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(backgroundTexture);
  ray.UnloadTexture(fudesumiTexture);
  ray.UnloadTexture(textureRed);
  ray.UnloadTexture(textureGreen);
  ray.UnloadTexture(textureBlue);
  ray.UnloadTexture(textureAlpha);
  ray.CloseWindow();        // Close window and OpenGL context
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