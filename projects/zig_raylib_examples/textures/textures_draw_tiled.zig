//!zig-autodoc-section: textures_draw_tiled.Main
//! raylib_examples/textures_draw_tiled.zig
//!   Example - Draw part of a texture tiled.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Draw part of the texture tiled
// *
// *   Example originally created with raylib 3.0, last time updated with raylib 4.2
// *
// *   Example contributed by Vlad Adrian (@demizdor) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2020-2024 Vlad Adrian (@demizdor) and Ramon Santamaria (@raysan5)
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

  const OPT_WIDTH: c_int = 220;      // Max width for the options container
  const MARGIN_SIZE: c_int = 8;      // Size for the margins
  const COLOR_SIZE: c_int = 16;      // Size of the color select buttons

  ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE); // Make the window resizable
  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - Draw part of a texture tiled");

  // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
  const texPattern = ray.LoadTexture(getPath("textures", "resources/patterns.png"));
  ray.SetTextureFilter(texPattern, ray.TEXTURE_FILTER_TRILINEAR); // Makes the texture smoother when upscaled

  // Coordinates for all patterns inside the texture
  const recPattern = [_]ray.Rectangle{
    ray.Rectangle{ .x = 3, .y = 3, .width = 66, .height = 66 },
    ray.Rectangle{ .x = 75, .y = 3, .width = 100, .height = 100 },
    ray.Rectangle{ .x = 3, .y = 75, .width = 66, .height = 66 },
    ray.Rectangle{ .x = 7, .y = 156, .width = 50, .height = 50 },
    ray.Rectangle{ .x = 85, .y = 106, .width = 90, .height = 45 },
    ray.Rectangle{ .x = 75, .y = 154, .width = 100, .height = 60 },
  };

  // Setup colors
  const colors = [_]ray.Color{
    ray.BLACK, ray.MAROON, ray.ORANGE, ray.BLUE, ray.PURPLE, ray.BEIGE, ray.LIME, ray.RED, ray.DARKGRAY, ray.SKYBLUE
  };
  const MAX_COLORS = @as(i32, colors.len);
  var colorRec: [MAX_COLORS]ray.Rectangle = undefined;

  // Calculate rectangle for each color
  var x: f32 = 0.0;
  var y: f32 = 0.0;
  for (0..MAX_COLORS) |i| {
    colorRec[i].x = 2.0 + toFloat(MARGIN_SIZE) + x;
    colorRec[i].y = 22.0 + 256.0 + toFloat(MARGIN_SIZE) + y;
    colorRec[i].width = toFloat(COLOR_SIZE) * 2.0;
    colorRec[i].height = toFloat(COLOR_SIZE);

    if (i == (MAX_COLORS / 2 - 1)) {
      x = 0.0;
      y += toFloat(COLOR_SIZE) + toFloat(MARGIN_SIZE);
    } else {
      x += toFloat(COLOR_SIZE) * 2.0 + toFloat(MARGIN_SIZE);
    }
  }

  var activePattern: i32 = 0;
  var activeCol: i32 = 0;
  var scale: f32 = 1.0;
  var rotation: f32 = 0.0;

  ray.SetTargetFPS(60);
  //---------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // Handle mouse
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT))
    {
      const mouse = ray.GetMousePosition();

      // Check which pattern was clicked and set it as the active pattern
      for (0..recPattern.len) |i| {
        if (ray.CheckCollisionPointRec(mouse, ray.Rectangle{ 
          .x = 2 + toFloat(MARGIN_SIZE) + recPattern[i].x, 
          .y = 40 + toFloat(MARGIN_SIZE) + recPattern[i].y, 
          .width = recPattern[i].width, 
          .height = recPattern[i].height 
        })) {
          activePattern = @intCast(i);
          break;
        }
      }

      // Check to see which color was clicked and set it as the active color
      for (0..MAX_COLORS) |i| {
        if (ray.CheckCollisionPointRec(mouse, colorRec[i])) {
          activeCol = @intCast(i);
          break;
        }
      }
    }

    // Handle keys

    // Change scale
    if (ray.IsKeyPressed(ray.KEY_UP)) scale += 0.25;
    if (ray.IsKeyPressed(ray.KEY_DOWN)) scale -= 0.25;
    if (scale > 10.0) scale = 10.0
    else if (scale <= 0.0) scale = 0.25;

    // Change rotation
    if (ray.IsKeyPressed(ray.KEY_LEFT)) rotation -= 25.0;
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) rotation += 25.0;

    // Reset
    if (ray.IsKeyPressed(ray.KEY_SPACE)) { rotation = 0.0; scale = 1.0; }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();
      ray.ClearBackground(ray.RAYWHITE);

      // Draw the tiled area
      DrawTextureTiled(texPattern, recPattern[@intCast(activePattern)], ray.Rectangle{
        .x = toFloat(OPT_WIDTH) + toFloat(MARGIN_SIZE), 
        .y = toFloat(MARGIN_SIZE), 
        .width = toFloat(ray.GetScreenWidth()) - toFloat(OPT_WIDTH) - 2.0 * toFloat(MARGIN_SIZE), 
        .height = toFloat(ray.GetScreenHeight()) - 2.0 * toFloat(MARGIN_SIZE)
      }, ray.Vector2{ .x = 0.0, .y = 0.0 }, rotation, scale, colors[@intCast(activeCol)]);

      // Draw options
      ray.DrawRectangle(MARGIN_SIZE, MARGIN_SIZE, OPT_WIDTH - MARGIN_SIZE, ray.GetScreenHeight() - 2 * MARGIN_SIZE, ray.ColorAlpha(ray.LIGHTGRAY, 0.5));

      ray.DrawText("Select Pattern", 2 + MARGIN_SIZE, 30 + MARGIN_SIZE, 10, ray.BLACK);
      ray.DrawTexture(texPattern, 2 + MARGIN_SIZE, 40 + MARGIN_SIZE, ray.BLACK);
      ray.DrawRectangle(toInt(2 + toFloat(MARGIN_SIZE) + recPattern[@intCast(activePattern)].x), 
                        toInt(40 + toFloat(MARGIN_SIZE) + recPattern[@intCast(activePattern)].y), 
                        toInt(recPattern[@intCast(activePattern)].width), 
                        toInt(recPattern[@intCast(activePattern)].height), ray.ColorAlpha(ray.DARKBLUE, 0.3));

      ray.DrawText("Select Color", 2 + MARGIN_SIZE, 10 + 256 + MARGIN_SIZE, 10, ray.BLACK);
      for (0..MAX_COLORS) |i| {
        ray.DrawRectangleRec(colorRec[i], colors[i]);
        if (activeCol == i) ray.DrawRectangleLinesEx(colorRec[i], 3, ray.ColorAlpha(ray.WHITE, 0.5));
      }

      ray.DrawText("Scale (UP/DOWN to change)", 2 + MARGIN_SIZE, 80 + 256 + MARGIN_SIZE, 10, ray.BLACK);
      ray.DrawText(ray.TextFormat("%.2fx", scale), 2 + MARGIN_SIZE, 92 + 256 + MARGIN_SIZE, 20, ray.BLACK);

      ray.DrawText("Rotation (LEFT/RIGHT to change)", 2 + MARGIN_SIZE, 122 + 256 + MARGIN_SIZE, 10, ray.BLACK);
      ray.DrawText(ray.TextFormat("%.0f degrees", rotation), 2 + MARGIN_SIZE, 134 + 256 + MARGIN_SIZE, 20, ray.BLACK);

      ray.DrawText("Press [SPACE] to reset", 2 + MARGIN_SIZE, 164 + 256 + MARGIN_SIZE, 10, ray.DARKBLUE);

      // Draw FPS
      ray.DrawText(ray.TextFormat("%i FPS", ray.GetFPS()), 2 + MARGIN_SIZE, 2 + MARGIN_SIZE, 20, ray.BLACK);
    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texPattern);        // Unload texture

  ray.CloseWindow();              // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
  return 0;
}

