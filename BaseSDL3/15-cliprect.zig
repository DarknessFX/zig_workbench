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

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

const CLIPRECT_SIZE = 250;
const CLIPRECT_SPEED = 200;   //* pixels per second */

var cliprect_position: sdl.SDL_FPoint  = undefined;
var cliprect_direction: sdl.SDL_FPoint = undefined;
var last_time: f32  = 0.0;

//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Clipping Rectangle";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-cliprect");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, WINDOW_WIDTH, WINDOW_HEIGHT, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  cliprect_direction.x = 1.0;
  cliprect_direction.y = 1.0;
  last_time = @floatFromInt(sdl.SDL_GetTicks());

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

  const cliprect = sdl.SDL_Rect{
    .x = @as(c_int, @intFromFloat(sdl.SDL_roundf(cliprect_position.x))),
    .y = @as(c_int, @intFromFloat(sdl.SDL_roundf(cliprect_position.y))),
    .w = CLIPRECT_SIZE,
    .h = CLIPRECT_SIZE,
  };

  const now: f32 = @floatFromInt(sdl.SDL_GetTicks());
  const elapsed = (now - last_time) / 1000.0; // seconds since last iteration
  const distance = elapsed * CLIPRECT_SPEED;

  // Update clipping rectangle position
  cliprect_position.x += distance * cliprect_direction.x;
  if (cliprect_position.x < 0.0) {
    cliprect_position.x = 0.0;
    cliprect_direction.x = 1.0;
  } else if (cliprect_position.x >= @as(f32, @floatFromInt(WINDOW_WIDTH - CLIPRECT_SIZE))) {
    cliprect_position.x = @as(f32, @floatFromInt(WINDOW_WIDTH - CLIPRECT_SIZE - 1));
    cliprect_direction.x = -1.0;
  }

  cliprect_position.y += distance * cliprect_direction.y;
  if (cliprect_position.y < 0.0) {
    cliprect_position.y = 0.0;
    cliprect_direction.y = 1.0;
  } else if (cliprect_position.y >= @as(f32, @floatFromInt(WINDOW_HEIGHT - CLIPRECT_SIZE))) {
    cliprect_position.y = @as(f32, @floatFromInt(WINDOW_HEIGHT - CLIPRECT_SIZE - 1));
    cliprect_direction.y = -1.0;
  }

  _ = sdl.SDL_SetRenderClipRect(renderer, &cliprect);
  last_time = now;

  // Render scene
  _ = sdl.SDL_SetRenderDrawColor(renderer, 33, 33, 33, sdl.SDL_ALPHA_OPAQUE); // grey, full alpha
  _ = sdl.SDL_RenderClear(renderer); // start with a blank canvas

  // Stretch texture across the window; only the clipped part will render
  _ = sdl.SDL_RenderTexture(renderer, texture, null, null);

  _ = sdl.SDL_RenderPresent(renderer); // present to the screen

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  sdl.SDL_DestroyTexture(texture);
  //* SDL will clean up the window/renderer for us. */
}