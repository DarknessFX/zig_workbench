const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
  usingnamespace std.os.windows.gdi32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

var wnd: win.HWND = undefined;
const wnd_title = L("BaseWin");
var wnd_size: win.RECT = .{ .left=0, .top=0, .right=800, .bottom=640 };
var wnd_dc: win.HDC = undefined;
var wnd_dpi: win.UINT = 72;

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  CreateWindow(hInstance, nCmdShow);
  defer _ = win.ReleaseDC(wnd, wnd_dc);
  defer _ = win.UnregisterClassW(wnd_title, hInstance);
  defer _ = win.DestroyWindow(wnd);

  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (win.GetMessageW(&msg, null, 0, 0) != 0) {
    _ = win.TranslateMessage(&msg);
    _ = win.DispatchMessageW(&msg);
  }

  return 0;
}


fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  switch (uMsg) {
    win.WM_DESTROY => {
      win.PostQuitMessage(0);
      return 0;
    },
    win.WM_PAINT => {
      var ps: PAINTSTRUCT = undefined;
      const hdc: HDC = BeginPaint(hWnd, &ps) orelse undefined;
      _ = FillRect(hdc, &ps.rcPaint, @ptrFromInt(COLOR_WINDOW+1));
      _ = EndPaint(hWnd, &ps);
    },
    else => _=.{},
  }

  return win.DefWindowProcW(hWnd, uMsg, wParam, lParam);
}


fn CreateWindow(hInstance: win.HINSTANCE, nCmdShow: win.INT) void {
  const wnd_class: win.WNDCLASSEXW = .{
    .cbSize = @sizeOf(win.WNDCLASSEXW),
    .style = win.CS_DBLCLKS,
    .lpfnWndProc = WindowProc,
    .cbClsExtra = 0, 
    .cbWndExtra = 0,
    .hInstance = hInstance,
    .hIcon = null, 
    .hCursor = LoadCursorW(null, IDC_ARROW),
    .hbrBackground = null, 
    .lpszMenuName = null,
    .lpszClassName = wnd_title,
    .hIconSm = null,
  };
  _ = win.RegisterClassExW(&wnd_class);

  _ = win.AdjustWindowRectEx(&wnd_size, win.WS_OVERLAPPEDWINDOW, win.FALSE, win.WS_EX_APPWINDOW);
  wnd = win.CreateWindowExW(
    win.WS_EX_APPWINDOW, wnd_title, wnd_title, win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
    win.CW_USEDEFAULT, win.CW_USEDEFAULT, 0, 0, 
    null, null, hInstance, null).?;

  var dpi = GetDpiForWindow(wnd);
  var xCenter = @divFloor(GetSystemMetricsForDpi(SM_CXSCREEN, dpi), 2);
  var yCenter = @divFloor(GetSystemMetricsForDpi(SM_CYSCREEN, dpi), 2);
  wnd_size.left = xCenter - @divFloor(wnd_size.right, 2);
  wnd_size.top  = yCenter - @divFloor(wnd_size.bottom, 2);
  _ = SetWindowPos( wnd, null, wnd_size.left, wnd_size.top, wnd_size.right, wnd_size.bottom, SWP_NOCOPYBITS );

  wnd_dc = win.GetDC(wnd).?;

  _ = win.ShowWindow(wnd, nCmdShow);
  _ = win.updateWindow(wnd) catch undefined;
}


// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}

const COLOR_WINDOW = 5;
pub const HDC = *opaque{};
pub const HBRUSH = *opaque{};
pub const PAINTSTRUCT = extern struct {
  hdc: HDC,
  fErase: win.BOOL,
  rcPaint: win.RECT,
  fRestore: win.BOOL,
  fIncUpdate: win.BOOL,
  rgbReserved: [32]win.BYTE
};

pub extern "user32" fn BeginPaint(
  hWnd: ?win.HWND,
  lpPaint: ?*PAINTSTRUCT,
) callconv(WINAPI) ?HDC;

pub extern "user32" fn FillRect(
  hDC: ?HDC,
  lprc: ?*const win.RECT,
  hbr: ?HBRUSH
) callconv(WINAPI) win.INT;

pub extern "user32" fn EndPaint(
  hWnd: win.HWND,
  lpPaint: *const PAINTSTRUCT
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn TextOutW(
  hDC: ?HDC,
  x: win.INT,
  y: win.INT,
  lpString: win.LPCWSTR,
  c: win.INT
) callconv(WINAPI) win.BOOL;

const IDC_ARROW: win.LONG = 32512;
pub extern "user32" fn LoadCursorW(
  hInstance: ?win.HINSTANCE,
  lpCursorName: win.LONG,
) callconv(WINAPI) win.HCURSOR;

//   _ = win.MessageBoxA(null, "Sample text.", "Title", win.MB_OK);
//  _ = OutputDebugStringA("\x1b[31mRed\x1b[0m");
pub extern "kernel32" fn OutputDebugStringA(
  lpOutputString: win.LPCSTR
) callconv(WINAPI) win.INT;

pub extern "user32" fn GetWindowRect(
  hWnd: win.HWND,
  lpRect: *win.RECT
) callconv(WINAPI) win.INT;

pub const SM_CXSCREEN = 0;
pub const SM_CYSCREEN = 1;
pub extern "user32" fn GetSystemMetricsForDpi(
  nIndex: win.INT,
  dpi: win.UINT
) callconv(WINAPI) win.INT;

pub extern "user32" fn GetDpiForWindow(
  hWnd: win.HWND,
) callconv(WINAPI) win.UINT;

pub const SWP_NOCOPYBITS = 0x0100;
pub extern "user32" fn SetWindowPos(
  hWnd: win.HWND,
  hWndInsertAfter: ?win.HWND,
  X: win.INT,
  Y: win.INT,
  cx: win.INT,
  cy: win.INT,
  uFlags: win.UINT,        
) callconv(WINAPI) win.BOOL;
