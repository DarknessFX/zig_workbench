const std = @import("std");
const win = @import("winapi.zig");
const wnd = &win.wnd;

fn MainLoop() void {
  var done = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done) {
    while (win.PeekMessageW(&msg, null, 0, 0, win.PM_REMOVE) != 0) {
      _ = win.TranslateMessage(&msg);
      _ = win.DispatchMessageW(&msg);
      if (msg.message == win.WM_QUIT) { done = true; }
    }
    if (done) break;

    _ = win.WaitMessage();
  }
}


// WINDOWS API
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  win.CreateWindow("BaseWinEx", hInstance, nCmdShow);
  defer _ = win.UnregisterClassW(wnd.classname, hInstance);
  defer _ = win.DestroyWindow(wnd.hWnd);

  _ = win.ShowWindow(wnd.hWnd, nCmdShow);
  _ = win.updateWindow(wnd.hWnd) catch undefined;

  MainLoop();

  return 0;
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}