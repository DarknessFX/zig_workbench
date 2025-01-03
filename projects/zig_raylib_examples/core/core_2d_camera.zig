//!zig-autodoc-section: core_2d_camera.Main
//! raylib_examples/core_2d_camera.zig
//!   Example - 2D Camera system.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h");
  @cInclude("stdlib.h");
});

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: c_int = 800;
  const screenHeight: c_int = 450;
  const MAX_BUILDINGS: usize = 100;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera");

  var player: rl.Rectangle = .{ .x=400, .y=280, .width=40, .height=40 };
  var buildings: [MAX_BUILDINGS]rl.Rectangle = undefined;
  var buildColors: [MAX_BUILDINGS]rl.Color = undefined;

  var spacing: c_int = 0;

  for (0..MAX_BUILDINGS) |i| {
    buildings[i].width = toFloat(rl.GetRandomValue(50, 200));
    buildings[i].height = toFloat(rl.GetRandomValue(100, 800));
    buildings[i].y = toFloat(screenHeight) - 130.0 - buildings[i].height;
    buildings[i].x = -6000.0 + toFloat(spacing);

    spacing += toInt(buildings[i].width);

    buildColors[i] = rl.Color{
      .r = @intCast(rl.GetRandomValue(200, 240)),
      .g = @intCast(rl.GetRandomValue(200, 240)),
      .b = @intCast(rl.GetRandomValue(200, 250)),
      .a = 255,
    };
  }

  var camera: rl.Camera2D = .{};
  camera.target = rl.Vector2{ .x = player.x + 20.0, .y = player.y + 20.0 };
  camera.offset = rl.Vector2{ .x = toFloat(screenWidth) / 2.0, .y = toFloat(screenHeight) / 2.0 };
  camera.rotation = 0.0;
  camera.zoom = 1.0;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // Player movement
    if (rl.IsKeyDown(rl.KEY_RIGHT)) player.x += 2
    else if (rl.IsKeyDown(rl.KEY_LEFT)) player.x -= 2;

    // Camera target follows player
    camera.target = rl.Vector2{ .x = player.x + 20, .y = player.y + 20 };

    // Camera rotation controls
    if (rl.IsKeyDown(rl.KEY_A)) camera.rotation -= 1
    else if (rl.IsKeyDown(rl.KEY_S)) camera.rotation += 1;

    // Limit camera rotation to 80 degrees (-40 to 40)
    if (camera.rotation > 40) camera.rotation = 40
    else if (camera.rotation < -40) camera.rotation = -40;

    // Camera zoom controls
    camera.zoom += rl.GetMouseWheelMove() * 0.05;

    if (camera.zoom > 3.0) camera.zoom = 3.0
    else if (camera.zoom < 0.1) camera.zoom = 0.1;

    // Camera reset (zoom and rotation)
    if (rl.IsKeyPressed(rl.KEY_R)) {
      camera.zoom = 1.0;
      camera.rotation = 0.0;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

      rl.ClearBackground(rl.RAYWHITE);

      rl.BeginMode2D(camera);

        rl.DrawRectangle(-6000, 320, 13000, 8000, rl.DARKGRAY);

        for (0..MAX_BUILDINGS) |i| {
          rl.DrawRectangleRec(buildings[i], buildColors[i]);
        }

        rl.DrawRectangleRec(player, rl.RED);

        rl.DrawLine(toInt(camera.target.x), -screenHeight * 10, toInt(camera.target.x), screenHeight * 10, rl.GREEN);
        rl.DrawLine(-screenWidth * 10, toInt(camera.target.y), screenWidth * 10, toInt(camera.target.y), rl.GREEN);

      rl.EndMode2D();

      rl.DrawText("SCREEN AREA", 640, 10, 20, rl.RED);

      rl.DrawRectangle(0, 0, screenWidth, 5, rl.RED);
      rl.DrawRectangle(0, 5, 5, screenHeight - 10, rl.RED);
      rl.DrawRectangle(screenWidth - 5, 5, 5, screenHeight - 10, rl.RED);
      rl.DrawRectangle(0, screenHeight - 5, screenWidth, 5, rl.RED);

      rl.DrawRectangle(10, 10, 250, 113, rl.Fade(rl.SKYBLUE, 0.5));
      rl.DrawRectangleLines(10, 10, 250, 113, rl.BLUE);

      rl.DrawText("Free 2d camera controls:", 20, 20, 10, rl.BLACK);
      rl.DrawText("- Right/Left to move Offset", 40, 40, 10, rl.DARKGRAY);
      rl.DrawText("- Mouse Wheel to Zoom in-out", 40, 60, 10, rl.DARKGRAY);
      rl.DrawText("- A / S to Rotate", 40, 80, 10, rl.DARKGRAY);
      rl.DrawText("- R to reset Zoom and Rotation", 40, 100, 10, rl.DARKGRAY);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}