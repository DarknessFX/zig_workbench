//!zig-autodoc-section: textures_bunnymark.Main
//! raylib_examples/textures_bunnymark.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Bunnymark
// *
// *   Example originally created with raylib 1.6, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2014-2024 Ramon Santamaria (@raysan5)
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
  const MAX_BUNNIES: c_int = 50000;    // 50K bunnies limit
  const MAX_BATCH_ELEMENTS: c_int = 8192; // This is the maximum amount of elements (quads) per batch

  const Bunny = struct {
    position: ray.Vector2,
    speed: ray.Vector2,
    color: ray.Color,
  };

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - bunnymark");

  // Load bunny texture
  const texBunny = ray.LoadTexture(getPath("textures", "resources/wabbit_alpha.png"));

  var bunnies: [*]Bunny = @alignCast(@ptrCast(std.c.malloc(@sizeOf(Bunny) * MAX_BUNNIES)));    // Bunnies array

  var bunniesCount: usize = 0;           // Bunnies counter

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) {
      // Create more bunnies
      for (0..100) |_| {
        if (bunniesCount < MAX_BUNNIES) {
          const mousePos = ray.GetMousePosition();
          bunnies[bunniesCount].position = mousePos;
          bunnies[bunniesCount].speed.x = toFloatC(ray.GetRandomValue(-250, 250)) / 60.0;
          bunnies[bunniesCount].speed.y = toFloatC(ray.GetRandomValue(-250, 250)) / 60.0;
          bunnies[bunniesCount].color = ray.Color{
            .r = @intCast(ray.GetRandomValue(50, 240)),
            .g = @intCast(ray.GetRandomValue(80, 240)),
            .b = @intCast(ray.GetRandomValue(100, 240)),
            .a = 255,
          };
          bunniesCount += 1;
        }
      }
    }

    // Update bunnies
    for (0..bunniesCount) |i| {
      bunnies[i].position.x += bunnies[i].speed.x;
      bunnies[i].position.y += bunnies[i].speed.y;

      if ((bunnies[i].position.x + toFloatC(texBunny.width) / 2.0) > toFloatC(screenWidth) or
          (bunnies[i].position.x + toFloatC(texBunny.width) / 2.0) < 0) bunnies[i].speed.x *= -1;
      if ((bunnies[i].position.y + toFloatC(texBunny.height) / 2.0) > toFloatC(screenHeight) or
          (bunnies[i].position.y + toFloatC(texBunny.height) / 2.0 - 40.0) < 0) bunnies[i].speed.y *= -1;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      for (0..bunniesCount) |i| {
        // NOTE: When internal batch buffer limit is reached (MAX_BATCH_ELEMENTS),
        // a draw call is launched and buffer starts being filled again;
        // before issuing a draw call, updated vertex data from internal CPU buffer is send to GPU...
        // Process of sending data is costly and it could happen that GPU data has not been completely
        // processed for drawing while new data is tried to be sent (updating current in-use buffers)
        // it could generates a stall and consequently a frame drop, limiting the number of drawn bunnies
        ray.DrawTexture(texBunny, toInt(bunnies[i].position.x), toInt(bunnies[i].position.y), bunnies[i].color);
      }

      ray.DrawRectangle(0, 0, screenWidth, 40, ray.BLACK);
      ray.DrawText(ray.TextFormat("bunnies: %i", bunniesCount), 120, 10, 20, ray.GREEN);
      ray.DrawText(ray.TextFormat("batched draw calls: %i", 1 + @divTrunc(bunniesCount, MAX_BATCH_ELEMENTS)), 320, 10, 20, ray.MAROON);

      ray.DrawFPS(10, 10);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  std.c.free(bunnies);              // Unload bunnies data array
  ray.UnloadTexture(texBunny);    // Unload bunny texture

  ray.CloseWindow();              // Close window and OpenGL context
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