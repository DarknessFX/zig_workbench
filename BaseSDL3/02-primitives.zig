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
var points: [500]sdl.SDL_FPoint = undefined;

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;
  const appTitle = "SDL3 Example Renderer Primitives";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-primitives");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, 640, 480, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }
  
  // Set up some random points
  for (0..points.len) |i| {
    points[i].x = (sdl.SDL_randf() * 440.0) + 100.0;
    points[i].y = (sdl.SDL_randf() * 280.0) + 100.0;
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

  var rect: sdl.SDL_FRect = undefined;
  // Start with a blank canvas
  _ = sdl.SDL_SetRenderDrawColor(renderer, 33, 33, 33, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  // Draw a filled rectangle in the middle of the canvas
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 255, sdl.SDL_ALPHA_OPAQUE);
  rect.x = 100;
  rect.y = 100;
  rect.w = 440;
  rect.h = 280;
  _ = sdl.SDL_RenderFillRect(renderer, &rect);

  // Draw some points across the canvas
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderPoints(renderer, &points[0], points.len);

  // Draw an unfilled rectangle in-set a little bit
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 255, 0, sdl.SDL_ALPHA_OPAQUE);
  rect.x += 30;
  rect.y += 30;
  rect.w -= 60;
  rect.h -= 60;
  _ = sdl.SDL_RenderRect(renderer, &rect);

  // Draw two lines in an X across the whole canvas
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderLine(renderer, 0, 0, 640, 480);
  _ = sdl.SDL_RenderLine(renderer, 0, 480, 640, 0);

  // Put it all on the screen
  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;
  //* SDL will clean up the window/renderer for us. */
}