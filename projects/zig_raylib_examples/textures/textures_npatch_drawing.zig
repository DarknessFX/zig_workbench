//!zig-autodoc-section: textures_npatch_drawing.Main
//! raylib_examples/textures_npatch_drawing.zig
//!   Example - N-patch drawing.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - N-patch drawing
// *
// *   NOTE: Images are loaded in CPU memory (RAM); textures are loaded in GPU memory (VRAM)
// *
// *   Example originally created with raylib 2.0, last time updated with raylib 2.5
// *
// *   Example contributed by Jorge A. Gomes (@overdev) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2018-2024 Jorge A. Gomes (@overdev) and Ramon Santamaria (@raysan5)
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

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - N-patch drawing");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  const nPatchTexture = ray.LoadTexture(getPath("textures", "resources/ninepatch_button.png"));

  var mousePosition = ray.Vector2{ .x = 0, .y = 0 };
  const origin = ray.Vector2{ .x = 0.0, .y = 0.0 };

  // Position and size of the n-patches
  var dstRec1 = ray.Rectangle{ .x = 480.0, .y = 160.0, .width = 32.0, .height = 32.0 };
  var dstRec2 = ray.Rectangle{ .x = 160.0, .y = 160.0, .width = 32.0, .height = 32.0 };
  var dstRecH = ray.Rectangle{ .x = 160.0, .y = 93.0, .width = 32.0, .height = 32.0 };
  var dstRecV = ray.Rectangle{ .x = 92.0, .y = 160.0, .width = 32.0, .height = 32.0 };

  // A 9-patch (NPATCH_NINE_PATCH) changes its sizes in both axis
  const ninePatchInfo1 = ray.NPatchInfo{ 
    .source = ray.Rectangle{ .x = 0.0, .y = 0.0, .width = 64.0, .height = 64.0 },
    .left = 12,
    .top = 40,
    .right = 12,
    .bottom = 12,
    .layout = ray.NPATCH_NINE_PATCH,
  };
  const ninePatchInfo2 = ray.NPatchInfo{ 
    .source = ray.Rectangle{ .x = 0.0, .y = 128.0, .width = 64.0, .height = 64.0 },
    .left = 16,
    .top = 16,
    .right = 16,
    .bottom = 16,
    .layout = ray.NPATCH_NINE_PATCH,
  };

  // A horizontal 3-patch (NPATCH_THREE_PATCH_HORIZONTAL) changes its sizes along the x axis only
  const h3PatchInfo = ray.NPatchInfo{ 
    .source = ray.Rectangle{ .x = 0.0, .y = 64.0, .width = 64.0, .height = 64.0 },
    .left = 8,
    .top = 8,
    .right = 8,
    .bottom = 8,
    .layout = ray.NPATCH_THREE_PATCH_HORIZONTAL,
  };

  // A vertical 3-patch (NPATCH_THREE_PATCH_VERTICAL) changes its sizes along the y axis only
  const v3PatchInfo = ray.NPatchInfo{ 
    .source = ray.Rectangle{ .x = 0.0, .y = 192.0, .width = 64.0, .height = 64.0 },
    .left = 6,
    .top = 6,
    .right = 6,
    .bottom = 6,
    .layout = ray.NPATCH_THREE_PATCH_VERTICAL,
  };

  ray.SetTargetFPS(60);
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    mousePosition = ray.GetMousePosition();

    // Resize the n-patches based on mouse position
    dstRec1.width = mousePosition.x - dstRec1.x;
    dstRec1.height = mousePosition.y - dstRec1.y;
    dstRec2.width = mousePosition.x - dstRec2.x;
    dstRec2.height = mousePosition.y - dstRec2.y;
    dstRecH.width = mousePosition.x - dstRecH.x;
    dstRecV.height = mousePosition.y - dstRecV.y;

    // Set a minimum width and/or height
    if (dstRec1.width < 1.0) dstRec1.width = 1.0;
    if (dstRec1.width > 300.0) dstRec1.width = 300.0;
    if (dstRec1.height < 1.0) dstRec1.height = 1.0;
    if (dstRec2.width < 1.0) dstRec2.width = 1.0;
    if (dstRec2.width > 300.0) dstRec2.width = 300.0;
    if (dstRec2.height < 1.0) dstRec2.height = 1.0;
    if (dstRecH.width < 1.0) dstRecH.width = 1.0;
    if (dstRecV.height < 1.0) dstRecV.height = 1.0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      // Draw the n-patches
      ray.DrawTextureNPatch(nPatchTexture, ninePatchInfo2, dstRec2, origin, 0.0, ray.WHITE);
      ray.DrawTextureNPatch(nPatchTexture, ninePatchInfo1, dstRec1, origin, 0.0, ray.WHITE);
      ray.DrawTextureNPatch(nPatchTexture, h3PatchInfo, dstRecH, origin, 0.0, ray.WHITE);
      ray.DrawTextureNPatch(nPatchTexture, v3PatchInfo, dstRecV, origin, 0.0, ray.WHITE);

      // Draw the source texture
      ray.DrawRectangleLines(5, 88, 74, 266, ray.BLUE);
      ray.DrawTexture(nPatchTexture, 10, 93, ray.WHITE);
      ray.DrawText("TEXTURE", 15, 360, 10, ray.DARKGRAY);

      ray.DrawText("Move the mouse to stretch or shrink the n-patches", 10, 20, 20, ray.DARKGRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(nPatchTexture);       // Texture unloading

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