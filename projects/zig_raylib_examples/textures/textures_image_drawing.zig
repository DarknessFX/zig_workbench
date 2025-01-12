//!zig-autodoc-section: textures_image_drawing.Main
//! raylib_examples/textures_image_drawing.zig
//!   Example - Image loading and drawing on it.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Image loading and drawing on it
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 1.4, last time updated with raylib 1.4
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2016-2024 Ramon Santamaria (@raysan5)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - image drawing");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)

  var cat = ray.LoadImage(getPath("textures", "resources/cat.png"));             // Load image in CPU memory (RAM)
  ray.ImageCrop(&cat, ray.Rectangle{ .x = 100, .y = 10, .width = 280, .height = 380 });      // Crop an image piece
  ray.ImageFlipHorizontal(&cat);                              // Flip cropped image horizontally
  ray.ImageResize(&cat, 150, 200);                            // Resize flipped-cropped image

  var parrots = ray.LoadImage(getPath("textures", "resources/parrots.png"));     // Load image in CPU memory (RAM)

  // Draw one image over the other with a scaling of 1.5f
  ray.ImageDraw(&parrots, cat, ray.Rectangle{ .x = 0, .y = 0, .width = toFloatC(cat.width), .height = toFloatC(cat.height) }, ray.Rectangle{ .x = 30, .y = 40, .width = toFloatC(cat.width) * 1.5, .height = toFloatC(cat.height) * 1.5 }, ray.WHITE);
  ray.ImageCrop(&parrots, ray.Rectangle{ .x = 0, .y = 50, .width = toFloatC(parrots.width), .height = toFloatC(parrots.height) - 100 }); // Crop resulting image

  // Draw on the image with a few image draw methods
  ray.ImageDrawPixel(&parrots, 10, 10, ray.RAYWHITE);
  ray.ImageDrawCircleLines(&parrots, 10, 10, 5, ray.RAYWHITE);
  ray.ImageDrawRectangle(&parrots, 5, 20, 10, 10, ray.RAYWHITE);

  ray.UnloadImage(cat);       // Unload image from RAM

  // Load custom font for drawing on image
  const font = ray.LoadFont(getPath("textures", "resources/custom_jupiter_crash.png"));

  // Draw over image using custom font
  ray.ImageDrawTextEx(&parrots, font, "PARROTS & CAT", ray.Vector2{ .x = 300, .y = 230 }, toFloatC(font.baseSize), -2, ray.WHITE);

  ray.UnloadFont(font);       // Unload custom font (already drawn used on image)

  const texture = ray.LoadTextureFromImage(parrots);      // Image converted to texture, uploaded to GPU memory (VRAM)
  ray.UnloadImage(parrots);   // Once image has been converted to texture and uploaded to VRAM, it can be unloaded from RAM

  ray.SetTargetFPS(60);
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawTexture(texture, @divTrunc(screenWidth, 2) - @divTrunc(texture.width, 2), @divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2) - 40, ray.WHITE);
      ray.DrawRectangleLines(@divTrunc(screenWidth, 2) - @divTrunc(texture.width, 2), @divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2) - 40, texture.width, texture.height, ray.DARKGRAY);

      ray.DrawText("We are drawing only one texture from various images composed!", 240, 350, 10, ray.DARKGRAY);
      ray.DrawText("Source images have been cropped, scaled, flipped and copied one over the other.", 190, 370, 10, ray.DARKGRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture);       // Texture unloading

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