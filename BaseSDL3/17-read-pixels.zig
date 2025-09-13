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
var texture: ?*sdl.SDL_Texture = undefined;
var texture_width: c_int = 0;
var texture_height: c_int = 0;
var converted_texture: ?*sdl.SDL_Texture = undefined;
var converted_texture_width: c_int = 0;
var converted_texture_height: c_int = 0;

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;
//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Renderer Read Pixels";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.renderer-read-pixels");

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
  const ftexture_width: f32 = @floatFromInt(texture_width);
  const ftexture_height: f32 = @floatFromInt(texture_height);
  var surface: *sdl.SDL_Surface = undefined;
  var center = sdl.SDL_FPoint{ .x = ftexture_width / 2.0, .y = ftexture_height / 2.0 };
  var dst_rect = sdl.SDL_FRect{
    .x = @as(f32, @floatFromInt(WINDOW_WIDTH - texture_width)) / 2.0,
    .y = @as(f32, @floatFromInt(WINDOW_HEIGHT - texture_height)) / 2.0,
    .w = ftexture_width,
    .h = ftexture_height,
  };

  // Calculate rotation
  const rotation: f32 = (@mod(now, 2000) / 2000.0) * 360.0;

  // Clear renderer
  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
  _ = sdl.SDL_RenderClear(renderer);

  // Render rotated texture
  _ = sdl.SDL_RenderTextureRotated(renderer, texture, null, &dst_rect, rotation, &center, sdl.SDL_FLIP_NONE);

  // Download pixels from renderer
  surface = sdl.SDL_RenderReadPixels(renderer, null);
  var surface_null: bool = @intFromPtr(surface) == 0;
  if (!surface_null) {
    // Convert surface if needed
    if (surface.format != sdl.SDL_PIXELFORMAT_RGBA8888 and surface.format != sdl.SDL_PIXELFORMAT_BGRA8888) {
      const converted = sdl.SDL_ConvertSurface(surface, sdl.SDL_PIXELFORMAT_RGBA8888);
      sdl.SDL_DestroySurface(surface);
      surface = converted;
      surface_null = @intFromPtr(converted) == 0;
    }

    if (!surface_null) {
      // Recreate texture if dimensions changed
      if (surface.w != converted_texture_width or surface.h != converted_texture_height) {
        sdl.SDL_DestroyTexture(converted_texture);
        converted_texture = sdl.SDL_CreateTexture(
          renderer,
          sdl.SDL_PIXELFORMAT_RGBA8888,
          sdl.SDL_TEXTUREACCESS_STREAMING,
          surface.w,
          surface.h
        );

        const converted_texture_null: bool = @intFromPtr(converted_texture) == 0;
        if (converted_texture_null) {
          sdl.SDL_Log("Couldn't (re)create conversion texture: %s", sdl.SDL_GetError());
          return sdl.SDL_APP_FAILURE;
        }
        converted_texture_width = surface.w;
        converted_texture_height = surface.h;
      }

      const surface_pixels: [*]u8 = @ptrCast(surface.pixels.?);
      const surface_pixels_ptr: usize = @intFromPtr(&surface_pixels[0]);
      var y: usize = 0;
      while (y < surface.h) : (y += 1) {
        const pixels: [*]u32 = @ptrFromInt(surface_pixels_ptr + y * @as(usize, @intCast(surface.pitch)));
        var x: usize = 0;
        while (x < surface.w) : (x += 1) {
          var p = std.mem.asBytes(&pixels[x]);
          const average = (@as(u32, p[1]) + @as(u32, p[2]) + @as(u32, p[3])) / 3;
          if (average == 0) {
            p[0] = 0xFF;
            p[1] = 0;
            p[2] = 0;
            p[3] = 0xFF;   // Make pure black pixels red
          } else {
            const value: u8 = if (average > 50) 0xFF else 0x00;
            p[1] = value;
            p[2] = value;
            p[3] = value;  // Make everything else either black or white
          }
        }
      }

      // Update texture with processed pixels
      _ = sdl.SDL_UpdateTexture(converted_texture, null, surface.pixels, surface.pitch);
      _ = sdl.SDL_DestroySurface(surface);

      // Render the processed texture to the top-left corner
      dst_rect = sdl.SDL_FRect{ 
        .x = 0, 
        .y = 0, 
        .w = WINDOW_WIDTH / 4.0, 
        .h = WINDOW_HEIGHT / 4.0 };
      _ = sdl.SDL_RenderTexture(renderer, converted_texture, null, &dst_rect);
    }
  }

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

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================