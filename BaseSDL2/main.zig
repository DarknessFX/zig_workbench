//!zig-autodoc-section: BaseSDL2\\main.zig
//! main.zig :
//!  Template using SDL2 framework.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const win = std.os.windows;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseSDL2/lib/SDL2/include/SDL.h");
pub const sdl = @cImport({
  @cInclude("SDL.h");
});
//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  _ = hInstance;
  _ = hPrevInstance;
  _ = pCmdLine;
  _ = nCmdShow;

  _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
  const window: *(sdl.SDL_Window) = sdl.SDL_CreateWindow(
    "GAME", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 1024, 768, 0)
    orelse undefined;
  defer sdl.SDL_DestroyWindow(window);

  win.kernel32.Sleep(3000);

  return 0;    
}
//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}
//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================



//#endregion ==================================================================
//=============================================================================