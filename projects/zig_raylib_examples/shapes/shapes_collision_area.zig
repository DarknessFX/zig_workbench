//!zig-autodoc-section: shapes_collision_area.Main
//! raylib_examples/shapes_collision_area.zig
//!   Example - collision area.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - collision area
// *
// *   Example originally created with raylib 2.5, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
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
  //---------------------------------------------------------
  var screenWidth: f32 = 800.0;
  var screenHeight: f32 = 450.0;

  ray.InitWindow(@intFromFloat(screenWidth), @intFromFloat(screenHeight), "raylib [shapes] example - collision area");

  // Box A: Moving box
  var boxA = ray.Rectangle{ .x = 10, .y = screenHeight / 2.0 - 50, .width = 200, .height = 100 };
  var boxASpeedX: f32 = 4.0;

  // Box B: Mouse moved box
  var boxB = ray.Rectangle{ .x = screenWidth / 2.0 - 30, .y = screenHeight / 2.0 - 30, .width = 60, .height = 60 };

  var boxCollision = ray.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 }; // Collision rectangle

  const screenUpperLimit = 40;      // Top menu limits

  var pause = false;             // Movement pause
  var collision = false;         // Collision detection

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //----------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //-----------------------------------------------------
    screenWidth = @floatFromInt(ray.GetScreenWidth());
    screenHeight = @floatFromInt(ray.GetScreenHeight());

    // Move box if not paused
    if (!pause) boxA.x += boxASpeedX;

    // Bounce box on x screen limits
    if ((boxA.x + boxA.width >= screenWidth) or (boxA.x <= 0)) boxASpeedX *= -1;

    // Update player-controlled-box (box02)
    boxB.x = @as(f32, @floatFromInt(ray.GetMouseX())) - boxB.width / 2.0;
    boxB.y = @as(f32, @floatFromInt(ray.GetMouseY())) - boxB.height / 2.0;

    // Make sure Box B does not go out of move area limits
    if (boxB.x + boxB.width >= screenWidth) boxB.x = screenWidth - boxB.width
    else if (boxB.x <= 0) boxB.x = 0;

    if (boxB.y + boxB.height >= screenHeight) boxB.y = screenHeight - boxB.height
    else if (boxB.y <=  @as(f32, @floatFromInt(screenUpperLimit))) boxB.y =  @as(f32, @floatFromInt(screenUpperLimit));

    // Check boxes collision
    collision = ray.CheckCollisionRecs(boxA, boxB);

    // Get collision rectangle (only on collision)
    if (collision) boxCollision = ray.GetCollisionRec(boxA, boxB);

    // Pause Box A movement
    if (ray.IsKeyPressed(ray.KEY_SPACE)) pause = !pause;
    //-----------------------------------------------------

    // Draw
    //-----------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawRectangle(0, 0, @intFromFloat(screenWidth), screenUpperLimit, if (collision) ray.RED else ray.BLACK);

      ray.DrawRectangleRec(boxA, ray.GOLD);
      ray.DrawRectangleRec(boxB, ray.BLUE);

      if (collision) {
        // Draw collision area
        ray.DrawRectangleRec(boxCollision, ray.LIME);

        // Draw collision message
        ray.DrawText("COLLISION!", @divTrunc(ray.GetScreenWidth(), 2) - @divTrunc(ray.MeasureText("COLLISION!", 20), 2), @divTrunc(screenUpperLimit, 2) - 10, 20, ray.BLACK);

        // Draw collision area
        ray.DrawText(ray.TextFormat("Collision Area: %i", 
          boxCollision.width * boxCollision.height), 
          @intFromFloat(@divTrunc(screenWidth, 2.0) - 100.0), screenUpperLimit + 10, 20, ray.BLACK);
      }

      // Draw help instructions
      ray.DrawText("Press SPACE to PAUSE/RESUME", 20, @intFromFloat(screenHeight - 35.0), 20, ray.LIGHTGRAY);

      ray.DrawFPS(10, 10);

    ray.EndDrawing();
    //-----------------------------------------------------
  }

  // De-Initialization
  //---------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //----------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
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