//!zig-autodoc-section: BaseWinEX
//!  Template for a Windows program, Windows API as submodule.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const win = @import("winapi.zig");
var wnd: win.wnd_type = undefined;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  _ = &hPrevInstance; _ = &pCmdLine;

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
    while (win.PeekMessageA(&msg, null, 0, 0, win.PM_REMOVE) != 0) {
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