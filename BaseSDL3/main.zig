//!zig-autodoc-section: BaseSDL3\\main.zig
//! main.zig :
//!	  Template using SDL3 framework.
// Build using Zig 0.13.0

const std = @import("std");
pub extern fn main() void; // Zig Main, ignored, using SDL3

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseSDL3/lib/SDL3/include/SDL.h");
const sdl = @cImport({
  @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
  @cInclude("SDL.h");
  @cInclude("SDL_main.h");
});

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;
  const appTitle = "BaseSDL3";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.base-sdl3");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, 640, 480, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  return sdl.SDL_APP_CONTINUE; // carry on with the program!
}

//* This function runs when a new event (mouse input, keypresses, etc) occurs. */
pub export fn SDL_AppEvent(appstate: ?*anyopaque, event: *sdl.SDL_Event) sdl.SDL_AppResult {
  _ = appstate;

  // SHIFT + ESC to quit
  if (event.key.key == sdl.SDLK_ESCAPE 
  and event.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
    return sdl.SDL_EVENT_QUIT;
  }

  if (event.*.type == sdl.SDL_EVENT_QUIT) {
    return sdl.SDL_APP_SUCCESS; // end the program, reporting success to the OS
  }
  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once per frame, and is the heart of the program. */
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;
  const now: f64 = @as(f64, @floatFromInt(sdl.SDL_GetTicks())) / 1000.0;

  // Calculate the frame color using sine wave trick
  const red: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now)));
  const green: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 2 / 3)));
  const blue: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 4 / 3)));

  // Set the renderer's draw color
  _ = sdl.SDL_SetRenderDrawColorFloat(renderer, red, green, blue, sdl.SDL_ALPHA_OPAQUE_FLOAT);

  // Clear the window with the new color
  _ = sdl.SDL_RenderClear(renderer);

  // Present the new rendering
  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;
  //* SDL will clean up the window/renderer for us. */
}