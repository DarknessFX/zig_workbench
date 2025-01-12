//!zig-autodoc-section: textures_polygon.Main
//! raylib_examples/textures_polygon.zig
//!   Example - Draw Textured Polygon.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - Draw Textured Polygon
// *
// *   Example originally created with raylib 3.7, last time updated with raylib 3.7
// *
// *   Example contributed by Chris Camacho (@codifies) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2021-2024 Chris Camacho (@codifies) and Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
  @cInclude("rlgl.h"); 
  @cInclude("raymath.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  const MAX_POINTS = 11;      // 10 points and back to the start

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - textured polygon");

  // Define texture coordinates to map our texture to poly
  var texcoords = [_]ray.Vector2{
    ray.Vector2{ .x = 0.75, .y = 0.0 },
    ray.Vector2{ .x = 0.25, .y = 0.0 },
    ray.Vector2{ .x = 0.0, .y = 0.5 },
    ray.Vector2{ .x = 0.0, .y = 0.75 },
    ray.Vector2{ .x = 0.25, .y = 1.0 },
    ray.Vector2{ .x = 0.375, .y = 0.875 },
    ray.Vector2{ .x = 0.625, .y = 0.875 },
    ray.Vector2{ .x = 0.75, .y = 1.0 },
    ray.Vector2{ .x = 1.0, .y = 0.75 },
    ray.Vector2{ .x = 1.0, .y = 0.5 },
    ray.Vector2{ .x = 0.75, .y = 0.0 },  // Close the poly
  };

  // Define the base poly vertices from the UV's
  // NOTE: They can be specified in any other way
  var points: [MAX_POINTS]ray.Vector2 = undefined;
  for (0..MAX_POINTS) |i|
  {
    points[i].x = (texcoords[i].x - 0.5) * 256.0;
    points[i].y = (texcoords[i].y - 0.5) * 256.0;
  }

  // Define the vertices drawing position
  // NOTE: Initially same as points but updated every frame
  var positions: [MAX_POINTS]ray.Vector2 = undefined;
  for (0..MAX_POINTS) |i| positions[i] = points[i];

  // Load texture to be mapped to poly
  const texture = ray.LoadTexture(getPath("textures", "resources/cat.png"));

  var angle: f32 = 0.0;             // Rotation angle (in degrees)

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // Update points rotation with an angle transform
    // NOTE: Base points position are not modified
    angle += 1.0;
    for (0..MAX_POINTS) |i| positions[i] = ray.Vector2Rotate(points[i], angle * ray.DEG2RAD);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawText("textured polygon", 20, 20, 20, ray.DARKGRAY);

      DrawTexturePoly(texture, ray.Vector2{ 
        .x = toFloatC(ray.GetScreenWidth()) / 2.0,
        .y = toFloatC(ray.GetScreenHeight()) / 2.0 },
        &positions, &texcoords, MAX_POINTS, ray.WHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texture); // Unload texture

  ray.CloseWindow();          // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
  return 0;
}

// Draw textured polygon, defined by vertex and texture coordinates
// NOTE: Polygon center must have straight line path to all points
// without crossing perimeter, points must be in anticlockwise order
fn DrawTexturePoly(texture: ray.Texture2D, center: ray.Vector2, points: [*]ray.Vector2, texcoords: [*]ray.Vector2, pointCount: i32, tint: ray.Color) void
{
  ray.rlSetTexture(texture.id);

  // Texturing is only supported on RL_QUADS
  ray.rlBegin(ray.RL_QUADS);

    ray.rlColor4ub(tint.r, tint.g, tint.b, tint.a);

    for (0..@intCast(pointCount - 1)) |i| {
      ray.rlTexCoord2f(0.5, 0.5);
      ray.rlVertex2f(center.x, center.y);

      ray.rlTexCoord2f(texcoords[i].x, texcoords[i].y);
      ray.rlVertex2f(points[i].x + center.x, points[i].y + center.y);

      ray.rlTexCoord2f(texcoords[i + 1].x, texcoords[i + 1].y);
      ray.rlVertex2f(points[i + 1].x + center.x, points[i + 1].y + center.y);

      ray.rlTexCoord2f(texcoords[i + 1].x, texcoords[i + 1].y);
      ray.rlVertex2f(points[i + 1].x + center.x, points[i + 1].y + center.y);
    }

  ray.rlEnd();

  ray.rlSetTexture(0);
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