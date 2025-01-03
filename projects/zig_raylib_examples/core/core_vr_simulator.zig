//!zig-autodoc-section: core_vr_simulator.Main
//! raylib_examples/core_vr_simulator.zig
//!   Example - VR Simulator (Oculus Rift CV1 parameters).
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

const GLSL_VERSION: c_int = 330;
//if (rl.is_platform_desktop()) 330 else 100;

// Helpers
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  // NOTE: screenWidth/screenHeight should match VR device aspect ratio
  rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - vr simulator");

  // VR device parameters definition
  const device = rl.VrDeviceInfo{
    // Oculus Rift CV1 parameters for simulator
    .hResolution = 2160, // Horizontal resolution in pixels
    .vResolution = 1200, // Vertical resolution in pixels
    .hScreenSize = 0.133793, // Horizontal size in meters
    .vScreenSize = 0.0669, // Vertical size in meters
    .eyeToScreenDistance = 0.041, // Distance between eye and display in meters
    .lensSeparationDistance = 0.07, // Lens separation distance in meters
    .interpupillaryDistance = 0.07, // IPD (distance between pupils) in meters

    // NOTE: CV1 uses fresnel-hybrid-asymmetric lenses with specific compute shaders
    // Following parameters are just an approximation to CV1 distortion stereo rendering
    .lensDistortionValues = .{1.0, 0.22, 0.24, 0.0}, // Lens distortion constants
    .chromaAbCorrection = .{0.996, -0.004, 1.014, 0.0}, // Chromatic aberration correction
  };

  // Load VR stereo config for VR device parameters (Oculus Rift CV1 parameters)
  const config = rl.LoadVrStereoConfig(device);

  // Distortion shader (uses device lens distortion and chroma)
  const distortion = rl.LoadShader(0, rl.TextFormat("resources/distortion%i.fs", GLSL_VERSION));

  // Update distortion shader with lens and distortion-scale parameters
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "leftLensCenter"), &config.leftLensCenter, rl.SHADER_UNIFORM_VEC2);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "rightLensCenter"), &config.rightLensCenter, rl.SHADER_UNIFORM_VEC2);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "leftScreenCenter"), &config.leftScreenCenter, rl.SHADER_UNIFORM_VEC2);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "rightScreenCenter"), &config.rightScreenCenter, rl.SHADER_UNIFORM_VEC2);

  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "scale"), &config.scale, rl.SHADER_UNIFORM_VEC2);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "scaleIn"), &config.scaleIn, rl.SHADER_UNIFORM_VEC2);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "deviceWarpParam"), &device.lensDistortionValues, rl.SHADER_UNIFORM_VEC4);
  rl.SetShaderValue(distortion, rl.GetShaderLocation(distortion, "chromaAbParam"), &device.chromaAbCorrection, rl.SHADER_UNIFORM_VEC4);

  // Initialize framebuffer for stereo rendering
  // NOTE: Screen size should match HMD aspect ratio
  const target = rl.LoadRenderTexture(device.hResolution, device.vResolution);

  // The target's height is flipped (in the source Rectangle), due to OpenGL reasons
  const sourceRec = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = toFloat(target.texture.width), .height = toFloat(-target.texture.height) };
  const destRec = rl.Rectangle{ .x = 0.0, .y = 0.0, .width =toFloat( rl.GetScreenWidth()), .height = toFloat(rl.GetScreenHeight()) };

  // Define the camera to look into our 3d world
  var camera = rl.Camera{ };
  camera.position = rl.Vector3{ .x = 5.0, .y = 2.0, .z = 5.0 }; // Camera position
  camera.target = rl.Vector3{ .x = 0.0, .y = 2.0, .z = 0.0 };  // Camera looking at point
  camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };      // Camera up vector
  camera.fovy = 60.0;                         // Camera field-of-view Y
  camera.projection = rl.CAMERA_PERSPECTIVE;  // Camera projection type

  const cubePosition = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };

  rl.DisableCursor(); // Limit cursor to relative movement inside the window

  rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    rl.UpdateCamera(&camera, rl.CAMERA_FIRST_PERSON);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    rl.BeginTextureMode(target);
      rl.ClearBackground(rl.RAYWHITE);
      rl.BeginVrStereoMode(config);
        rl.BeginMode3D(camera);

          rl.DrawCube(cubePosition, 2.0, 2.0, 2.0, rl.RED);
          rl.DrawCubeWires(cubePosition, 2.0, 2.0, 2.0, rl.MAROON);
          rl.DrawGrid(40, 1.0);

        rl.EndMode3D();
      rl.EndVrStereoMode();
    rl.EndTextureMode();
    
    rl.BeginDrawing();
      rl.ClearBackground(rl.RAYWHITE);
      rl.BeginShaderMode(distortion);
        rl.DrawTexturePro(target.texture, sourceRec, destRec, rl.Vector2{ .x = 0.0, .y = 0.0 }, 0.0, rl.WHITE);
      rl.EndShaderMode();
      rl.DrawFPS(10, 10);
    rl.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  rl.UnloadVrStereoConfig(config);   // Unload stereo config

  rl.UnloadRenderTexture(target);    // Unload stereo render fbo
  rl.UnloadShader(distortion);       // Unload distortion shader

  rl.CloseWindow();                  // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}
