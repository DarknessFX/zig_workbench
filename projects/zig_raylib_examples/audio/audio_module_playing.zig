//!zig-autodoc-section: audio_module_playing.Main
//! raylib_examples/audio_module_playing.zig
//!   Example - Module playing (streaming).
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

const MAX_CIRCLES: c_int = 64;
const CircleWave = struct {
  position: rl.Vector2,
  radius: f32,
  alpha: f32,
  speed: f32,
  color: rl.Color,
};

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT); // NOTE: Try to enable MSAA 4X
  rl.InitWindow(screenWidth, screenHeight, "raylib [audio] example - module playing (streaming)");

  rl.InitAudioDevice(); // Initialize audio device

  const colors = [_]rl.Color{
    rl.ORANGE, rl.RED, rl.GOLD, rl.LIME, rl.BLUE, rl.VIOLET, rl.BROWN, rl.LIGHTGRAY, rl.PINK,
    rl.YELLOW, rl.GREEN, rl.SKYBLUE, rl.PURPLE, rl.BEIGE,
  };

  // Creates some circles for visual effect
  var circles: [MAX_CIRCLES]CircleWave = undefined;
  for (&circles) |*circle| {
    circle.*.alpha = 0.0;
    circle.*.radius = toFloat(rl.GetRandomValue(10, 40));
    circle.*.position.x = toFloat(rl.GetRandomValue(toInt(circle.radius), toInt(screenWidth - circle.radius)));
    circle.*.position.y = toFloat(rl.GetRandomValue(toInt(circle.radius), toInt(screenHeight - circle.radius)));
    circle.*.speed = toFloat(rl.GetRandomValue(1, 100)) / 2000.0;
    circle.*.color = colors[@intCast(rl.GetRandomValue(0, 13))];
  }

  var music = rl.LoadMusicStream(getPath("audio/resources/mini1111.xm"));
  music.looping = false;
  var pitch: f32 = 1.0;

  rl.PlayMusicStream(music);

  var timePlayed: f32 = 0.0; // Time played scaled to bar dimensions
  var pause = false;

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateMusicStream(music); // Update music buffer with new stream data

    // Restart music playing (stop and play)
    if (rl.IsKeyPressed(rl.KEY_SPACE)) {
      rl.StopMusicStream(music);
      rl.PlayMusicStream(music);
      pause = false;
    }

    // Pause/Resume music playing
    if (rl.IsKeyPressed(rl.KEY_P)) {
      pause = !pause;

      if (pause) rl.PauseMusicStream(music)
      else rl.ResumeMusicStream(music);
    }

    if (rl.IsKeyDown(rl.KEY_DOWN)) pitch -= 0.01
    else if (rl.IsKeyDown(rl.KEY_UP)) pitch += 0.01;

    rl.SetMusicPitch(music, pitch);

    // Get timePlayed scaled to bar dimensions
    timePlayed = rl.GetMusicTimePlayed(music) / rl.GetMusicTimeLength(music) * toFloat(screenWidth - 40);

    // Color circles animation
    for (&circles) |*circle| {
      if (!pause) {
        circle.*.alpha += circle.speed;
        circle.*.radius += circle.speed * 10.0;

        if (circle.*.alpha > 1.0) circle.*.speed *= -1;

        if (circle.*.alpha <= 0.0) {
          circle.*.alpha = 0.0;
          circle.*.radius = toFloat(rl.GetRandomValue(10, 40));
          circle.*.position.x = toFloat(rl.GetRandomValue(toInt(circle.radius), toInt(screenWidth - circle.radius)));
          circle.*.position.y = toFloat(rl.GetRandomValue(toInt(circle.radius), toInt(screenHeight - circle.radius)));
          circle.*.color = colors[@intCast(rl.GetRandomValue(0, 13))];
          circle.*.speed = toFloat(rl.GetRandomValue(1, 100)) / 2000.0;
        }
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    for (circles) |circle| {
      rl.DrawCircleV(circle.position, circle.radius, rl.Fade(circle.color, circle.alpha));
    }

    // Draw time bar
    rl.DrawRectangle(20, screenHeight - 20 - 12, screenWidth - 40, 12, rl.LIGHTGRAY);
    rl.DrawRectangle(20, screenHeight - 20 - 12, toInt(timePlayed), 12, rl.MAROON);
    rl.DrawRectangleLines(20, screenHeight - 20 - 12, screenWidth - 40, 12, rl.GRAY);

    // Draw help instructions
    rl.DrawRectangle(20, 20, 425, 145, rl.WHITE);
    rl.DrawRectangleLines(20, 20, 425, 145, rl.GRAY);
    rl.DrawText("PRESS SPACE TO RESTART MUSIC", 40, 40, 20, rl.BLACK);
    rl.DrawText("PRESS P TO PAUSE/RESUME", 40, 70, 20, rl.BLACK);
    rl.DrawText("PRESS UP/DOWN TO CHANGE SPEED", 40, 100, 20, rl.BLACK);
    rl.DrawText(rl.TextFormat("SPEED: %f", pitch), 40, 130, 20, rl.MAROON);

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadMusicStream(music); // Unload music stream buffers from RAM

  rl.CloseAudioDevice(); // Close audio device (music streaming is automatically stopped)

  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}

//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
fn getPath(file: []const u8) [*c]const u8 {
  // Get current folder
  const cwd: []u8 = std.process.getCwd(
    std.heap.page_allocator.alloc(u8, 256) catch unreachable)
    catch unreachable;
  defer std.heap.page_allocator.free(cwd);
  var file_fix = file[0..];
  while (std.mem.indexOf(u8, file_fix, "/")) |idx| {
    const file_pre = file_fix[0..idx];
    const file_pos = file_fix[idx + 1..];
    file_fix = std.mem.join(
      std.heap.page_allocator, 
      "\\", 
      &[_][]const u8{ file_pre, file_pos }) catch unreachable;
  }
  defer std.heap.page_allocator.free(file_fix);
  return @ptrCast(std.fs.path.join(std.heap.page_allocator, &.{ cwd, file_fix }) catch unreachable);
}
