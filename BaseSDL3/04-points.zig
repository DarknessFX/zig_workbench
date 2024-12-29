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

var last_time: u64 = 0;
const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;
const NUM_POINTS = 500;
const MIN_PIXELS_PER_SECOND = 30;
const MAX_PIXELS_PER_SECOND = 60;

// Arrays for points and speeds
var points: [NUM_POINTS]sdl.SDL_FPoint = undefined;
var point_speeds: [NUM_POINTS]f32 = undefined;

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Points";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-points");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, 640, 480, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  // Set up the data for a bunch of points
  for (0..points.len) |i| {
    points[i].x = sdl.SDL_randf() * WINDOW_WIDTH;
    points[i].y = sdl.SDL_randf() * WINDOW_HEIGHT;
    point_speeds[i] = MIN_PIXELS_PER_SECOND + 
      (sdl.SDL_randf() * (MAX_PIXELS_PER_SECOND - MIN_PIXELS_PER_SECOND));
  }
  last_time = sdl.SDL_GetTicks();

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

  const now = sdl.SDL_GetTicks();
  const elapsed = @as(f32, @floatFromInt(now - last_time)) / 1000.0;

  for (0..points.len) |i| {
    const distance = elapsed * point_speeds[i];
    points[i].x += distance;
    points[i].y += distance;

    if (points[i].x >= WINDOW_WIDTH 
    or points[i].y >= WINDOW_HEIGHT) {
      if (sdl.SDL_rand(2) == 1) {
        points[i].x = sdl.SDL_randf() * WINDOW_WIDTH;
        points[i].y = 0.0;
      } else {
        points[i].x = 0.0;
        points[i].y = sdl.SDL_randf() * WINDOW_HEIGHT;
      }
      point_speeds[i] = MIN_PIXELS_PER_SECOND + 
        (sdl.SDL_randf() * (MAX_PIXELS_PER_SECOND - MIN_PIXELS_PER_SECOND));
    }
  }
  last_time = now;

  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderPoints(renderer, &points[0], points.len);

  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;
  //* SDL will clean up the window/renderer for us. */
}