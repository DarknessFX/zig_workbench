//!zig-autodoc-section: core_window_letterbox.Main
//! raylib_examples/core_window_letterbox.zig
//!   Example - window scale letterbox (and virtual mouse).
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const rl = @cImport({ 
  @cInclude("raylib.h"); 
});
const rm = @cImport({ 
  @cInclude("raymath.h"); 
});

// Helpers
inline fn MAX (a: f32, b: f32) f32 { return if (a > b) a else b; }
inline fn MIN (a: f32, b: f32) f32 { return if (a < b) a else b; }
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  const windowWidth: c_int = 800;
  const windowHeight: c_int = 450;

  // Enable config flags for resizable window and vertical synchro
  rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_VSYNC_HINT);
  rl.InitWindow(windowWidth, windowHeight, "raylib [core] example - window scale letterbox");
  rl.SetWindowMinSize(320, 240);

  const gameScreenWidth: f32 = 640.0;
  const gameScreenHeight: f32 = 480.0;

  // Render texture initialization, used to hold the rendering result so we can easily resize it
  const target = rl.LoadRenderTexture(gameScreenWidth, gameScreenHeight);
  rl.SetTextureFilter(target.texture, rl.TEXTURE_FILTER_BILINEAR);  // Texture scale filter to use

  // Initialize random colors for the bars
  var colors: [10]rl.Color = undefined;
  for (0..colors.len) |i| {
    colors[i] = rl.Color{
      .r = toU8(rl.GetRandomValue(100, 250)),
      .g = toU8(rl.GetRandomValue(50, 150)),
      .b = toU8(rl.GetRandomValue(10, 100)),
      .a = 255,
    };
  }

  rl.SetTargetFPS(60);  // Set our game to run at 60 frames-per-second

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    //----------------------------------------------------------------------------------
    // Compute required framebuffer scaling
    const scale: f32 = MIN(toFloat(rl.GetScreenWidth()) / gameScreenWidth, toFloat(rl.GetScreenHeight()) / gameScreenHeight);

    if (rl.IsKeyPressed(rl.KEY_SPACE)) {
      // Recalculate random colors for the bars
      for (0..colors.len) |i| {
        colors[i] = rl.Color{
          .r = toU8(rl.GetRandomValue(100, 250)),
          .g = toU8(rl.GetRandomValue(50, 150)),
          .b = toU8(rl.GetRandomValue(10, 100)),
          .a = 255,
        };
      }
    }

    // Update virtual mouse (clamped mouse value behind game screen)
    const mouse = rl.GetMousePosition();
    var virtualMouse = rm.Vector2{
      .x = (mouse.x - (toFloat(rl.GetScreenWidth()) - (gameScreenWidth * scale)) * 0.5) / scale,
      .y = (mouse.y - (toFloat(rl.GetScreenHeight()) - (gameScreenHeight * scale)) * 0.5) / scale,
    };
    virtualMouse = rm.Vector2Clamp(virtualMouse, rm.Vector2{ .x = 0, .y = 0 }, rm.Vector2{ .x = gameScreenWidth, .y = gameScreenHeight });

    // Apply the same transformation as the virtual mouse to the real mouse (i.e. to work with raygui)
    //SetMouseOffset(-(GetScreenWidth() - (gameScreenWidth*scale))*0.5f, -(GetScreenHeight() - (gameScreenHeight*scale))*0.5f);
    //SetMouseScale(1/scale, 1/scale);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    // Draw everything in the render texture, note this will not be rendered on screen, yet
    rl.BeginTextureMode(target);
    rl.ClearBackground(rl.RAYWHITE);  // Clear render texture background color

    for (0..colors.len) |i| {
      rl.DrawRectangle(0, toInt(gameScreenHeight / 10.0) * @as(c_int, @intCast(i)), toInt(gameScreenWidth), toInt(gameScreenHeight / 10.0), colors[i]);
    }

    rl.DrawText("If executed inside a window,\nyou can resize the window,\nand see the screen scaling!", 10, 25, 20, rl.WHITE);
    rl.DrawText(rl.TextFormat("Default Mouse: [%i , %i]", toInt(mouse.x), toInt(mouse.y)), 350, 25, 20, rl.GREEN);
    rl.DrawText(rl.TextFormat("Virtual Mouse: [%i , %i]", toInt(virtualMouse.x), toInt(virtualMouse.y)), 350, 55, 20, rl.YELLOW);
    rl.EndTextureMode();

    rl.BeginDrawing();
    rl.ClearBackground(rl.BLACK);  // Clear screen background

    // Draw render texture to screen, properly scaled
    rl.DrawTexturePro(target.texture, 
      rl.Rectangle{ .x = 0.0, .y = 0.0, 
        .width = toFloat(target.texture.width), 
        .height = toFloat(-target.texture.height) },
      rl.Rectangle{ 
        .x = (toFloat(rl.GetScreenWidth()) - gameScreenWidth * scale) * 0.5, 
        .y = (toFloat(rl.GetScreenHeight()) - gameScreenHeight * scale) * 0.5,
        .width = gameScreenWidth * scale, 
        .height = gameScreenHeight * scale }, rl.Vector2{ .x = 0, .y = 0 }, 0.0, rl.WHITE);
    rl.EndDrawing();
    //--------------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadRenderTexture(target);  // Unload render texture

  rl.CloseWindow();  // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}