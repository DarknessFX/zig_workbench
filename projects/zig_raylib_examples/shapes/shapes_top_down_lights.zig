//!zig-autodoc-section: shapes_top_down_lights.Main
//! raylib_examples/shapes_top_down_lights.zig
//!   Example - top down lights.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [shapes] example - top down lights
// *
// *   Example originally created with raylib 4.2, last time updated with raylib 4.2
// *
// *   Example contributed by Vlad Adrian (@demizdor) and reviewed by Ramon Santamaria (@raysan5)
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2022-2024 Jeffery Myers (@JeffM2501)
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

const RLGL_SRC_ALPHA = 0x0302;
const RLGL_MIN = 0x8007;
const RLGL_MAX = 0x8008;

const MAX_BOXES = 20;
const MAX_SHADOWS = MAX_BOXES * 3;         // MAX_BOXES *3. Each box can cast up to two shadow volumes for the edges it is away from, and one for the box itself
const MAX_LIGHTS = 16;

const ShadowGeometry = struct {
  vertices: [4]ray.Vector2,
};

const LightInfo = struct {
  active: bool = false,                // Is this light slot active?
  dirty: bool = false,                 // Does this light need to be updated?
  valid: bool = false,                 // Is this light in a valid position?

  position: ray.Vector2 = ray.Vector2{ .x = 0, .y = 0 },           // Light position
  mask: ray.RenderTexture = undefined,         // Alpha mask for the light
  outerRadius: f32 = 0,          // The distance the light touches
  bounds: ray.Rectangle = ray.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 },           // A cached rectangle of the light bounds to help with culling

  shadows: [MAX_SHADOWS]ShadowGeometry = undefined,
  shadowCount: i32 = 0,
};

var lights = [_]LightInfo{LightInfo{}} ** MAX_LIGHTS;

// Move a light and mark it as dirty so that we update it's mask next frame
fn MoveLight(slot: i32, x: f32, y: f32) void {
  lights[toUsize(slot)].dirty = true;
  lights[toUsize(slot)].position.x = x; 
  lights[toUsize(slot)].position.y = y;

  // update the cached bounds
  lights[toUsize(slot)].bounds.x = x - lights[toUsize(slot)].outerRadius;
  lights[toUsize(slot)].bounds.y = y - lights[toUsize(slot)].outerRadius;
}

// Compute a shadow volume for the edge
// It takes the edge and projects it back by the light radius and turns it into a quad
fn ComputeShadowVolumeForEdge(slot: i32, sp: ray.Vector2, ep: ray.Vector2) void {
  if (lights[toUsize(slot)].shadowCount >= MAX_SHADOWS) return;

  const extension = lights[toUsize(slot)].outerRadius * 2;

  const spVector = ray.Vector2Normalize(ray.Vector2Subtract(sp, lights[toUsize(slot)].position));
  const spProjection = ray.Vector2Add(sp, ray.Vector2Scale(spVector, extension));

  const epVector = ray.Vector2Normalize(ray.Vector2Subtract(ep, lights[toUsize(slot)].position));
  const epProjection = ray.Vector2Add(ep, ray.Vector2Scale(epVector, extension));

  lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[0] = sp;
  lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[1] = ep;
  lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[2] = epProjection;
  lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[3] = spProjection;

  lights[toUsize(slot)].shadowCount += 1;
}

// Draw the light and shadows to the mask for a light
fn DrawLightMask(slot: i32) void {
  // Use the light mask
  ray.BeginTextureMode(lights[toUsize(slot)].mask);

    ray.ClearBackground(ray.WHITE);

    // Force the blend mode to only set the alpha of the destination
    ray.rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MIN);
    ray.rlSetBlendMode(ray.BLEND_CUSTOM);

    // If we are valid, then draw the light radius to the alpha mask
    if (lights[toUsize(slot)].valid) ray.DrawCircleGradient(toInt(lights[toUsize(slot)].position.x), toInt(lights[toUsize(slot)].position.y), lights[toUsize(slot)].outerRadius, ray.ColorAlpha(ray.WHITE, 0), ray.WHITE);
    
    ray.rlDrawRenderBatchActive();

    // Cut out the shadows from the light radius by forcing the alpha to maximum
    ray.rlSetBlendMode(ray.BLEND_ALPHA);
    ray.rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MAX);
    ray.rlSetBlendMode(ray.BLEND_CUSTOM);

    // Draw the shadows to the alpha mask
    var i: i32 = 0;
    while (i < lights[toUsize(slot)].shadowCount) : (i += 1) {
      ray.DrawTriangleFan(&lights[toUsize(slot)].shadows[toUsize(i)].vertices, 4, ray.WHITE);
    }

    ray.rlDrawRenderBatchActive();
    
    // Go back to normal blend mode
    ray.rlSetBlendMode(ray.BLEND_ALPHA);

  ray.EndTextureMode();
}

