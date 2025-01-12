//!zig-autodoc-section: textures_particles_blending.Main
//! raylib_examples/textures_particles_blending.zig
//!   Example - particles blending.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib example - particles blending
// *
// *   Example originally created with raylib 1.7, last time updated with raylib 3.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2017-2024 Ramon Santamaria (@raysan5)
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
  const MAX_PARTICLES: c_int = 200;

  // Particle structure with basic data
  const Particle = struct {
    position: ray.Vector2,
    color: ray.Color,
    alpha: f32,
    size: f32,
    rotation: f32,
    active: bool,        // NOTE: Use it to activate/deactive particle
  };

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - particles blending");

  // Particles pool, reuse them!
  var mouseTail: [MAX_PARTICLES]Particle = undefined;

  // Initialize particles
  for (0..MAX_PARTICLES) |i|
  {
    mouseTail[i].position = ray.Vector2{ .x = 0, .y = 0 };
    mouseTail[i].color = ray.Color{ 
      .r = @intCast(ray.GetRandomValue(0, 255)), 
      .g = @intCast(ray.GetRandomValue(0, 255)), 
      .b = @intCast(ray.GetRandomValue(0, 255)), 
      .a = 255 
    };
    mouseTail[i].alpha = 1.0;
    mouseTail[i].size = toFloatC(ray.GetRandomValue(1, 30)) / 20.0;
    mouseTail[i].rotation = toFloatC(ray.GetRandomValue(0, 360));
    mouseTail[i].active = false;
  }

  const gravity: f32 = 3.0;
  const smoke = ray.LoadTexture(getPath("textures", "resources/spark_flame.png"));

  var blending: i32 = ray.BLEND_ALPHA;

  ray.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------

    // Activate one particle every frame and Update active particles
    // NOTE: Particles initial position should be mouse position when activated
    // NOTE: Particles fall down with gravity and rotation... and disappear after 2 seconds (alpha = 0)
    // NOTE: When a particle disappears, active = false and it can be reused.
    for (0..MAX_PARTICLES) |i| {
      if (!mouseTail[i].active)
      {
        mouseTail[i].active = true;
        mouseTail[i].alpha = 1.0;
        mouseTail[i].position = ray.GetMousePosition();
        break;
      }
    }

    for (0..MAX_PARTICLES) |i| {
      if (mouseTail[i].active)
      {
        mouseTail[i].position.y += gravity / 2.0;
        mouseTail[i].alpha -= 0.005;

        if (mouseTail[i].alpha <= 0.0) mouseTail[i].active = false;

        mouseTail[i].rotation += 2.0;
      }
    }

    if (ray.IsKeyPressed(ray.KEY_SPACE)) {
      if (blending == ray.BLEND_ALPHA) blending = ray.BLEND_ADDITIVE
      else blending = ray.BLEND_ALPHA;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.DARKGRAY);

      ray.BeginBlendMode(blending);

        // Draw active particles
        for (0..MAX_PARTICLES) |i| {
          if (mouseTail[i].active) {
            ray.DrawTexturePro(smoke, ray.Rectangle{ .x = 0.0, .y = 0.0, .width = toFloatC(smoke.width), .height = toFloatC(smoke.height) },
              ray.Rectangle{ .x = mouseTail[i].position.x, .y = mouseTail[i].position.y, .width = toFloatC(smoke.width) * mouseTail[i].size, .height = toFloatC(smoke.height) * mouseTail[i].size },
              ray.Vector2{ .x = (toFloatC(smoke.width) * mouseTail[i].size)/2.0, .y = (toFloatC(smoke.height) * mouseTail[i].size)/2.0 }, mouseTail[i].rotation,
              ray.Fade(mouseTail[i].color, mouseTail[i].alpha));
          }
        }

      ray.EndBlendMode();

      ray.DrawText("PRESS SPACE to CHANGE BLENDING MODE", 180, 20, 20, ray.BLACK);

      if (blending == ray.BLEND_ALPHA) ray.DrawText("ALPHA BLENDING", 290, screenHeight - 40, 20, ray.BLACK)
      else ray.DrawText("ADDITIVE BLENDING", 280, screenHeight - 40, 20, ray.RAYWHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(smoke);

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