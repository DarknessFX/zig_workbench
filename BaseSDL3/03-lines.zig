// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
pub extern fn main() void; // Zig Main, ignored, using SDL3

const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
  @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
  @cInclude("SDL.h");
  @cInclude("SDL_main.h");
});

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Lines";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-lines");

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

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
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

  // Define line points
  const line_points = [_]sdl.SDL_FPoint{
    .{ .x = 100, .y = 354 }, .{ .x = 220, .y = 230 }, .{ .x = 140, .y = 230 },
    .{ .x = 320, .y = 100 }, .{ .x = 500, .y = 230 }, .{ .x = 420, .y = 230 },
    .{ .x = 540, .y = 354 }, .{ .x = 400, .y = 354 }, .{ .x = 100, .y = 354 },
  };

  // Start with a blank canvas
  _ = sdl.SDL_SetRenderDrawColor(renderer, 100, 100, 100, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  // Draw individual brown lines
  _ = sdl.SDL_SetRenderDrawColor(renderer, 127, 49, 32, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderLine(renderer, 240, 450, 400, 450);
  _ = sdl.SDL_RenderLine(renderer, 240, 356, 400, 356);
  _ = sdl.SDL_RenderLine(renderer, 240, 356, 240, 450);
  _ = sdl.SDL_RenderLine(renderer, 400, 356, 400, 450);

  // Draw a series of connected green lines
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 255, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderLines(renderer, &line_points[0], line_points.len);

  // Draw lines from a center point in a circle with random colors
  for (0..360) |i| {
    const size: f32 = 30.0;
    const x: f32 = 320.0;
    const y: f32 = 95.0 - (size / 2.0);
    const fi: f32 = @floatFromInt(i);
    _ = sdl.SDL_SetRenderDrawColor(renderer, 
      @as(u8, @intCast(sdl.SDL_rand(256))), 
      @as(u8, @intCast(sdl.SDL_rand(256))), 
      @as(u8, @intCast(sdl.SDL_rand(256))), sdl.SDL_ALPHA_OPAQUE);

    _ = sdl.SDL_RenderLine(
      renderer,
      x, y,
      x + sdl.SDL_sinf(fi) * size,
      y + sdl.SDL_cosf(fi) * size,
    );
  }

  // Put it all on the screen
  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;
  //* SDL will clean up the window/renderer for us. */
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================


//#endregion ==================================================================
//=============================================================================