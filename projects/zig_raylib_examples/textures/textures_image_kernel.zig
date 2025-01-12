//!zig-autodoc-section: textures_image_kernel.Main
//! raylib_examples/textures_image_kernel.zig
//!   Example - Image loading and texture creation.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Image loading and texture creation
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 1.3, last time updated with raylib 1.3
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2015-2024 Karim Salem (@kimo-s)
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
fn NormalizeKernel(kernel: [*]f32, size: i32) void {
  var sum: f32 = 0.0;
  var i: usize = 0;
  while (i < size) : (i += 1) sum += kernel[i];

  if (sum != 0.0) {
    i = 0;
    while (i < size) : (i += 1) kernel[i] /= sum;
  }
}

pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - image convolution");

  var image = ray.LoadImage(getPath("textures", "resources/cat.png"));     // Loaded in CPU memory (RAM)

  var gaussiankernel = [_]f32{ 
    1.0, 2.0, 1.0,
    2.0, 4.0, 2.0,
    1.0, 2.0, 1.0 
  };

  var sobelkernel = [_]f32{
    1.0, 0.0, -1.0,
    2.0, 0.0, -2.0,
    1.0, 0.0, -1.0 
  };

  var sharpenkernel = [_]f32{
    0.0, -1.0, 0.0,
   -1.0, 5.0, -1.0,
    0.0, -1.0, 0.0 
  };

  NormalizeKernel(&gaussiankernel, 9);
  NormalizeKernel(&sharpenkernel, 9);
  NormalizeKernel(&sobelkernel, 9);

  var catSharpend = ray.ImageCopy(image);
  ray.ImageKernelConvolution(&catSharpend, &sharpenkernel, 9);

  var catSobel = ray.ImageCopy(image);
  ray.ImageKernelConvolution(&catSobel, &sobelkernel, 9);

  var catGaussian = ray.ImageCopy(image);

  var i: i32 = 0;
  while (i < 6) : (i += 1)
  {
    ray.ImageKernelConvolution(&catGaussian, &gaussiankernel, 9);
  }

  ray.ImageCrop(&image, ray.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 450 });
  ray.ImageCrop(&catGaussian, ray.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 450 });
  ray.ImageCrop(&catSobel, ray.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 450 });
  ray.ImageCrop(&catSharpend, ray.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 450 });

  // Images converted to texture, GPU memory (VRAM)
  const texture = ray.LoadTextureFromImage(image);
  const catSharpendTexture = ray.LoadTextureFromImage(catSharpend);
  const catSobelTexture = ray.LoadTextureFromImage(catSobel);
  const catGaussianTexture = ray.LoadTextureFromImage(catGaussian);

  // Once images have been converted to texture and uploaded to VRAM, 
  // they can be unloaded from RAM
  ray.UnloadImage(image);
  ray.UnloadImage(catGaussian);
  ray.UnloadImage(catSobel);
  ray.UnloadImage(catSharpend);

  ray.SetTargetFPS(60);     // Set our game to run at 60 frames-per-second
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

      ray.DrawTexture(catSharpendTexture, 0, 0, ray.WHITE);
      ray.DrawTexture(catSobelTexture, 200, 0, ray.WHITE);
      ray.DrawTexture(catGaussianTexture, 400, 0, ray.WHITE);
      ray.DrawTexture(texture, 600, 0, ray.WHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture);
  ray.UnloadTexture(catGaussianTexture);
  ray.UnloadTexture(catSobelTexture);
  ray.UnloadTexture(catSharpendTexture);

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