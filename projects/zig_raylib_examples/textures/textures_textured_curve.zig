//!zig-autodoc-section: textures_textured_curve.Main
//! raylib_examples/textures_textured_curve.zig
//!   Example - Draw a texture along a segmented curve.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Draw a texture along a segmented curve
// *
// *   Example originally created with raylib 4.5, last time updated with raylib 4.5
// *
// *   Example contributed by Jeffery Myers and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2022-2024 Jeffery Myers and Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
  @cInclude("raymath.h"); 
  @cInclude("rlgl.h"); 
});

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  texRoad = ray.Texture2D{};

  var showCurve = false;

  curveWidth = 50;
  curveSegments = 24;

  curveStartPosition = ray.Vector2{ .x = 0, .y = 0 };
  curveStartPositionTangent = ray.Vector2{ .x = 0, .y = 0 };

  curveEndPosition = ray.Vector2{ .x = 0, .y = 0 };
  curveEndPositionTangent = ray.Vector2{ .x = 0, .y = 0 };

  var curveSelectedPoint: ?*ray.Vector2 = null;

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;

  ray.SetConfigFlags(ray.FLAG_VSYNC_HINT | ray.FLAG_MSAA_4X_HINT);
  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] examples - textured curve");

  // Load the road texture
  texRoad = ray.LoadTexture(getPath("textures", "resources/road.png"));
  ray.SetTextureFilter(texRoad, ray.TEXTURE_FILTER_BILINEAR);

  // Setup the curve
  curveStartPosition = ray.Vector2{ .x = 80, .y = 100 };
  curveStartPositionTangent = ray.Vector2{ .x = 100, .y = 300 };

  curveEndPosition = ray.Vector2{ .x = 700, .y = 350 };
  curveEndPositionTangent = ray.Vector2{ .x = 600, .y = 100 };

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // Curve config options
    if (ray.IsKeyPressed(ray.KEY_SPACE)) showCurve = !showCurve;
    if (ray.IsKeyPressed(ray.KEY_EQUAL)) curveWidth += 2;
    if (ray.IsKeyPressed(ray.KEY_MINUS)) curveWidth -= 2;
    if (curveWidth < 2) curveWidth = 2;

    // Update segments
    if (ray.IsKeyPressed(ray.KEY_LEFT)) curveSegments -= 2;
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) curveSegments += 2;

    if (curveSegments < 2) curveSegments = 2;

    // Update curve logic
    // If the mouse is not down, we are not editing the curve so clear the selection
    if (!ray.IsMouseButtonDown(ray.MOUSE_LEFT_BUTTON))  curveSelectedPoint = null;

    // If a point was selected, move it
    if (curveSelectedPoint) |cv| cv.* = ray.Vector2Add(curveSelectedPoint.?.*, ray.GetMouseDelta());

    // The mouse is down, and nothing was selected, so see if anything was picked
    const mouse = ray.GetMousePosition();
    if (ray.CheckCollisionPointCircle(mouse, curveStartPosition, 6)) curveSelectedPoint = &curveStartPosition
    else if (ray.CheckCollisionPointCircle(mouse, curveStartPositionTangent, 6)) curveSelectedPoint = &curveStartPositionTangent
    else if (ray.CheckCollisionPointCircle(mouse, curveEndPosition, 6)) curveSelectedPoint = &curveEndPosition
    else if (ray.CheckCollisionPointCircle(mouse, curveEndPositionTangent, 6)) curveSelectedPoint = &curveEndPositionTangent;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      DrawTexturedCurve();    // Note: This function is not defined in raylib, you would need to implement this
      // For now, we'll comment this out since we don't have the function
      
      // Draw spline for reference
      if (showCurve) ray.DrawSplineSegmentBezierCubic(curveStartPosition, curveEndPosition, curveStartPositionTangent, curveEndPositionTangent, 2, ray.BLUE);

      // Draw the various control points and highlight where the mouse is
      ray.DrawLineV(curveStartPosition, curveStartPositionTangent, ray.SKYBLUE);
      ray.DrawLineV(curveStartPositionTangent, curveEndPositionTangent, ray.Fade(ray.LIGHTGRAY, 0.4));
      ray.DrawLineV(curveEndPosition, curveEndPositionTangent, ray.PURPLE);
      
      if (ray.CheckCollisionPointCircle(mouse, curveStartPosition, 6)) ray.DrawCircleV(curveStartPosition, 7, ray.YELLOW);
      ray.DrawCircleV(curveStartPosition, 5, ray.RED);

      if (ray.CheckCollisionPointCircle(mouse, curveStartPositionTangent, 6)) ray.DrawCircleV(curveStartPositionTangent, 7, ray.YELLOW);
      ray.DrawCircleV(curveStartPositionTangent, 5, ray.MAROON);

      if (ray.CheckCollisionPointCircle(mouse, curveEndPosition, 6)) ray.DrawCircleV(curveEndPosition, 7, ray.YELLOW);
      ray.DrawCircleV(curveEndPosition, 5, ray.GREEN);

      if (ray.CheckCollisionPointCircle(mouse, curveEndPositionTangent, 6)) ray.DrawCircleV(curveEndPositionTangent, 7, ray.YELLOW);
      ray.DrawCircleV(curveEndPositionTangent, 5, ray.DARKGREEN);

      // Draw usage info
      ray.DrawText("Drag points to move curve, press SPACE to show/hide base curve", 10, 10, 10, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("Curve width: %2.0f (Use + and - to adjust)", curveWidth), 10, 30, 10, ray.DARKGRAY);
      ray.DrawText(ray.TextFormat("Curve segments: %d (Use LEFT and RIGHT to adjust)", curveSegments), 10, 50, 10, ray.DARKGRAY);
      
    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(texRoad);
      
  ray.CloseWindow();              // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
  return 0;
}

