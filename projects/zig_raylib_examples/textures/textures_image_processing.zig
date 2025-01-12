//!zig-autodoc-section: textures_image_processing.Main
//! raylib_examples/textures_image_processing.zig
//!   Example - Image processing.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Image processing
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 1.4, last time updated with raylib 3.5
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
  const NUM_PROCESSES = 9;

  const ImageProcess = enum {
      NONE,
      COLOR_GRAYSCALE,
      COLOR_TINT,
      COLOR_INVERT,
      COLOR_CONTRAST,
      COLOR_BRIGHTNESS,
      GAUSSIAN_BLUR,
      FLIP_VERTICAL,
      FLIP_HORIZONTAL,
  };

  const processText = [_][]const u8{
      "NO PROCESSING",
      "COLOR GRAYSCALE",
      "COLOR TINT",
      "COLOR INVERT",
      "COLOR CONTRAST",
      "COLOR BRIGHTNESS",
      "GAUSSIAN BLUR",
      "FLIP VERTICAL",
      "FLIP HORIZONTAL"
  };

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - image processing");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)

  var imOrigin = ray.LoadImage(getPath("textures", "resources/parrots.png"));   // Loaded in CPU memory (RAM)
  ray.ImageFormat(&imOrigin, ray.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);         // Format image to RGBA 32bit (required for texture update) <-- ISSUE
  const texture = ray.LoadTextureFromImage(imOrigin);    // Image converted to texture, GPU memory (VRAM)

  var imCopy = ray.ImageCopy(imOrigin);

  var currentProcess: c_int = @intFromEnum(ImageProcess.NONE);
  var textureReload: bool = false;

  var toggleRecs: [NUM_PROCESSES]ray.Rectangle = undefined;
  var mouseHoverRec: i32 = -1;

  for (0..NUM_PROCESSES) |i| toggleRecs[i] = ray.Rectangle{ .x = 40.0, .y = @floatFromInt(50 + 32 * i), .width = 150.0, .height = 30.0 };

  ray.SetTargetFPS(60);
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------

    // Mouse toggle group logic
    for (0..NUM_PROCESSES) |i| {
      if (ray.CheckCollisionPointRec(ray.GetMousePosition(), toggleRecs[i])) {
        mouseHoverRec = @intCast(i);

        if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) {
          currentProcess = @intCast(i);
          textureReload = true;
        }
        break;
      }
      else mouseHoverRec = -1;
    }

    // Keyboard toggle group logic
    if (ray.IsKeyPressed(ray.KEY_DOWN))
    {
      currentProcess = switch (currentProcess) {
        @intFromEnum(ImageProcess.FLIP_HORIZONTAL) => @intFromEnum(ImageProcess.NONE),
        else => currentProcess + 1,
      };
      textureReload = true;
    }
    else if (ray.IsKeyPressed(ray.KEY_UP))
    {
      currentProcess = switch (currentProcess) {
        @intFromEnum(ImageProcess.NONE) => @intFromEnum(ImageProcess.FLIP_HORIZONTAL),
        else => currentProcess - 1,
      };
      textureReload = true;
    }

    // Reload texture when required
    if (textureReload)
    {
      ray.UnloadImage(imCopy);                // Unload image-copy data
      imCopy = ray.ImageCopy(imOrigin);     // Restore image-copy from image-origin

      // NOTE: Image processing is a costly CPU process to be done every frame,
      // If image processing is required in a frame-basis, it should be done
      // with a texture and by shaders
      switch (currentProcess) {
        @intFromEnum(ImageProcess.COLOR_GRAYSCALE) => ray.ImageColorGrayscale(&imCopy),
        @intFromEnum(ImageProcess.COLOR_TINT) => ray.ImageColorTint(&imCopy, ray.GREEN),
        @intFromEnum(ImageProcess.COLOR_INVERT) => ray.ImageColorInvert(&imCopy),
        @intFromEnum(ImageProcess.COLOR_CONTRAST) => ray.ImageColorContrast(&imCopy, -40),
        @intFromEnum(ImageProcess.COLOR_BRIGHTNESS) => ray.ImageColorBrightness(&imCopy, -80),
        @intFromEnum(ImageProcess.GAUSSIAN_BLUR) => ray.ImageBlurGaussian(&imCopy, 10),
        @intFromEnum(ImageProcess.FLIP_VERTICAL) => ray.ImageFlipVertical(&imCopy),
        @intFromEnum(ImageProcess.FLIP_HORIZONTAL) => ray.ImageFlipHorizontal(&imCopy),
        else => {},
      }

      const pixels = ray.LoadImageColors(imCopy);    // Load pixel data from image (RGBA 32bit)
      ray.UpdateTexture(texture, pixels);             // Update texture with new image data
      ray.UnloadImageColors(pixels);                  // Unload pixels data from RAM

      textureReload = false;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("IMAGE PROCESSING:", 40, 30, 10, ray.DARKGRAY);

      // Draw rectangles
      for (0..NUM_PROCESSES) |i|
      {
        ray.DrawRectangleRec(toggleRecs[i], if (i == currentProcess or i == mouseHoverRec) ray.SKYBLUE else ray.LIGHTGRAY);
        ray.DrawRectangleLines(toInt(toggleRecs[i].x), toInt(toggleRecs[i].y), toInt(toggleRecs[i].width), toInt(toggleRecs[i].height), if (i == currentProcess or i == mouseHoverRec) ray.BLUE else ray.GRAY);
        ray.DrawText(processText[i].ptr, toInt(toggleRecs[i].x + toggleRecs[i].width/2 - toFloat(ray.MeasureText(processText[i].ptr, 10))/2), toInt(toggleRecs[i].y + 11), 10, if (i == currentProcess or i == mouseHoverRec) ray.DARKBLUE else ray.DARKGRAY);
      }

      ray.DrawTexture(texture, screenWidth - texture.width - 60, @divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2), ray.WHITE);
      ray.DrawRectangleLines(screenWidth - texture.width - 60, @divTrunc(screenHeight, 2) - @divTrunc(texture.height, 2), texture.width, texture.height, ray.BLACK);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture);       // Unload texture from VRAM
  ray.UnloadImage(imOrigin);        // Unload image-origin from RAM
  ray.UnloadImage(imCopy);          // Unload image-copy from RAM

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