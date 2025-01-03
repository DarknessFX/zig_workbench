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
const rl = @cImport({ 
  @cInclude("raylib.h"); 
});

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}

const GRAVITY: c_int = 400;
const PLAYER_JUMP_SPD: c_int = 350.0;
const PLAYER_HOR_SPD: c_int = 200.0;
const MAX_ENVIRONMENT_ELEMENTS: c_int = 5;

const Player = struct {
  position: rl.Vector2,
  speed: f32,
  canJump: bool,
};

const EnvElement = struct {
  rect: rl.Rectangle,
  blocking: i32,
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

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - automation events");

  // Define player
  var player = Player{ .position = rl.Vector2{ .x = 400, .y = 280 }, .speed = 0, .canJump = false };

  // Define environment elements (platforms)
  var envElements: [MAX_ENVIRONMENT_ELEMENTS]EnvElement = undefined;
  envElements[0] = EnvElement{ .rect = rl.Rectangle{ .x = 0,     .y = 0, .width = 1000, .height = 400 }, .blocking = 0, .color = rl.LIGHTGRAY };
  envElements[1] = EnvElement{ .rect = rl.Rectangle{ .x = 0,   .y = 400, .width = 1000, .height = 200 }, .blocking = 1, .color = rl.GRAY };
  envElements[2] = EnvElement{ .rect = rl.Rectangle{ .x = 300, .y = 200,  .width = 400, .height =  10 }, .blocking = 1, .color = rl.GRAY };
  envElements[3] = EnvElement{ .rect = rl.Rectangle{ .x = 250, .y = 300,  .width = 100, .height =  10 }, .blocking = 1, .color = rl.GRAY };
  envElements[4] = EnvElement{ .rect = rl.Rectangle{ .x = 650, .y = 300,  .width = 100, .height =  10 }, .blocking = 1, .color = rl.GRAY };

  // Define camera
  var camera = rl.Camera2D{
    .target = player.position,
    .offset = rl.Vector2{ .x = screenWidth / 2.0, .y = screenHeight / 2.0 },
    .rotation = 0.0,
    .zoom = 1.0,
  };

  // Automation events
  var aelist = rl.LoadAutomationEventList(0); // Initialize list of automation events to record new events
  rl.SetAutomationEventList(&aelist);
  var eventRecording = false;
  var eventPlaying = false;

  var frameCounter: u32 = 0;
  var playFrameCounter: u32 = 0;
  var currentPlayFrame: u32 = 0;

  rl.SetTargetFPS(60);
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) {
    // Update
    //----------------------------------------------------------------------------------
    const deltaTime = 0.015; // rl.GetFrameTime();

    // Dropped files logic
    //----------------------------------------------------------------------------------
    if (rl.IsFileDropped()) {
      const droppedFiles = rl.LoadDroppedFiles();

      // Supports loading .rgs style files (text or binary) and .png style palette images
      if (rl.IsFileExtension(droppedFiles.paths[0], ".txt;.rae")) {
        rl.UnloadAutomationEventList(aelist);
        aelist = rl.LoadAutomationEventList(droppedFiles.paths[0]);

        eventRecording = false;

        // Reset scene state to play
        eventPlaying = true;
        playFrameCounter = 0;
        currentPlayFrame = 0;

        player.position = rl.Vector2{ .x = 400, .y = 280 };
        player.speed = 0;
        player.canJump = false;

        camera.target = player.position;
        camera.offset = rl.Vector2{ .x = screenWidth / 2.0, .y = screenHeight / 2.0 };
        camera.rotation = 0.0;
        camera.zoom = 1.0;
      }

      rl.UnloadDroppedFiles(droppedFiles); // Unload filepaths from memory
    }
    //----------------------------------------------------------------------------------

    // Update player
    //----------------------------------------------------------------------------------
    if (rl.IsKeyDown(rl.KEY_LEFT)) player.position.x -= toFloat(PLAYER_HOR_SPD) * deltaTime;
    if (rl.IsKeyDown(rl.KEY_RIGHT)) player.position.x += toFloat(PLAYER_HOR_SPD) * deltaTime;
    if (rl.IsKeyDown(rl.KEY_SPACE) and player.canJump) {
      player.speed = -PLAYER_JUMP_SPD;
      player.canJump = false;
    }

    var hitObstacle = false;
    for (0..MAX_ENVIRONMENT_ELEMENTS) |i| {
      const element = &envElements[i];
      const p = &player.position;
      if (element.blocking != 0 and
          element.rect.x <= p.x and
          element.rect.x + element.rect.width >= p.x and
          element.rect.y >= p.y and
          element.rect.y <= p.y + player.speed * deltaTime) {
        hitObstacle = true;
        player.speed = 0.0;
        p.y = element.rect.y;
      }
    }

    if (!hitObstacle) {
      player.position.y += player.speed * deltaTime;
      player.speed += toFloat(GRAVITY) * deltaTime;
      player.canJump = false;
    } else {
      player.canJump = true;
    }

    if (rl.IsKeyPressed(rl.KEY_R)) {
      // Reset game state
      player.position = rl.Vector2{ .x = 400, .y = 280 };
      player.speed = 0;
      player.canJump = false;

      camera.target = player.position;
      camera.offset = rl.Vector2{ .x = screenWidth / 2.0, .y = screenHeight / 2.0 };
      camera.rotation = 0.0;
      camera.zoom = 1.0;
    }
    //----------------------------------------------------------------------------------

    // Events playing
    // NOTE: Logic must be before Camera update because it depends on mouse-wheel value,
    // that can be set by the played event... but some other inputs could be affected
    //----------------------------------------------------------------------------------
    if (eventPlaying) {
      // NOTE: Multiple events could be executed in a single frame
      while (playFrameCounter == aelist.events[currentPlayFrame].frame) {
        rl.PlayAutomationEvent(aelist.events[currentPlayFrame]);
        currentPlayFrame += 1;

        if (currentPlayFrame == aelist.count) {
          eventPlaying = false;
          currentPlayFrame = 0;
          playFrameCounter = 0;

          rl.TraceLog(rl.LOG_INFO, "FINISH PLAYING!");
          break;
        }
      }

      playFrameCounter += 1;
    }
    //----------------------------------------------------------------------------------

    // Update camera
    //----------------------------------------------------------------------------------
    camera.target = player.position;
    camera.offset = rl.Vector2{ .x = screenWidth / 2.0, .y = screenHeight / 2.0 };
    var minX: f32 = 1000.0;
    var minY: f32 = 1000.0;
    var maxX: f32 = -1000.0;
    var maxY: f32 = -1000.0;

    // WARNING: On event replay, mouse-wheel internal value is set
    camera.zoom += (rl.GetMouseWheelMove() * 0.05);
    if (camera.zoom > 3.0) camera.zoom = 3.0
    else if (camera.zoom < 0.25) camera.zoom = 0.25;

    for (0..MAX_ENVIRONMENT_ELEMENTS) |i| {
      const element = &envElements[i];
      minX = @min(element.rect.x, minX);
      maxX = @max(element.rect.x + element.rect.width, maxX);
      minY = @min(element.rect.y, minY);
      maxY = @max(element.rect.y + element.rect.height, maxY);
    }

    const max = rl.GetWorldToScreen2D(rl.Vector2{ .x = maxX, .y = maxY }, camera);
    const min = rl.GetWorldToScreen2D(rl.Vector2{ .x = minX, .y = minY }, camera);

    if (max.x < screenWidth) camera.offset.x = screenWidth - (max.x - screenWidth / 2.0);
    if (max.y < screenHeight) camera.offset.y = screenHeight - (max.y - screenHeight / 2.0);
    if (min.x > 0) camera.offset.x = screenWidth / 2.0 - min.x;
    if (min.y > 0) camera.offset.y = screenHeight / 2.0 - min.y;
    //----------------------------------------------------------------------------------

    // Events management
    if (rl.IsKeyPressed(rl.KEY_S)) { // Toggle events recording
      if (!eventPlaying) {
        if (eventRecording) {
          rl.StopAutomationEventRecording();
          eventRecording = false;

          _ = rl.ExportAutomationEventList(aelist, "automation.rae");

          rl.TraceLog(rl.LOG_INFO, "RECORDED FRAMES: %i", aelist.count);
        } else {
          rl.SetAutomationEventBaseFrame(180);
          rl.StartAutomationEventRecording();
          eventRecording = true;
        }
      }
    } else if (rl.IsKeyPressed(rl.KEY_A)) { // Toggle events playing (WARNING: Starts next frame)
      if (!eventRecording and (aelist.count > 0)) {
        // Reset scene state to play
        eventPlaying = true;
        playFrameCounter = 0;
        currentPlayFrame = 0;

        player.position = rl.Vector2{ .x = 400, .y = 280 };
        player.speed = 0;
        player.canJump = false;

        camera.target = player.position;
        camera.offset = rl.Vector2{ .x = screenWidth / 2.0, .y = screenHeight / 2.0 };
        camera.rotation = 0.0;
        camera.zoom = 1.0;
      }
    }

    if (eventRecording or eventPlaying) frameCounter += 1
    else frameCounter = 0;
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

    rl.ClearBackground(rl.LIGHTGRAY);

    rl.BeginMode2D(camera);

    // Draw environment elements
    for (0..MAX_ENVIRONMENT_ELEMENTS) |i| {
      rl.DrawRectangleRec(envElements[i].rect, envElements[i].color);
    }

    // Draw player rectangle
    rl.DrawRectangleRec(rl.Rectangle{
      .x = player.position.x - 20,
      .y = player.position.y - 40,
      .width = 40,
      .height = 40,
    }, rl.RED);

    rl.EndMode2D();

    // Draw game controls
    rl.DrawRectangle(10, 10, 290, 145, rl.Fade(rl.SKYBLUE, 0.5));
    rl.DrawRectangleLines(10, 10, 290, 145, rl.Fade(rl.BLUE, 0.8));

    rl.DrawText("Controls:", 20, 20, 10, rl.DARKGRAY);
    rl.DrawText("Arrow keys = Move", 20, 40, 10, rl.DARKGRAY);
    rl.DrawText("Space = Jump", 20, 60, 10, rl.DARKGRAY);
    rl.DrawText("R = Reset", 20, 80, 10, rl.DARKGRAY);
    rl.DrawText("S = Record Event", 20, 100, 10, rl.DARKGRAY);
    rl.DrawText("A = Play Event", 20, 120, 10, rl.DARKGRAY);

    rl.EndDrawing();
    //--------------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}