// Setup a light
fn SetupLight(slot: i32, x: f32, y: f32, radius: f32) void {
  lights[toUsize(slot)].active = true;
  lights[toUsize(slot)].valid = false;  // The light must prove it is valid
  lights[toUsize(slot)].mask = ray.LoadRenderTexture(ray.GetScreenWidth(), ray.GetScreenHeight());
  lights[toUsize(slot)].outerRadius = radius;

  lights[toUsize(slot)].bounds.width = radius * 2;
  lights[toUsize(slot)].bounds.height = radius * 2;

  MoveLight(slot, x, y);

  // Force the render texture to have something in it
  DrawLightMask(slot);
}

// See if a light needs to update it's mask
fn UpdateLight(slot: i32, boxes: []ray.Rectangle, count: i32) bool {
  if (!lights[toUsize(slot)].active or !lights[toUsize(slot)].dirty) return false;

  lights[toUsize(slot)].dirty = false;
  lights[toUsize(slot)].shadowCount = 0;
  lights[toUsize(slot)].valid = false;

  var i: i32 = 0;
  while (i < count) : (i += 1) {
    // Are we in a box? if so we are not valid
    if (ray.CheckCollisionPointRec(lights[toUsize(slot)].position, boxes[toUsize(i)])) return false;

    // If this box is outside our bounds, we can skip it
    if (!ray.CheckCollisionRecs(lights[toUsize(slot)].bounds, boxes[toUsize(i)])) continue;

    // Check the edges that are on the same side we are, and cast shadow volumes out from them
    
    // Top
    var sp = ray.Vector2{ .x = boxes[toUsize(i)].x, .y = boxes[toUsize(i)].y };
    var ep = ray.Vector2{ .x = boxes[toUsize(i)].x + boxes[toUsize(i)].width, .y = boxes[toUsize(i)].y };

    if (lights[toUsize(slot)].position.y > ep.y) ComputeShadowVolumeForEdge(slot, sp, ep);

    // Right
    sp = ep;
    ep.y += boxes[toUsize(i)].height;
    if (lights[toUsize(slot)].position.x < ep.x) ComputeShadowVolumeForEdge(slot, sp, ep);

    // Bottom
    sp = ep;
    ep.x -= boxes[toUsize(i)].width;
    if (lights[toUsize(slot)].position.y < ep.y) ComputeShadowVolumeForEdge(slot, sp, ep);

    // Left
    sp = ep;
    ep.y -= boxes[toUsize(i)].height;
    if (lights[toUsize(slot)].position.x > ep.x) ComputeShadowVolumeForEdge(slot, sp, ep);

    // The box itself
    lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[0] = ray.Vector2{ .x = boxes[toUsize(i)].x, .y = boxes[toUsize(i)].y };
    lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[1] = ray.Vector2{ .x = boxes[toUsize(i)].x, .y = boxes[toUsize(i)].y + boxes[toUsize(i)].height };
    lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[2] = ray.Vector2{ .x = boxes[toUsize(i)].x + boxes[toUsize(i)].width, .y = boxes[toUsize(i)].y + boxes[toUsize(i)].height };
    lights[toUsize(slot)].shadows[toUsize(lights[toUsize(slot)].shadowCount)].vertices[3] = ray.Vector2{ .x = boxes[toUsize(i)].x + boxes[toUsize(i)].width, .y = boxes[toUsize(i)].y };
    lights[toUsize(slot)].shadowCount += 1;
  }

  lights[toUsize(slot)].valid = true;

  DrawLightMask(slot);

  return true;
}

