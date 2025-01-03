//!zig-autodoc-section: core_basic_screen_manager.Main
//! raylib_examples/core_basic_screen_manager.zig
//!   Example - Basic screen manager.
//!*   NOTE: This example illustrates a very simple screen manager based on a states machines
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

//------------------------------------------------------------------------------------------
// Types and Structures Definition
//------------------------------------------------------------------------------------------
const GameScreen = enum { LOGO, TITLE, GAMEPLAY, ENDING };

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {

  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth: usize  = 800;
  const screenHeight: usize = 450;

  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic screen manager");

  var currentScreen: GameScreen = .LOGO;

  // TODO: Initialize all required variables and load all required data here!

  var framesCounter: usize = 0;          // Useful to count frames

  rl.SetTargetFPS(60);  // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    switch (currentScreen) {
      .LOGO => {
        // TODO: Update LOGO screen variables here!

        framesCounter +%= 1;    // Count frames

        // Wait for 2 seconds (120 frames) before jumping to TITLE screen
        if (framesCounter > 120) {
          currentScreen = .TITLE;
        }        
      },
      .TITLE => {
        // TODO: Update TITLE screen variables here!

        // Press enter to change to GAMEPLAY screen
        if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsGestureDetected(rl.GESTURE_TAP)) {
          currentScreen = .GAMEPLAY;
        }        
      },
      .GAMEPLAY => {
        // TODO: Update GAMEPLAY screen variables here!

        // Press enter to change to ENDING screen
        if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsGestureDetected(rl.GESTURE_TAP)) {
            currentScreen = .ENDING;
        }
      },
      .ENDING => {
        // TODO: Update ENDING screen variables here!

        // Press enter to return to TITLE screen
        if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsGestureDetected(rl.GESTURE_TAP)) {
            currentScreen = .TITLE;
        }
      }
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginDrawing();

      rl.ClearBackground(rl.RAYWHITE);

      switch(currentScreen) {
        .LOGO => {
          // TODO: Draw LOGO screen here!
          rl.DrawText("LOGO SCREEN", 20, 20, 40, rl.LIGHTGRAY);
          rl.DrawText("WAIT for 2 SECONDS...", 290, 220, 20, rl.GRAY);

        },
        .TITLE => {
          // TODO: Draw TITLE screen here!
          rl.DrawRectangle(0, 0, screenWidth, screenHeight, rl.GREEN);
          rl.DrawText("TITLE SCREEN", 20, 20, 40, rl.DARKGREEN);
          rl.DrawText("PRESS ENTER or TAP to JUMP to GAMEPLAY SCREEN", 120, 220, 20, rl.DARKGREEN);

        },
        .GAMEPLAY => {
          // TODO: Draw GAMEPLAY screen here!
          rl.DrawRectangle(0, 0, screenWidth, screenHeight, rl.PURPLE);
          rl.DrawText("GAMEPLAY SCREEN", 20, 20, 40, rl.MAROON);
          rl.DrawText("PRESS ENTER or TAP to JUMP to ENDING SCREEN", 130, 220, 20, rl.MAROON);

        },
        .ENDING => {
          // TODO: Draw ENDING screen here!
          rl.DrawRectangle(0, 0, screenWidth, screenHeight, rl.BLUE);
          rl.DrawText("ENDING SCREEN", 20, 20, 40, rl.DARKBLUE);
          rl.DrawText("PRESS ENTER or TAP to RETURN to TITLE SCREEN", 120, 220, 20, rl.DARKBLUE);

        }
      }

    rl.EndDrawing();
    //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------

    // TODO: Unload all loaded data (textures, fonts, audio) here!

  rl.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}