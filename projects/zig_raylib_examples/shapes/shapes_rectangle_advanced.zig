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
  @cInclude("rlgl.h");
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;
  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - rectangle avanced");
  ray.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {     // Detect window close button or ESC key
    // Update rectangle bounds
    //----------------------------------------------------------------------------------
    const getScreenWidth: f32 = toFloat(ray.GetScreenWidth());
    const getScreenHeight: f32 = toFloat(ray.GetScreenHeight());

    const width = getScreenWidth / 2.0;
    const height = getScreenHeight / 6.0;
    var rec = ray.Rectangle{
      .x = getScreenWidth / 2.0 - width / 2.0,
      .y = getScreenHeight / 2.0 - (5.0) * (height / 2.0),
      .width = width,
      .height = height
    };
    //--------------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();
      ray.ClearBackground(ray.RAYWHITE);

      // Draw All Rectangles with different roundess  for each side and different gradients
      DrawRectangleRoundedGradientH(rec, 0.8, 0.8, 36, ray.BLUE, ray.RED);

      rec.y += rec.height + 1.0;
      DrawRectangleRoundedGradientH(rec, 0.5, 1.0, 36, ray.RED, ray.PINK);

      rec.y += rec.height + 1.0;
      DrawRectangleRoundedGradientH(rec, 1.0, 0.5, 36, ray.RED, ray.BLUE);

      rec.y += rec.height + 1.0;
      DrawRectangleRoundedGradientH(rec, 0.0, 1.0, 36, ray.BLUE, ray.BLACK);

      rec.y += rec.height + 1.0;
      DrawRectangleRoundedGradientH(rec, 1.0, 0.0, 36, ray.BLUE, ray.PINK);
    ray.EndDrawing();
    //--------------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

pub fn DrawRectangleRoundedGradientH(rec: ray.Rectangle, roundnessLeft: f32, roundnessRight: f32, segments: i32, left: ray.Color, right: ray.Color) void {
  // Neither side is rounded
  if ((roundnessLeft <= 0.0 and roundnessRight <= 0.0) or (rec.width < 1.0) or (rec.height < 1.0)) {
    ray.DrawRectangleGradientEx(rec, left, left, right, right);
    return;
  }

  const adjustedRoundnessLeft = if (roundnessLeft >= 1.0) 1.0 else roundnessLeft;
  const adjustedRoundnessRight = if (roundnessRight >= 1.0) 1.0 else roundnessRight;

  // Calculate corner radius both from right and left
  const recSize = if (rec.width > rec.height) rec.height else rec.width;
  var radiusLeft = (recSize * adjustedRoundnessLeft) / 2.0;
  var radiusRight = (recSize * adjustedRoundnessRight) / 2.0;

  if (radiusLeft <= 0.0) radiusLeft = 0.0;
  if (radiusRight <= 0.0) radiusRight = 0.0;

  if (radiusRight <= 0.0 and radiusLeft <= 0.0) return;

  const stepLength: f32 = 90.0 / toFloat(segments);

  const point = [_]ray.Vector2{
    // P0, P1, P2
    ray.Vector2{ .x = rec.x + radiusLeft, .y = rec.y }, 
    ray.Vector2{ .x = rec.x + rec.width - radiusRight, .y = rec.y }, 
    ray.Vector2{ .x = rec.x + rec.width, .y = rec.y + radiusRight },
    // P3, P4
    ray.Vector2{ .x = rec.x + rec.width, .y = rec.y + rec.height - radiusRight }, 
    ray.Vector2{ .x = rec.x + rec.width - radiusRight, .y = rec.y + rec.height },
    // P5, P6, P7
    ray.Vector2{ .x = rec.x + radiusLeft, .y = rec.y + rec.height }, 
    ray.Vector2{ .x = rec.x, .y = rec.y + rec.height - radiusLeft }, 
    ray.Vector2{ .x = rec.x, .y = rec.y + radiusLeft },
    // P8, P9
    ray.Vector2{ .x = rec.x + radiusLeft, .y = rec.y + radiusLeft }, 
    ray.Vector2{ .x = rec.x + rec.width - radiusRight, .y = rec.y + radiusRight },
    // P10, P11
    ray.Vector2{ .x = rec.x + rec.width - radiusRight, .y = rec.y + rec.height - radiusRight }, 
    ray.Vector2{ .x = rec.x + radiusLeft, .y = rec.y + rec.height - radiusLeft }
  };

  const centers = [_]ray.Vector2{ point[8], point[9], point[10], point[11] };
  const angles = [_]f32{ 180.0, 270.0, 0.0, 90.0 };

  const RL_TRIANGLES = 4; // Assuming this is how it's defined in raylib for triangles
  ray.rlBegin(RL_TRIANGLES);

    // Draw all of the 4 corners: [1] Upper Left Corner, [3] Upper Right Corner, [5] Lower Right Corner, [7] Lower Left Corner
    for (0..4) |k| {
      var color: ray.Color = undefined;
      var radius: f32 = undefined;
      if (k == 0) {
        color = left;
        radius = radiusLeft;     // [1] Upper Left Corner
      } else if (k == 1) {
        color = right;
        radius = radiusRight;    // [3] Upper Right Corner
      } else if (k == 2) {
        color = right;
        radius = radiusRight;    // [5] Lower Right Corner
      } else if (k == 3) {
        color = left;
        radius = radiusLeft;     // [7] Lower Left Corner
      }
      var angle = angles[k];
      const center = centers[k];

      var i: i32 = 0;
      while (i < segments) : (i += 1) {
        ray.rlColor4ub(color.r, color.g, color.b, color.a);
        ray.rlVertex2f(center.x, center.y);
        ray.rlVertex2f(center.x + @cos(@as(f32, @floatCast(ray.DEG2RAD * (angle + stepLength)))) * radius, center.y + @sin(@as(f32, @floatCast(ray.DEG2RAD * (angle + stepLength)))) * radius);
        ray.rlVertex2f(center.x + @cos(@as(f32, @floatCast(ray.DEG2RAD * angle))) * radius, center.y + @sin(@as(f32, @floatCast(ray.DEG2RAD * angle))) * radius);
        angle += stepLength;
      }
    }

    // [2] Upper Rectangle
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[0].x, point[0].y);
    ray.rlVertex2f(point[8].x, point[8].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[9].x, point[9].y);
    ray.rlVertex2f(point[1].x, point[1].y);
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[0].x, point[0].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[9].x, point[9].y);

    // [4] Right Rectangle
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[9].x, point[9].y);
    ray.rlVertex2f(point[10].x, point[10].y);
    ray.rlVertex2f(point[3].x, point[3].y);
    ray.rlVertex2f(point[2].x, point[2].y);
    ray.rlVertex2f(point[9].x, point[9].y);
    ray.rlVertex2f(point[3].x, point[3].y);

    // [6] Bottom Rectangle
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[11].x, point[11].y);
    ray.rlVertex2f(point[5].x, point[5].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[4].x, point[4].y);
    ray.rlVertex2f(point[10].x, point[10].y);
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[11].x, point[11].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[4].x, point[4].y);

    // [8] Left Rectangle
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[7].x, point[7].y);
    ray.rlVertex2f(point[6].x, point[6].y);
    ray.rlVertex2f(point[11].x, point[11].y);
    ray.rlVertex2f(point[8].x, point[8].y);
    ray.rlVertex2f(point[7].x, point[7].y);
    ray.rlVertex2f(point[11].x, point[11].y);

    // [9] Middle Rectangle
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[8].x, point[8].y);
    ray.rlVertex2f(point[11].x, point[11].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[10].x, point[10].y);
    ray.rlVertex2f(point[9].x, point[9].y);
    ray.rlColor4ub(left.r, left.g, left.b, left.a);
    ray.rlVertex2f(point[8].x, point[8].y);
    ray.rlColor4ub(right.r, right.g, right.b, right.a);
    ray.rlVertex2f(point[10].x, point[10].y);

  ray.rlEnd();
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