// Set up some boxes
fn SetupBoxes(boxes: []ray.Rectangle, count: *i32) void {
  boxes[0] = ray.Rectangle{ .x = 150, .y = 80, .width = 40, .height = 40 };
  boxes[1] = ray.Rectangle{ .x = 1200, .y = 700, .width = 40, .height = 40 };
  boxes[2] = ray.Rectangle{ .x = 200, .y = 600, .width = 40, .height = 40 };
  boxes[3] = ray.Rectangle{ .x = 1000, .y = 50, .width = 40, .height = 40 };
  boxes[4] = ray.Rectangle{ .x = 500, .y = 350, .width = 40, .height = 40 };

  for (5..MAX_BOXES) |i| {
    boxes[i] = ray.Rectangle{ 
      .x = toFloat(ray.GetRandomValue(0, ray.GetScreenWidth())), 
      .y = toFloat(ray.GetRandomValue(0, ray.GetScreenHeight())), 
      .width = toFloat(ray.GetRandomValue(10, 100)), 
      .height = toFloat(ray.GetRandomValue(10, 100)) 
    };
  }

  count.* = MAX_BOXES;
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;
  
  ray.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - top down lights");

  // Initialize our 'world' of boxes
  var boxCount: i32 = 0;
  var boxes = [_]ray.Rectangle{ray.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 }} ** MAX_BOXES;
  SetupBoxes(&boxes, &boxCount);

  // Create a checkerboard ground texture
  const img = ray.GenImageChecked(64, 64, 32, 32, ray.DARKBROWN, ray.DARKGRAY);
  const backgroundTexture = ray.LoadTextureFromImage(img);
  ray.UnloadImage(img);

  // Create a global light mask to hold all the blended lights
  const lightMask = ray.LoadRenderTexture(ray.GetScreenWidth(), ray.GetScreenHeight());

  // Setup initial light
  SetupLight(0, 600, 400, 300);
  var nextLight: i32 = 1;

  var showLines = false;

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // Drag light 0
    if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) MoveLight(0, ray.GetMousePosition().x, ray.GetMousePosition().y);

    // Make a new light
    if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_RIGHT) and (nextLight < MAX_LIGHTS)) {
      SetupLight(nextLight, ray.GetMousePosition().x, ray.GetMousePosition().y, 200);
      nextLight += 1;
    }

    // Toggle debug info
    if (ray.IsKeyPressed(ray.KEY_F1)) showLines = !showLines;

    // Update the lights and keep track if any were dirty so we know if we need to update the master light mask
    var dirtyLights = false;
    for (0..MAX_LIGHTS) |i| {
      if (UpdateLight(@intCast(i), &boxes, boxCount)) dirtyLights = true;
    }

    // Update the light mask
    if (dirtyLights) {
      // Build up the light mask
      ray.BeginTextureMode(lightMask);
      
        ray.ClearBackground(ray.BLACK);

        // Force the blend mode to only set the alpha of the destination
        ray.rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MIN);
        ray.rlSetBlendMode(ray.BLEND_CUSTOM);

        // Merge in all the light masks
        for (0..MAX_LIGHTS) |i| {
          if (lights[i].active) ray.DrawTextureRec(lights[i].mask.texture, ray.Rectangle{ .x = 0, .y = 0, .width = toFloat(ray.GetScreenWidth()), .height = -toFloat(ray.GetScreenHeight()) }, ray.Vector2Zero(), ray.WHITE);
        }

        ray.rlDrawRenderBatchActive();

        // Go back to normal blend
        ray.rlSetBlendMode(ray.BLEND_ALPHA);
      ray.EndTextureMode();
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.BLACK);
      
      // Draw the tile background
      ray.DrawTextureRec(backgroundTexture, ray.Rectangle{ .x = 0, .y = 0, .width = toFloat(ray.GetScreenWidth()), .height = toFloat(ray.GetScreenHeight()) }, ray.Vector2Zero(), ray.WHITE);
      
      // Overlay the shadows from all the lights
      ray.DrawTextureRec(lightMask.texture, ray.Rectangle{ .x = 0, .y = 0, .width = toFloat(ray.GetScreenWidth()), .height = -toFloat(ray.GetScreenHeight()) }, ray.Vector2Zero(), ray.ColorAlpha(ray.WHITE, if (showLines) 0.75 else 1.0));

      // Draw the lights
      for (0..MAX_LIGHTS) |i| {
        if (lights[i].active) ray.DrawCircle(toInt(lights[i].position.x), toInt(lights[i].position.y), 10, if (i == 0) ray.YELLOW else ray.WHITE);
      }

      if (showLines) {
        for (0..toUsize(lights[0].shadowCount)) |s| {
          ray.DrawTriangleFan(&lights[0].shadows[s].vertices, 4, ray.DARKPURPLE);
        }

        for (0..toUsize(boxCount)) |b| {
          if (ray.CheckCollisionRecs(boxes[b], lights[0].bounds)) ray.DrawRectangleRec(boxes[b], ray.PURPLE);

          ray.DrawRectangleLines(toInt(boxes[b].x), toInt(boxes[b].y), toInt(boxes[b].width), toInt(boxes[b].height), ray.DARKBLUE);
        }

        ray.DrawText("(F1) Hide Shadow Volumes", 10, 50, 10, ray.GREEN);
      }
      else {
        ray.DrawText("(F1) Show Shadow Volumes", 10, 50, 10, ray.GREEN);
      }

      ray.DrawFPS(screenWidth - 80, 10);
      ray.DrawText("Drag to move light #1", 10, 10, 10, ray.DARKGREEN);
      ray.DrawText("Right click to add new light", 10, 30, 10, ray.DARKGREEN);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadTexture(backgroundTexture);
  ray.UnloadRenderTexture(lightMask);
  for (0..MAX_LIGHTS) |i| {
    if (lights[i].active) ray.UnloadRenderTexture(lights[i].mask);
  }

  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toUsize(value: i32) usize { return @as(usize, @intCast(value));}
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