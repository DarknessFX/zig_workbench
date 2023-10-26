/ NOTE: Change .vscode/Tasks.json replacing 
//  FROM "run", "main.zig"
//  TO   "run", "-lc", "-lSDL2", "-L lib/SDL2", "-I lib/SDL2/include", "main.zig"
// REASON: Project depends of -lc (libc) and to inform Zig Run
//         where to find the .H and .LIB

const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;

pub const sdl = @cImport({
  // NOTE: Need full path to SDL2/include
  @cInclude("SDL.h");
});

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hInstance;
  _ = hPrevInstance;
  _ = pCmdLine;
  _ = nCmdShow;

  _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
  var window: *(sdl.SDL_Window) = sdl.SDL_CreateWindow(
    "GAME", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 1024, 768, 0)
    orelse undefined;
  defer sdl.SDL_DestroyWindow(window);

  win.Sleep(3000);

  return 0;    
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}
