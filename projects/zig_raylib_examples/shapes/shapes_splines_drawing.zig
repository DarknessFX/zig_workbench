//!zig-autodoc-section: shapes_splines_drawing.Main
//! raylib_examples/shapes_splines_drawing.zig
//!   Example - splines drawing.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - splines drawing
// *
// *   Example originally created with raylib 5.0, last time updated with raylib 5.0
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2023 Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h");
  @cDefine("RAYGUI_IMPLEMENTATION","");
  @cInclude("raygui.h");
});

const MAX_SPLINE_POINTS = 32;

const ControlPoint = struct {
  start: ray.Vector2,
  end: ray.Vector2,
};

const SplineType = enum(c_int) {
  SPLINE_LINEAR = 0,      // Linear
  SPLINE_BASIS,           // B-Spline
  SPLINE_CATMULLROM,      // Catmull-Rom
  SPLINE_BEZIER,          // Cubic Bezier
};

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - splines drawing");

  var points = [_]ray.Vector2{
    ray.Vector2{ .x = 50.0, .y = 400.0 },
    ray.Vector2{ .x = 160.0, .y = 220.0 },
    ray.Vector2{ .x = 340.0, .y = 380.0 },
    ray.Vector2{ .x = 520.0, .y = 60.0 },
    ray.Vector2{ .x = 710.0, .y = 260.0 },
  } ++ [_]ray.Vector2{ray.Vector2{ .x = 0, .y = 0 }} ** (MAX_SPLINE_POINTS - 5);
  
  // Array required for spline bezier-cubic, 
  // including control points interleaved with start-end segment points
  var pointsInterleaved = [_]ray.Vector2{ray.Vector2{ .x = 0, .y = 0 }} ** (3*(MAX_SPLINE_POINTS - 1) + 1);
  
  var pointCount: i32 = 5;
  var selectedPoint: i32 = -1;
  var focusedPoint: i32 = -1;
  var selectedControlPoint: ?*ray.Vector2 = null;
  var focusedControlPoint: ?*ray.Vector2 = null;
  
  // Cubic Bezier control points initialization
  var control = [_]ControlPoint{ControlPoint{ .start = ray.Vector2{ .x = 0, .y = 0 }, .end = ray.Vector2{ .x = 0, .y = 0 }}} ** (MAX_SPLINE_POINTS - 1);
  for (0..@intCast(pointCount - 1)) |i| {
    control[i].start = ray.Vector2{ .x = points[i].x + 50, .y = points[i].y };
    control[i].end = ray.Vector2{ .x = points[i + 1].x - 50, .y = points[i + 1].y };
  }

  // Spline config variables
  var splineThickness: f32 = 8.0;
  var splineTypeActive: c_int = @intFromEnum(SplineType.SPLINE_LINEAR); // 0-Linear, 1-BSpline, 2-CatmullRom, 3-Bezier
  var splineTypeEditMode: bool = false; 
  var splineHelpersActive: bool = true;
  
  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // Spline points creation logic (at the end of spline)
    if (ray.IsMouseButtonPressed(ray.MOUSE_RIGHT_BUTTON) and (pointCount < MAX_SPLINE_POINTS)) {
      points[@intCast(pointCount)] = ray.GetMousePosition();
      const i: usize = @intCast(pointCount - 1);
      control[i].start = ray.Vector2{ .x = points[i].x + 50, .y = points[i].y };
      control[i].end = ray.Vector2{ .x = points[i + 1].x - 50, .y = points[i + 1].y };
      pointCount += 1;
    }

    // Spline point focus and selection logic
    for (0..@intCast(pointCount)) |i| {
      if (ray.CheckCollisionPointCircle(ray.GetMousePosition(), points[i], 8.0)) {
        focusedPoint = @intCast(i);
        if (ray.IsMouseButtonDown(ray.MOUSE_LEFT_BUTTON)) selectedPoint = @intCast(i); 
        break;
      }
      else focusedPoint = -1;
    }
    
    // Spline point movement logic
    if (selectedPoint >= 0) {
      points[@intCast(selectedPoint)] = ray.GetMousePosition();
      if (ray.IsMouseButtonReleased(ray.MOUSE_LEFT_BUTTON)) selectedPoint = -1;
    }
    
    // Cubic Bezier spline control points logic
    if (@as(SplineType, @enumFromInt(splineTypeActive)) == SplineType.SPLINE_BEZIER and (focusedPoint == -1)) {
      // Spline control point focus and selection logic
      for (0..@intCast(pointCount - 1)) |i| {
        if (ray.CheckCollisionPointCircle(ray.GetMousePosition(), control[i].start, 6.0)) {
          focusedControlPoint = &control[i].start;
          if (ray.IsMouseButtonDown(ray.MOUSE_LEFT_BUTTON)) selectedControlPoint = &control[i].start; 
          break;
        }
        else if (ray.CheckCollisionPointCircle(ray.GetMousePosition(), control[i].end, 6.0)) {
          focusedControlPoint = &control[i].end;
          if (ray.IsMouseButtonDown(ray.MOUSE_LEFT_BUTTON)) selectedControlPoint = &control[i].end; 
          break;
        }
        else focusedControlPoint = null;
      }
      
      // Spline control point movement logic
      if (selectedControlPoint != null) {
        selectedControlPoint.?.* = ray.GetMousePosition();
        if (ray.IsMouseButtonReleased(ray.MOUSE_LEFT_BUTTON)) selectedControlPoint = null;
      }
    }
    
    // Spline selection logic
    if (ray.IsKeyPressed(ray.KEY_ONE)) splineTypeActive = @intFromEnum(SplineType.SPLINE_LINEAR)
    else if (ray.IsKeyPressed(ray.KEY_TWO)) splineTypeActive = @intFromEnum(SplineType.SPLINE_BASIS)
    else if (ray.IsKeyPressed(ray.KEY_THREE)) splineTypeActive = @intFromEnum(SplineType.SPLINE_CATMULLROM)
    else if (ray.IsKeyPressed(ray.KEY_FOUR)) splineTypeActive = @intFromEnum(SplineType.SPLINE_BEZIER);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);
  
      if (@as(SplineType, @enumFromInt(splineTypeActive)) == SplineType.SPLINE_LINEAR) {
        // Draw spline: linear
        ray.DrawSplineLinear(&points, @intCast(pointCount), splineThickness, ray.RED);
      } else if (@as(SplineType, @enumFromInt(splineTypeActive)) == SplineType.SPLINE_BASIS) {
        // Draw spline: basis
        ray.DrawSplineBasis(&points, @intCast(pointCount), splineThickness, ray.RED);  // Provide connected points array

        // Note: Individual segment drawing is omitted here due to complexity and lack of implementation in raylib for Zig
      } else if (@as(SplineType, @enumFromInt(splineTypeActive)) == SplineType.SPLINE_CATMULLROM) {
        // Draw spline: catmull-rom
        ray.DrawSplineCatmullRom(&points, @intCast(pointCount), splineThickness, ray.RED); // Provide connected points array
        
        // Note: Individual segment drawing is omitted here due to complexity and lack of implementation in raylib for Zig
      } else if (@as(SplineType, @enumFromInt(splineTypeActive)) == SplineType.SPLINE_BEZIER) {
        // NOTE: Cubic-bezier spline requires the 2 control points of each segment to be 
        // provided interleaved with the start and end point of every segment
        for (0..@intCast(pointCount - 1)) |i| {
          pointsInterleaved[3*i] = points[i];
          pointsInterleaved[3*i + 1] = control[i].start;
          pointsInterleaved[3*i + 2] = control[i].end;
        }
        
        pointsInterleaved[@as(usize, @intCast(3*(pointCount - 1)))] = points[@intCast(pointCount - 1)];

        // Draw spline: cubic-bezier (with control points)
        ray.DrawSplineBezierCubic(&pointsInterleaved, @intCast(3*(pointCount - 1) + 1), splineThickness, ray.RED);
        
        // Note: Individual segment drawing is omitted here due to complexity and lack of implementation in raylib for Zig

        // Draw spline control points
        for (0..@intCast(pointCount - 1)) |i| {
          // Every cubic bezier point have two control points
          ray.DrawCircleV(control[i].start, 6, ray.GOLD);
          ray.DrawCircleV(control[i].end, 6, ray.GOLD);
          if (focusedControlPoint == &control[i].start) ray.DrawCircleV(control[i].start, 8, ray.GREEN)
          else if (focusedControlPoint == &control[i].end) ray.DrawCircleV(control[i].end, 8, ray.GREEN);
          ray.DrawLineEx(points[i], control[i].start, 1.0, ray.LIGHTGRAY);
          ray.DrawLineEx(points[i + 1], control[i].end, 1.0, ray.LIGHTGRAY);
      
          // Draw spline control lines
          ray.DrawLineV(points[i], control[i].start, ray.GRAY);
          ray.DrawLineV(control[i].end, points[i + 1], ray.GRAY);
        }
      }

      if (splineHelpersActive) {
        // Draw spline point helpers
        for (0..@intCast(pointCount)) |i| {
          ray.DrawCircleLinesV(points[i], if (focusedPoint == @as(i32, @intCast(i))) 12.0 else 8.0, if (focusedPoint == @as(usize, @intCast(i))) ray.BLUE else ray.DARKBLUE);
          if ((@as(SplineType, @enumFromInt(splineTypeActive)) != SplineType.SPLINE_LINEAR) and
            (@as(SplineType, @enumFromInt(splineTypeActive)) != SplineType.SPLINE_BEZIER) and
            (i < @as(usize, @intCast(pointCount - 1)))) ray.DrawLineV(points[i], points[i + 1], ray.GRAY);

          ray.DrawText(ray.TextFormat("[%.0f, %.0f]", points[i].x, points[i].y), 
            toInt(points[i].x), toInt(points[i].y) + 10, 10, ray.BLACK);
        }
      }

      // Check all possible UI states that require controls lock
      if (splineTypeEditMode) ray.GuiLock();
      
      // Draw spline config
      _ = ray.GuiLabel(ray.Rectangle{ .x = 12, .y = 62, .width = 140, .height = 24 }, ray.TextFormat("Spline thickness: %i", toInt(splineThickness)));
      _ = ray.GuiSliderBar(ray.Rectangle{ .x = 12, .y = 60 + 24, .width = 140, .height = 16 }, null, null, &splineThickness, 1.0, 40.0);

      _ = ray.GuiCheckBox(ray.Rectangle{ .x = 12, .y = 110, .width = 20, .height = 20 }, "Show point helpers", &splineHelpersActive);

      ray.GuiUnlock();

      _ = ray.GuiLabel(ray.Rectangle{ .x = 12, .y = 10, .width = 140, .height = 24 }, "Spline type:");
      if (ray.GuiDropdownBox(
        ray.Rectangle{ .x = 12, .y = 8 + 24, .width = 140, .height = 28 }, "LINEAR;BSPLINE;CATMULLROM;BEZIER", &splineTypeActive, splineTypeEditMode)
        != 0) splineTypeEditMode = !splineTypeEditMode;

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