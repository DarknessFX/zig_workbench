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
var texture_width: c_int = 0;
var texture_height: c_int = 0;

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Color Mods";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-color-mods");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, WINDOW_WIDTH, WINDOW_HEIGHT, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  var bmp_path: [*c]u8 = undefined;
  var surface: ?*sdl.SDL_Surface = undefined;

  {
    var buf: [1024]u8 = std.mem.zeroes([1024]u8);
    const cwd = std.process.getCwd(&buf) catch unreachable;
    _ = sdl.SDL_asprintf(&bmp_path, "%s/asset/sample.bmp", cwd.ptr);
  }
  surface = sdl.SDL_LoadBMP(bmp_path);
  if (surface == null) {
    sdl.SDL_Log("Couldn't load bitmap: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  // /* Textures are pixel data that we upload to the video hardware for fast drawing. Lots of 2D
  //     engines refer to these as "sprites." We'll do a static texture (upload once, draw many
  //     times) with data from a bitmap file. */

  // /* SDL_Surface is pixel data the CPU can access. SDL_Texture is pixel data the GPU can access.
  //     Load a .bmp into a surface, move it to a texture from there. */
  sdl.SDL_free(bmp_path);  //* done with this, the file is loaded. */

  texture_width = surface.?.w;
  texture_height = surface.?.h;

  texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
  if (texture == null) {
    sdl.SDL_Log("Couldn't create static texture: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  sdl.SDL_DestroySurface(surface); //* done with this, the texture has a copy of the pixels now. */

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

  const now: f32 = @as(f32, @floatFromInt(sdl.SDL_GetTicks())) / 1000.0;
  const red: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now)));
  const green: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 2 / 3)));
  const blue: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 4 / 3)));

  const fWINDOW_WIDTH: f32 = @floatFromInt(WINDOW_WIDTH);
  const fWINDOW_HEIGHT: f32 = @floatFromInt(WINDOW_HEIGHT);
  const ftexture_width: f32 = @floatFromInt(texture_width);
  const ftexture_height: f32 = @floatFromInt(texture_height);

  // Clear the screen to black.
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  // Top left texture, make it blue.
  var dst_rect = sdl.SDL_FRect{
    .x = 0.0,
    .y = 0.0,
    .w = ftexture_width,
    .h = ftexture_height,
  };
  _ = sdl.SDL_SetTextureColorModFloat(texture, 0.0, 0.0, 1.0);
  _ = sdl.SDL_RenderTexture(renderer, texture, null, &dst_rect);

  // Center texture, cycle through colors.
  dst_rect.x = (fWINDOW_WIDTH - ftexture_width) / 2.0;
  dst_rect.y = (fWINDOW_HEIGHT - ftexture_height) / 2.0;
  _ = sdl.SDL_SetTextureColorModFloat(texture, red, green, blue);
  _ = sdl.SDL_RenderTexture(renderer, texture, null, &dst_rect);

  // Bottom right texture, make it red.
  dst_rect.x = fWINDOW_WIDTH - ftexture_width;
  dst_rect.y = fWINDOW_HEIGHT - ftexture_height;
  _ = sdl.SDL_SetTextureColorModFloat(texture, 1.0, 0.0, 0.0);
  _ = sdl.SDL_RenderTexture(renderer, texture, null, &dst_rect);

  // Present the renderer.
  _ = sdl.SDL_RenderPresent(renderer);
    return sdl.SDL_APP_CONTINUE; // carry on with the program
  }

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  sdl.SDL_DestroyTexture(texture);
  //* SDL will clean up the window/renderer for us. */
}