// Draw part of a texture (defined by a rectangle) with rotation and scale tiled into dest.
fn DrawTextureTiled(texture: ray.Texture2D, source: ray.Rectangle, dest: ray.Rectangle, origin: ray.Vector2, rotation: f32, scale: f32, tint: ray.Color) void
{
  if ((texture.id <= 0) or (scale <= 0.0)) return;  // Wanna see an infinite loop?!...just delete this line!
  if ((source.width == 0) or (source.height == 0)) return;

  const tileWidth = toInt(source.width * scale);
  const tileHeight = toInt(source.height * scale);
  if ((dest.width < toFloat(tileWidth)) and (dest.height < toFloat(tileHeight)))
  {
    // Can fit only one tile
    ray.DrawTexturePro(texture, ray.Rectangle{
      .x = source.x, 
      .y = source.y, 
      .width = (dest.width / toFloat(tileWidth)) * source.width, 
      .height = (dest.height / toFloat(tileHeight)) * source.height
    }, ray.Rectangle{
      .x = dest.x, 
      .y = dest.y, 
      .width = dest.width, 
      .height = dest.height
    }, origin, rotation, tint);
  }
  else if (dest.width <= toFloat(tileWidth))
  {
    // Tiled vertically (one column)
    var dy: i32 = 0;
    while (dy + tileHeight < toInt(dest.height)) : (dy += tileHeight)
    {
      ray.DrawTexturePro(texture, ray.Rectangle{
        .x = source.x, 
        .y = source.y, 
        .width = (dest.width / toFloat(tileWidth)) * source.width, 
        .height = source.height
      }, ray.Rectangle{
        .x = dest.x, 
        .y = dest.y + toFloat(dy), 
        .width = dest.width, 
        .height = toFloat(tileHeight)
      }, origin, rotation, tint);
    }

    // Fit last tile
    if (dy < toInt(dest.height))
    {
      ray.DrawTexturePro(texture, ray.Rectangle{
        .x = source.x, 
        .y = source.y, 
        .width = (dest.width / toFloat(tileWidth)) * source.width, 
        .height = (dest.height - toFloat(dy)) / toFloat(tileHeight) * source.height
      }, ray.Rectangle{
        .x = dest.x, 
        .y = dest.y + toFloat(dy), 
        .width = dest.width, 
        .height = dest.height - toFloat(dy)
      }, origin, rotation, tint);
    }
  }
  else if (dest.height <= toFloat(tileHeight))
  {
    // Tiled horizontally (one row)
    var dx: i32 = 0;
    while (dx + tileWidth < toInt(dest.width)) : (dx += tileWidth)
    {
      ray.DrawTexturePro(texture, ray.Rectangle{
        .x = source.x, 
        .y = source.y, 
        .width = source.width, 
        .height = (dest.height / toFloat(tileHeight)) * source.height
      }, ray.Rectangle{
        .x = dest.x + toFloat(dx), 
        .y = dest.y, 
        .width = toFloat(tileWidth), 
        .height = dest.height
      }, origin, rotation, tint);
    }

    // Fit last tile
    if (dx < toInt(dest.width))
    {
      ray.DrawTexturePro(texture, ray.Rectangle{
        .x = source.x, 
        .y = source.y, 
        .width = ((dest.width - toFloat(dx)) / toFloat(tileWidth)) * source.width, 
        .height = (dest.height / toFloat(tileHeight)) * source.height
      }, ray.Rectangle{
        .x = dest.x + toFloat(dx), 
        .y = dest.y, 
        .width = dest.width - toFloat(dx), 
        .height = dest.height
      }, origin, rotation, tint);
    }
  }
  else
  {
    // Tiled both horizontally and vertically (rows and columns)
    var dx: i32 = 0;
    while (dx + tileWidth < toInt(dest.width)) : (dx += tileWidth)
    {
      var dy: i32 = 0;
      while (dy + tileHeight < toInt(dest.height)) : (dy += tileHeight)
      {
        ray.DrawTexturePro(texture, source, ray.Rectangle{
          .x = dest.x + toFloat(dx), 
          .y = dest.y + toFloat(dy), 
          .width = toFloat(tileWidth), 
          .height = toFloat(tileHeight)
        }, origin, rotation, tint);
      }

      if (dy < toInt(dest.height))
      {
        ray.DrawTexturePro(texture, ray.Rectangle{
          .x = source.x, 
          .y = source.y, 
          .width = source.width, 
          .height = ((dest.height - toFloat(dy)) / toFloat(tileHeight)) * source.height
        }, ray.Rectangle{
          .x = dest.x + toFloat(dx), 
          .y = dest.y + toFloat(dy), 
          .width = toFloat(tileWidth), 
          .height = dest.height - toFloat(dy)
        }, origin, rotation, tint);
      }
    }

    // Fit last column of tiles
    if (dx < toInt(dest.width))
    {
      var dy: i32 = 0;
      while (dy + tileHeight < toInt(dest.height)) : (dy += tileHeight)
      {
        ray.DrawTexturePro(texture, ray.Rectangle{
          .x = source.x, 
          .y = source.y, 
          .width = ((dest.width - toFloat(dx)) / toFloat(tileWidth)) * source.width, 
          .height = source.height
        }, ray.Rectangle{
          .x = dest.x + toFloat(dx), 
          .y = dest.y + toFloat(dy), 
          .width = dest.width - toFloat(dx), 
          .height = toFloat(tileHeight)
        }, origin, rotation, tint);
      }

      // Draw final tile in the bottom right corner
      if (dy < toInt(dest.height))
      {
        ray.DrawTexturePro(texture, ray.Rectangle{
          .x = source.x, 
          .y = source.y, 
          .width = ((dest.width - toFloat(dx)) / toFloat(tileWidth)) * source.width, 
          .height = ((dest.height - toFloat(dy)) / toFloat(tileHeight)) * source.height
        }, ray.Rectangle{
          .x = dest.x + toFloat(dx), 
          .y = dest.y + toFloat(dy), 
          .width = dest.width - toFloat(dx), 
          .height = dest.height - toFloat(dy)
        }, origin, rotation, tint);
      }
    }
  }
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