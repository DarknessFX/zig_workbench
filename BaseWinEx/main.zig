//!zig-autodoc-section: BaseWinEx.Main
//! BaseWinEx\\main.zig :
//!   Template for a Windows program, Windows API as submodule.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const Io = std.Io;
const win = @import("winapi.zig");
var wnd: win.wnd_type = undefined;
var appinit: std.process.Init = undefined;

const print = std.debug.print;
/// Print line directly when text don't need formating.
inline fn printLine(line: []const u8) void { print("{s}\n", .{ line }); }

const log = std.log.info;
/// Log line directly when text don't need formating.
inline fn logLine(line: []const u8) void { log("{s}\n", .{ line }); }

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE,
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  _ = hPrevInstance; _ = pCmdLine;

  win.CreateWindow("BaseWinEx", hInstance, nCmdShow);
  defer win.Destroy();

  wnd = win.wnd;

  win.ShowWindow(wnd.hWnd, nCmdShow);
  _ = win.UpdateWindow(wnd.hWnd);

  MainLoop();

  return 0;
}

fn MainLoop() void {
  var done = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done) {
    while (win.PeekMessageA(&msg, null, 0, 0, win.PM_REMOVE) != win.BOOL.FALSE) {
      _ = win.TranslateMessage(&msg);
      _ = win.DispatchMessageA(&msg);
      if (msg.message == win.WM_QUIT) { done = true; }
    }
    if (done) break;

    _ = win.WaitMessage();
  }
}


//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
// Fix for libc linking error.
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  return wWinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================
test " " {
}


//#endregion ==================================================================
//=============================================================================
