// Build using Zig 0.15.1

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

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Rectangles";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-rectangles");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, WINDOW_WIDTH, WINDOW_HEIGHT, 0, @ptrCast(&window), @ptrCast(&renderer))) {
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

  const now: f32 = @floatFromInt(sdl.SDL_GetTicks());
  const direction: f32 = if (@mod(now, 2000) >= 1000) 1.0 else -1.0;
  const scale = (@mod(now, 1000.0) - 500) / 500.0 * direction;

  var rects: [16]sdl.SDL_FRect = undefined;

  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  rects[0].x = 100;
  rects[0].y = rects[0].x;
  rects[0].w = 100 + (100 * scale);
  rects[0].h = rects[0].w;
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderRect(renderer, &rects[0]);

  for (0..3) |i| {
    const size: f32 = @as(f32, @floatFromInt(i + 1)) * 50.0;
    rects[i].h = size + (size * scale);
    rects[i].w = rects[i].h;
    rects[i].x = (WINDOW_WIDTH - rects[i].w) / 2;
    rects[i].y = (WINDOW_HEIGHT - rects[i].h) / 2;
  }
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 255, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderRects(renderer, &rects[0], 3);

  rects[0].x = 400;
  rects[0].y = 50;
  rects[0].w = 100 + (100 * scale);
  rects[0].h = 50 + (50 * scale);
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 255, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderFillRect(renderer, &rects[0]);

  for (0..rects.len) |i| {
    const fi = @as(f32, @floatFromInt(i));
    const w: f32 = WINDOW_WIDTH / rects.len;
    const h: f32 = fi * 8.0;
    rects[i].x = fi * w;
    rects[i].y = WINDOW_HEIGHT - h;
    rects[i].w = w;
    rects[i].h = h;
  }
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderFillRects(renderer, &rects[0], rects.len);

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