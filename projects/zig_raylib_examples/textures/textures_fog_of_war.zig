//!zig-autodoc-section: textures_fog_of_war.Main
//! raylib_examples/textures_fog_of_war.zig
//!   Example - Fog of war.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [textures] example - Fog of war
// *
// *   Example originally created with raylib 4.2, last time updated with raylib 4.2
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2018-2024 Ramon Santamaria (@raysan5)
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
  const MAP_TILE_SIZE = 32;         // Tiles size 32x32 pixels
  const PLAYER_SIZE = 16;           // Player size
  const PLAYER_TILE_VISIBILITY = 2; // Player can see 2 tiles around its position

  // Map data type
  const Map = struct {
    tilesX: u32,            // Number of tiles in X axis
    tilesY: u32,            // Number of tiles in Y axis
    tileIds: [*]u8,         // Tile ids (tilesX*tilesY), defines type of tile to draw
    tileFog: [*]u8,         // Tile fog state (tilesX*tilesY), defines if a tile has fog or half-fog
  };

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: i32 = 800;
  const screenHeight: i32 = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [textures] example - fog of war");

  var map = Map{
    .tilesX = 25,
    .tilesY = 15,
    .tileIds = @ptrCast(std.c.malloc(25 * 15)),
    .tileFog = @ptrCast(std.c.malloc(25 * 15)),
  };

  // NOTE: We can have up to 256 values for tile ids and for tile fog state,
  // probably we don't need that many values for fog state, it can be optimized
  // to use only 2 bits per fog state (reducing size by 4) but logic will be a bit more complex

  // Load map tiles (generating 2 random tile ids for testing)
  // NOTE: Map tile ids should be probably loaded from an external map file
  for (0..map.tilesY * map.tilesX) |i| map.tileIds[i] = @intCast(ray.GetRandomValue(0, 1));

  // Player position on the screen (pixel coordinates, not tile coordinates)
  var playerPosition = ray.Vector2{ .x = 180, .y = 130 };
  var playerTileX: i32 = 0;
  var playerTileY: i32 = 0;

  // Render texture to render fog of war
  // NOTE: To get an automatic smooth-fog effect we use a render texture to render fog
  // at a smaller size (one pixel per tile) and scale it on drawing with bilinear filtering
  const fogOfWar = ray.LoadRenderTexture(@intCast(map.tilesX), @intCast(map.tilesY));
  ray.SetTextureFilter(fogOfWar.texture, ray.TEXTURE_FILTER_BILINEAR);

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // Move player around
    if (ray.IsKeyDown(ray.KEY_RIGHT)) playerPosition.x += 5;
    if (ray.IsKeyDown(ray.KEY_LEFT)) playerPosition.x -= 5;
    if (ray.IsKeyDown(ray.KEY_DOWN)) playerPosition.y += 5;
    if (ray.IsKeyDown(ray.KEY_UP)) playerPosition.y -= 5;

    // Check player position to avoid moving outside tilemap limits
    if (playerPosition.x < 0) playerPosition.x = 0
    else if ((playerPosition.x + toFloat(PLAYER_SIZE)) > @as(f32, @floatFromInt(map.tilesX * MAP_TILE_SIZE))) playerPosition.x = @as(f32, @floatFromInt(map.tilesX * MAP_TILE_SIZE)) - toFloat(PLAYER_SIZE);
    if (playerPosition.y < 0) playerPosition.y = 0
    else if ((playerPosition.y + toFloat(PLAYER_SIZE)) > @as(f32, @floatFromInt(map.tilesY * MAP_TILE_SIZE))) playerPosition.y = @as(f32, @floatFromInt(map.tilesY * MAP_TILE_SIZE)) - toFloat(PLAYER_SIZE);

    // Previous visited tiles are set to partial fog
    for (0..map.tilesX * map.tilesY) |i| { if (map.tileFog[i] == 1) map.tileFog[i] = 2; }

    // Get current tile position from player pixel position
    playerTileX = toInt((playerPosition.x + toFloat(MAP_TILE_SIZE) / 2.0) / toFloat(MAP_TILE_SIZE));
    playerTileY = toInt((playerPosition.y + toFloat(MAP_TILE_SIZE) / 2.0) / toFloat(MAP_TILE_SIZE));

    {
      // Check visibility and update fog
      // NOTE: We check tilemap limits to avoid processing tiles out-of-array-bounds (it could crash program)
      var y = playerTileY - PLAYER_TILE_VISIBILITY;
      while (y < playerTileY + PLAYER_TILE_VISIBILITY) : (y += 1) {
        var x = playerTileX - PLAYER_TILE_VISIBILITY;
        while (x < playerTileX + PLAYER_TILE_VISIBILITY) : (x += 1) {
          if ((x >= 0) and (x < map.tilesX) and (y >= 0) and (y < map.tilesY)) map.tileFog[@intCast(y * @as(i32, @intCast(map.tilesX)) + x)] = 1;
        }
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    // Draw fog of war to a small render texture for automatic smoothing on scaling
    ray.BeginTextureMode(fogOfWar);
      ray.ClearBackground(ray.BLANK);
      {
        var y: u32 = 0;
        while (y < map.tilesY) : (y += 1) {
          var x: u32 = 0;
          while (x < map.tilesX) : (x += 1) {
            if (map.tileFog[@intCast(y * map.tilesX + x)] == 0) ray.DrawRectangle(@intCast(x), @intCast(y), 1, 1, ray.BLACK)
            else if (map.tileFog[@intCast(y * map.tilesX + x)] == 2) ray.DrawRectangle(@intCast(x), @intCast(y), 1, 1, ray.Fade(ray.BLACK, 0.8));
          }
        }
      }
    ray.EndTextureMode();

    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      {
        var y: u32 = 0;
        while (y < map.tilesY) : (y += 1) {
          var x: u32 = 0;
          while (x < map.tilesX) : (x += 1) {
            // Draw tiles from id (and tile borders)
            ray.DrawRectangle(@intCast(x * MAP_TILE_SIZE), @intCast(y * MAP_TILE_SIZE), MAP_TILE_SIZE, MAP_TILE_SIZE,
                              if (map.tileIds[@intCast(y * map.tilesX + x)] == 0) ray.BLUE else ray.Fade(ray.BLUE, 0.9));
            ray.DrawRectangleLines(@intCast(x * MAP_TILE_SIZE), @intCast(y * MAP_TILE_SIZE), MAP_TILE_SIZE, MAP_TILE_SIZE, ray.Fade(ray.DARKBLUE, 0.5));
          }
        }
      }

      // Draw player
      ray.DrawRectangleV(playerPosition, ray.Vector2{ .x = toFloat(PLAYER_SIZE), .y = toFloat(PLAYER_SIZE) }, ray.RED);

      // Draw fog of war (scaled to full map, bilinear filtering)
      ray.DrawTexturePro(fogOfWar.texture, ray.Rectangle{ 
        .x = 0, 
        .y = 0, 
        .width = toFloat(fogOfWar.texture.width), 
        .height = toFloat(-fogOfWar.texture.height) 
      }, ray.Rectangle{ 
        .x = 0, 
        .y = 0, 
        .width = toFloat( @as(i32, @intCast(map.tilesX * MAP_TILE_SIZE))), 
        .height = toFloat( @as(i32, @intCast(map.tilesY * MAP_TILE_SIZE))) 
      }, ray.Vector2{ .x = 0, .y = 0 }, 0.0, ray.WHITE);

      // Draw player current tile
      ray.DrawText(ray.TextFormat("Current tile: [%i,%i]", playerTileX, playerTileY), 10, 10, 20, ray.RAYWHITE);
      ray.DrawText("ARROW KEYS to move", 10, screenHeight-25, 20, ray.RAYWHITE);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  std.c.free(map.tileIds);      // Free allocated map tile ids
  std.c.free(map.tileFog);      // Free allocated map tile fog state

  ray.UnloadRenderTexture(fogOfWar);  // Unload render texture

  ray.CloseWindow();          // Close window and OpenGL context
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