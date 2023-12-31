const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
  usingnamespace std.os.windows.gdi32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

var g_width: i32 = 1280;
var g_height: i32 = 720;

var wnd: win.HWND = undefined;
const wnd_title = L("BaseWin");
const wnd_classname = wnd_title ++ L("_class");
var wnd_size: win.RECT = .{ .left=0, .top=0, .right=1280, .bottom=720 };
var wnd_dc: win.HDC = undefined;
var wnd_dpi: win.UINT = 96;
var wnd_color: COLORREF = 0x001E1E1E;  //0x00RRGGBB;

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  CreateWindow(hInstance, nCmdShow);
  defer _ = win.ReleaseDC(wnd, wnd_dc);
  defer _ = win.DestroyWindow(wnd);
  defer _ = win.UnregisterClassW(wnd_title, hInstance);

  var done: bool = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done) {
    while (win.PeekMessageW(&msg, null, 0, 0, win.PM_REMOVE) != 0) {
      _ = win.TranslateMessage(&msg);
      _ = win.DispatchMessageW(&msg);
      if (msg.message == win.WM_QUIT) { done = true; }
    }
    if (done) break;

  }

  return 0;
}


fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  switch (uMsg) {
    win.WM_DESTROY,
    win.WM_CLOSE => {
      win.PostQuitMessage(0);
      return 0;
    },
    win.WM_PAINT => {
      _ = BeginPaint(hWnd, &ps).?;
      _ = FillRect(wnd_dc, &ps.rcPaint, CreateSolidBrush(wnd_color));
      _ = EndPaint(hWnd, &ps);
      return 0;
    },
    win.WM_SIZE => {
      g_width = @as(i32, @intCast(LOWORD(lParam)));
      g_height = @as(i32, @intCast(HIWORD(lParam)));
      _ = PostMessageW(hWnd, win.WM_PAINT, 0, 0);
      return 0;
    },
		win.WM_KEYDOWN,
		win.WM_SYSKEYDOWN => {
			switch (wParam) {
				VK_ESCAPE => { //SHIFT+ESC = EXIT
					if (GetAsyncKeyState(VK_LSHIFT) & 0x01 == 1) {
						win.PostQuitMessage(0);
						return 0;
					}
        },
        else => {}
      }
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
    .lpszClassName = wnd_classname,
    .hIconSm = null,
  };
  _ = win.RegisterClassExW(&wnd_class);
  _ = win.AdjustWindowRectEx(&wnd_size, win.WS_OVERLAPPEDWINDOW, win.FALSE, win.WS_EX_APPWINDOW);

  wnd = win.CreateWindowExW(
    win.WS_EX_APPWINDOW, wnd_classname, wnd_title, win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
    win.CW_USEDEFAULT, win.CW_USEDEFAULT, 0, 0, null, null, hInstance, null).?;

  wnd_dc = win.GetDC(wnd).?;
  wnd_dpi = GetDpiForWindow(wnd);
  var xCenter = @divFloor(GetSystemMetricsForDpi(SM_CXSCREEN, wnd_dpi), 2);
  var yCenter = @divFloor(GetSystemMetricsForDpi(SM_CYSCREEN, wnd_dpi), 2);
  const div_w = @divFloor(wnd_size.right, 2);
  const div_h = @divFloor(wnd_size.bottom, 2);
  wnd_size.left = xCenter - div_w;
  wnd_size.top  = yCenter - div_h;
  wnd_size.right = wnd_size.left + div_w;
  wnd_size.bottom = wnd_size.top + div_h;
  _ = SetWindowPos( wnd, null, wnd_size.left, wnd_size.top, wnd_size.right, wnd_size.bottom, SWP_NOCOPYBITS );

  _ = win.ShowWindow(wnd, nCmdShow);
  _ = win.updateWindow(wnd) catch undefined;
}


// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}


pub fn LOWORD(l: win.LONG_PTR) win.UINT { return @as(u32, @intCast(l)) & 0xFFFF; }
pub fn HIWORD(l: win.LONG_PTR) win.UINT { return (@as(u32, @intCast(l)) >> 16) & 0xFFFF; }

pub const VK_ESCAPE = 27;
pub const VK_LSHIFT = 160;

pub const COLOR_WINDOW = 5;
pub var ps: PAINTSTRUCT = undefined;
pub const PAINTSTRUCT = extern struct {
  hdc: win.HDC,
  fErase: win.BOOL,
  rcPaint: win.RECT,
  fRestore: win.BOOL,
  fIncUpdate: win.BOOL,
  rgbReserved: [32]win.BYTE
};

pub extern "user32" fn BeginPaint(
  hWnd: ?win.HWND,
  lpPaint: ?*PAINTSTRUCT,
) callconv(WINAPI) ?win.HDC;

pub const COLORREF = win.DWORD;
pub extern "gdi32" fn CreateSolidBrush(
  color: COLORREF
) callconv(WINAPI) win.HBRUSH;

pub extern "user32" fn FillRect(
  hDC: ?win.HDC,
  lprc: ?*const win.RECT,
  hbr: ?win.HBRUSH
) callconv(WINAPI) win.INT;

pub extern "user32" fn EndPaint(
  hWnd: win.HWND,
  lpPaint: *const PAINTSTRUCT
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn TextOutW(
  hDC: ?win.HDC,
  x: win.INT,
  y: win.INT,
  lpString: win.LPCWSTR,
  c: win.INT
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn GetAsyncKeyState(
  nKey: c_int
) callconv(WINAPI) win.INT;

pub const IDC_ARROW: win.LONG = 32512;
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

pub extern "user32" fn PostMessageW(
  hWnd: ?win.HWND,
  Msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(WINAPI) win.BOOL;
