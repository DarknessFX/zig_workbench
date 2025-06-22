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
var texture: ?*sdl.SDL_Texture = undefined;

const TEXTURE_SIZE: c_int = 150;

const WINDOW_WIDTH: c_int = 640;
const WINDOW_HEIGHT: c_int = 480;


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Streaming Textures";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-streaming-textures");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, WINDOW_WIDTH, WINDOW_HEIGHT, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_RGBA8888, sdl.SDL_TEXTUREACCESS_STREAMING, TEXTURE_SIZE, TEXTURE_SIZE);
  if (texture == null) {
    sdl.SDL_Log("Couldn't create streaming texture: %s", sdl.SDL_GetError());
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

  var surface: *sdl.SDL_Surface = undefined;
  var dst_rect: sdl.SDL_FRect = undefined;

  if (sdl.SDL_LockTextureToSurface(texture, null, @ptrCast(&surface))) {
    const sdl_format = sdl.SDL_GetPixelFormatDetails(surface.format);
    const sdl_palette = sdl.SDL_GetSurfacePalette(surface);
    var r: sdl.SDL_Rect = undefined;
    _ = sdl.SDL_FillSurfaceRect(surface, null, 
      sdl.SDL_MapRGB(
        sdl_format,
        sdl_palette,
        0, 0, 0));  // make the whole surface black
    r.w = TEXTURE_SIZE;
    r.h = TEXTURE_SIZE / 10;
    r.x = 0;
    r.y = @as(c_int, @intFromFloat( @as(f32, @floatFromInt(TEXTURE_SIZE - r.h)) * ((scale + 1.0) / 2.0) ));
    _ = sdl.SDL_FillSurfaceRect(
        surface, &r, 
        sdl.SDL_MapRGB(
          sdl_format,
          sdl_palette,
          0, 255, 0));  // make a strip of the surface green
    _ = sdl.SDL_UnlockTexture(texture);  // upload the changes (and frees the temporary surface)!
  }

  _ = sdl.SDL_SetRenderDrawColor(renderer, 66, 66, 66, sdl.SDL_ALPHA_OPAQUE);  // grey, full alpha
  _ = sdl.SDL_RenderClear(renderer);

  const fTEXTURE_SIZE: f32 = @floatFromInt(TEXTURE_SIZE);
  dst_rect.x = (WINDOW_WIDTH - TEXTURE_SIZE) / 2;
  dst_rect.y = (WINDOW_HEIGHT - TEXTURE_SIZE) / 2;
  dst_rect.w = fTEXTURE_SIZE;
  dst_rect.h = fTEXTURE_SIZE;
  _ = sdl.SDL_RenderTexture(renderer, texture, null, &dst_rect);

  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  sdl.SDL_DestroyTexture(texture);
  //* SDL will clean up the window/renderer for us. */
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================


//#endregion ==================================================================
//=============================================================================