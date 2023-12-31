const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;

pub const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  @cInclude("lib/SDL3/include/SDL.h");
});

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hInstance;
  _ = hPrevInstance;
  _ = pCmdLine;
  _ = nCmdShow;

  _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
  var window: *(sdl.SDL_Window) = sdl.SDL_CreateWindow("GAME", 1280, 720, 0).?;
  defer sdl.SDL_DestroyWindow(window);

  win.Sleep(3000);

  return 0;    
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}
