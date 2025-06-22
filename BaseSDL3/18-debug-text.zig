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

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Debug Texture";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-debug-text");

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
//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

//* This function runs once per frame, and is the heart of the program. */
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;

  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderDebugText(renderer, 272, 100, "Hello world!");
  _ = sdl.SDL_RenderDebugText(renderer, 224, 150, "This is some debug text.");

  _ = sdl.SDL_SetRenderDrawColor(renderer, 51, 102, 255, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderDebugText(renderer, 184, 200, "You can do it in different colors.");
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);

  _ = sdl.SDL_SetRenderScale(renderer, 4.0, 4.0);
  _ = sdl.SDL_RenderDebugText(renderer, 14, 65, "It can be scaled.");
  _ = sdl.SDL_SetRenderScale(renderer, 1.0, 1.0);
  _ = sdl.SDL_RenderDebugText(renderer, 64, 350, "This only does ASCII chars. So this laughing emoji won't draw: 🤣");

  {
    const charsize = sdl.SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE;
    var buf: [*c]u8 = undefined;
    _ = sdl.SDL_asprintf(&buf, 
      "(This program has been running for %d seconds.)", 
      sdl.SDL_GetTicks() / 1000);
    _ = sdl.SDL_RenderDebugText(renderer, ((WINDOW_WIDTH - (charsize * 46)) / 2), 400, buf);
  }

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

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================