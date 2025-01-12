//!zig-autodoc-section: textures_mouse_painting.Main
//! raylib_examples/textures_mouse_painting.zig
//!   Example - Mouse painting.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Mouse painting
// *
// *   Example originally created with raylib 3.0, last time updated with raylib 3.0
// *
// *   Example contributed by Chris Dill (@MysteriousSpace) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2019-2024 Chris Dill (@MysteriousSpace) and Ramon Santamaria (@raysan5)
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
  const MAX_COLORS_COUNT: c_int = 23;          // Number of colors available

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - mouse painting");

  // Colors to choose from
  const colors = [_]ray.Color{
      ray.RAYWHITE, ray.YELLOW, ray.GOLD, ray.ORANGE, ray.PINK, ray.RED, ray.MAROON, ray.GREEN, ray.LIME, ray.DARKGREEN,
      ray.SKYBLUE, ray.BLUE, ray.DARKBLUE, ray.PURPLE, ray.VIOLET, ray.DARKPURPLE, ray.BEIGE, ray.BROWN, ray.DARKBROWN,
      ray.LIGHTGRAY, ray.GRAY, ray.DARKGRAY, ray.BLACK 
  };

  // Define colorsRecs data (for every rectangle)
  var colorsRecs: [MAX_COLORS_COUNT]ray.Rectangle = undefined;

  for (0..MAX_COLORS_COUNT) |i|
  {
      colorsRecs[i].x = 10.0 + 30.0 * @as(f32, @floatFromInt(i)) + 2.0 * @as(f32, @floatFromInt(i));
      colorsRecs[i].y = 10.0;
      colorsRecs[i].width = 30.0;
      colorsRecs[i].height = 30.0;
  }

  var colorSelected: i32 = 0;
  var colorSelectedPrev: i32 = colorSelected;
  var colorMouseHover: i32 = 0;
  var brushSize: f32 = 20.0;
  var mouseWasPressed = false;

  const btnSaveRec = ray.Rectangle{ .x = 750, .y = 10, .width = 40, .height = 30 };
  var btnSaveMouseHover = false;
  var showSaveMessage = false;
  var saveMessageCounter: i32 = 0;

  // Create a RenderTexture2D to use as a canvas
  const target = ray.LoadRenderTexture(screenWidth, screenHeight);

  // Clear render texture before entering the game loop
  ray.BeginTextureMode(target);
  ray.ClearBackground(colors[0]);
  ray.EndTextureMode();

  ray.SetTargetFPS(120);              // Set our game to run at 120 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    const mousePos = ray.GetMousePosition();

    // Move between colors with keys
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) colorSelected += 1
    else if (ray.IsKeyPressed(ray.KEY_LEFT)) colorSelected -= 1;

    if (colorSelected >= MAX_COLORS_COUNT) colorSelected = MAX_COLORS_COUNT - 1
    else if (colorSelected < 0) colorSelected = 0;

    // Choose color with mouse
    for (0..MAX_COLORS_COUNT) |i|
    {
      if (ray.CheckCollisionPointRec(mousePos, colorsRecs[i]))
      {
        colorMouseHover = @intCast(i);
        break;
      }
      else colorMouseHover = -1;
    }

    if ((colorMouseHover >= 0) and ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT))
    {
      colorSelected = colorMouseHover;
      colorSelectedPrev = colorSelected;
    }

    // Change brush size
    brushSize += ray.GetMouseWheelMove() * 5.0;
    if (brushSize < 2.0) brushSize = 2.0;
    if (brushSize > 50.0) brushSize = 50.0;

    if (ray.IsKeyPressed(ray.KEY_C))
    {
      // Clear render texture to clear color
      ray.BeginTextureMode(target);
      ray.ClearBackground(colors[0]);
      ray.EndTextureMode();
    }

    if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT) or (ray.GetGestureDetected() == ray.GESTURE_DRAG))
    {
      // Paint circle into render texture
      // NOTE: To avoid discontinuous circles, we could store
      // previous-next mouse points and just draw a line using brush size
      ray.BeginTextureMode(target);
      if (mousePos.y > 50) ray.DrawCircle(toInt( mousePos.x), toInt( mousePos.y), brushSize, colors[@intCast(colorSelected)]);
      ray.EndTextureMode();
    }

    if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_RIGHT))
    {
      if (!mouseWasPressed)
      {
        colorSelectedPrev = colorSelected;
        colorSelected = 0;
      }

      mouseWasPressed = true;

      // Erase circle from render texture
      ray.BeginTextureMode(target);
      if (mousePos.y > 50) ray.DrawCircle(toInt( mousePos.x), toInt( mousePos.y), brushSize, colors[0]);
      ray.EndTextureMode();
    }
    else if (ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_RIGHT) and mouseWasPressed)
    {
      colorSelected = colorSelectedPrev;
      mouseWasPressed = false;
    }

    // Check mouse hover save button
    if (ray.CheckCollisionPointRec(mousePos, btnSaveRec)) btnSaveMouseHover = true
    else btnSaveMouseHover = false;

    // Image saving logic
    // NOTE: Saving painted texture to a default named image
    if ((btnSaveMouseHover and ray.IsMouseButtonReleased(ray.MOUSE_BUTTON_LEFT)) or ray.IsKeyPressed(ray.KEY_S))
    {
      var image = ray.LoadImageFromTexture(target.texture);
      ray.ImageFlipVertical(&image);
      _ = ray.ExportImage(image, getPath("", "my_amazing_texture_painting.png"));
      ray.UnloadImage(image);
      showSaveMessage = true;
    }

    if (showSaveMessage)
    {
      // On saving, show a full screen message for 2 seconds
      saveMessageCounter += 1;
      if (saveMessageCounter > 240)
      {
        showSaveMessage = false;
        saveMessageCounter = 0;
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

    ray.ClearBackground(ray.RAYWHITE);

    // NOTE: Render texture must be y-flipped due to default OpenGL coordinates (left-bottom)
    ray.DrawTextureRec(target.texture, ray.Rectangle{ .x = 0, .y = 0, .width = toFloat(target.texture.width), .height = toFloat(-target.texture.height) }, ray.Vector2{ .x = 0, .y = 0 }, ray.WHITE);

    // Draw drawing circle for reference
    if (mousePos.y > 50)
    {
      if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_RIGHT)) ray.DrawCircleLines(toInt( mousePos.x), toInt( mousePos.y), brushSize, ray.GRAY)
      else ray.DrawCircle(toInt( mousePos.x), toInt( mousePos.y), brushSize, colors[@intCast(colorSelected)]);
    }

    // Draw top panel
    ray.DrawRectangle(0, 0, ray.GetScreenWidth(), 50, ray.RAYWHITE);
    ray.DrawLine(0, 50, ray.GetScreenWidth(), 50, ray.LIGHTGRAY);

    // Draw color selection rectangles
    for (0..MAX_COLORS_COUNT) |i| ray.DrawRectangleRec(colorsRecs[i], colors[i]);
    ray.DrawRectangleLines(10, 10, 30, 30, ray.LIGHTGRAY);

    if (colorMouseHover >= 0) ray.DrawRectangleRec(colorsRecs[@intCast(colorMouseHover)], ray.Fade(ray.WHITE, 0.6));

    ray.DrawRectangleLinesEx(ray.Rectangle{ 
      .x = colorsRecs[@intCast(colorSelected)].x - 2, 
      .y = colorsRecs[@intCast(colorSelected)].y - 2,
      .width = colorsRecs[@intCast(colorSelected)].width + 4, 
      .height = colorsRecs[@intCast(colorSelected)].height + 4 
    }, 2, ray.BLACK);

    // Draw save image button
    ray.DrawRectangleLinesEx(btnSaveRec, 2, if (btnSaveMouseHover) ray.RED else ray.BLACK);
    ray.DrawText("SAVE!", 755, 20, 10, if (btnSaveMouseHover) ray.RED else ray.BLACK);

    // Draw save image message
    if (showSaveMessage)
    {
      ray.DrawRectangle(0, 0, ray.GetScreenWidth(), ray.GetScreenHeight(), ray.Fade(ray.RAYWHITE, 0.8));
      ray.DrawRectangle(0, 150, ray.GetScreenWidth(), 80, ray.BLACK);
      ray.DrawText("IMAGE SAVED:  my_amazing_texture_painting.png", 150, 180, 20, ray.RAYWHITE);
    }

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadRenderTexture(target);    // Unload render texture

  ray.CloseWindow();                  // Close window and OpenGL context
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