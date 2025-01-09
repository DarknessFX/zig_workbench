//!zig-autodoc-section: core_automation_events.Main
//! raylib_examples/core_automation_events.zig
//!   Example - automation events.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX


const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h");
  @cInclude("reasings.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
const RECS_WIDTH: c_int = 50;
const RECS_HEIGHT: c_int = 50;

const MAX_RECS_X: c_int = 800 / RECS_WIDTH;
const MAX_RECS_Y: c_int = 450 / RECS_HEIGHT;

const PLAY_TIME_IN_FRAMES: c_int = 240;                 // At 60 fps = 4 seconds

pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - easings rectangle array");

  var recs = [_]ray.Rectangle{ray.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 }} ** (MAX_RECS_X * MAX_RECS_Y);

  for (0..MAX_RECS_Y) |y| {
    for (0..MAX_RECS_X) |x| {
      recs[y * MAX_RECS_X + x].x = toFloat(RECS_WIDTH) / 2.0 + toFloat(RECS_WIDTH) * toFloat(@intCast(x));
      recs[y * MAX_RECS_X + x].y = toFloat(RECS_HEIGHT) / 2.0 + toFloat(RECS_HEIGHT) * toFloat(@intCast(y));
      recs[y * MAX_RECS_X + x].width = toFloat(RECS_WIDTH);
      recs[y * MAX_RECS_X + x].height = toFloat(RECS_HEIGHT);
    }
  }

  var rotation: f32 = 0.0;
  var framesCounter: f32 = 0.0;
  var state: c_int = 0;                  // Rectangles animation state: 0-Playing, 1-Finished

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (state == 0) {
      framesCounter += 1;

      for (0..(MAX_RECS_X * MAX_RECS_Y)) |i| {
        recs[i].height = ray.EaseCircOut(framesCounter, toFloat(RECS_HEIGHT), -toFloat(RECS_HEIGHT), toFloat(PLAY_TIME_IN_FRAMES));
        recs[i].width = ray.EaseCircOut(framesCounter, toFloat(RECS_WIDTH), -toFloat(RECS_WIDTH), toFloat(PLAY_TIME_IN_FRAMES));

        if (recs[i].height < 0) recs[i].height = 0;
        if (recs[i].width < 0) recs[i].width = 0;

        if ((recs[i].height == 0) and (recs[i].width == 0)) state = 1;   // Finish playing

        rotation = ray.EaseLinearIn(framesCounter, 0.0, 360.0, toFloat(PLAY_TIME_IN_FRAMES));
      }
    } else if ((state == 1) and ray.IsKeyPressed(ray.KEY_SPACE)) {
      // When animation has finished, press space to restart
      framesCounter = 0;

      for (0..(MAX_RECS_X * MAX_RECS_Y)) |i| {
        recs[i].height = toFloat(RECS_HEIGHT);
        recs[i].width = toFloat(RECS_WIDTH);
      }

      state = 0;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      if (state == 0) {
        for (0..(MAX_RECS_X * MAX_RECS_Y)) |i| {
          ray.DrawRectanglePro(recs[i], ray.Vector2{ .x = recs[i].width / 2.0, .y = recs[i].height / 2.0 }, rotation, ray.RED);
        }
      } else if (state == 1) ray.DrawText("PRESS [SPACE] TO PLAY AGAIN!", 240, 200, 20, ray.GRAY);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

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