// These variables should be defined globally or passed as parameters
var curveWidth: f32 = 0.0;
var curveSegments: i32 = 0.0;
var curveStartPosition: ray.Vector2 = undefined;
var curveStartPositionTangent: ray.Vector2 = undefined;
var curveEndPosition: ray.Vector2 = undefined;
var curveEndPositionTangent: ray.Vector2 = undefined;
var texRoad: ray.Texture2D = undefined;

// Draw textured curve using Spline Cubic Bezier
fn DrawTexturedCurve() void
{
  const step = 1.0 / toFloat(curveSegments);

  var previous = curveStartPosition;
  var previousTangent = ray.Vector2{ .x = 0, .y = 0 };
  var previousV: f32 = 0;

  // We can't compute a tangent for the first point, so we need to reuse the tangent from the first segment
  var tangentSet = false;

  var current = ray.Vector2{ .x = 0, .y = 0 };
  var t: f32 = 0.0;

  for (1..@intCast(curveSegments)) |i| {
    t = step * toFloat(@intCast(i));

    const a = std.math.pow(f32, 1.0 - t, 3);
    const b = 3.0 * std.math.pow(f32, 1.0 - t, 2) * t;
    const c = 3.0 * (1.0 - t) * std.math.pow(f32, t, 2);
    const d = std.math.pow(f32, t, 3);

    // Compute the endpoint for this segment
    current.y = a * curveStartPosition.y + b * curveStartPositionTangent.y + c * curveEndPositionTangent.y + d * curveEndPosition.y;
    current.x = a * curveStartPosition.x + b * curveStartPositionTangent.x + c * curveEndPositionTangent.x + d * curveEndPosition.x;

    // Vector from previous to current
    const delta = ray.Vector2{ .x = current.x - previous.x, .y = current.y - previous.y };

    // The right hand normal to the delta vector
    const normal = ray.Vector2Normalize(ray.Vector2{ .x = -delta.y, .y = delta.x });

    // The v texture coordinate of the segment (add up the length of all the segments so far)
    const v = previousV + ray.Vector2Length(delta);

    // Make sure the start point has a normal
    if (!tangentSet)
    {
      previousTangent = normal;
      tangentSet = true;
    }

    // Extend out the normals from the previous and current points to get the quad for this segment
    const prevPosNormal = ray.Vector2Add(previous, ray.Vector2Scale(previousTangent, curveWidth));
    const prevNegNormal = ray.Vector2Add(previous, ray.Vector2Scale(previousTangent, -curveWidth));

    const currentPosNormal = ray.Vector2Add(current, ray.Vector2Scale(normal, curveWidth));
    const currentNegNormal = ray.Vector2Add(current, ray.Vector2Scale(normal, -curveWidth));

    // Draw the segment as a quad
    ray.rlSetTexture(texRoad.id);
    ray.rlBegin(ray.RL_QUADS);
      ray.rlColor4ub(255, 255, 255, 255);
      ray.rlNormal3f(0.0, 0.0, 1.0);

      ray.rlTexCoord2f(0, previousV);
      ray.rlVertex2f(prevNegNormal.x, prevNegNormal.y);

      ray.rlTexCoord2f(1, previousV);
      ray.rlVertex2f(prevPosNormal.x, prevPosNormal.y);

      ray.rlTexCoord2f(1, v);
      ray.rlVertex2f(currentPosNormal.x, currentPosNormal.y);

      ray.rlTexCoord2f(0, v);
      ray.rlVertex2f(currentNegNormal.x, currentNegNormal.y);
    ray.rlEnd();

    // The current step is the start of the next step
    previous = current;
    previousTangent = normal;
    previousV = v;
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