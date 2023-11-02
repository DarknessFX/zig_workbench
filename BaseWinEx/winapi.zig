pub const win = @This();
const std = @import("std");

pub usingnamespace std.os.windows;
pub usingnamespace std.os.windows.user32;
pub usingnamespace std.os.windows.kernel32;
pub usingnamespace std.os.windows.gdi32;

const WINAPI = std.os.windows.WINAPI;
pub const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub const wnd_type = struct {
  hWnd: win.HWND,
  name: [*:0]const u16,
  classname: [*:0]const u16,
  size: struct {
    width: i16,
    height: i16
  },
  pos: win.RECT,
  hdc: win.HDC,
  dpi: win.UINT
};

pub var wnd: wnd_type = .{
  .hWnd = undefined,
  .name = undefined,
  .classname = undefined,
  .size = .{
    .width = 1280,
    .height = 720
  },
  .pos = .{
    .left = 0,
    .top = 0,
    .right = 1280,
    .bottom = 720
  },
  .hdc = undefined,
  .dpi = 96
};

pub fn CreateWindow(comptime title: []const u8, hInstance: win.HINSTANCE, nCmdShow: win.INT) void {
  _ = nCmdShow;

  wnd.name = L(title);
  wnd.classname = L(title) ++ L("_class");
  const wnd_class: win.WNDCLASSEXW = .{
    .cbSize = @sizeOf(win.WNDCLASSEXW),
    .style = win.CS_CLASSDC | win.CS_HREDRAW | win.CS_VREDRAW,
    .lpfnWndProc = WindowProc,
    .cbClsExtra = 0, 
    .cbWndExtra = 0,
    .hInstance = hInstance,
    .hIcon = null, 
    .hCursor = LoadCursorW(null, win.IDC_ARROW),
    .hbrBackground = null, 
    .lpszMenuName = null,
    .lpszClassName = wnd.classname,
    .hIconSm = null,
  };

  _ = win.RegisterClassExW(&wnd_class);

  wnd.hWnd = win.CreateWindowExW(
    0, wnd.classname, wnd.name, win.WS_OVERLAPPEDWINDOW,
    win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
    null, null, hInstance, null) orelse undefined;
}

pub fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  switch (uMsg) {
    win.WM_DESTROY => {
      win.PostQuitMessage(0);
      return 0;
    },
    win.WM_PAINT => {
      const hdc: win.HDC = BeginPaint(hWnd, &ps) orelse undefined;
      _ = FillRect(hdc, &ps.rcPaint, @ptrFromInt(COLOR_WINDOW+1));
      _ = EndPaint(hWnd, &ps);
    },
    win.WM_SIZE => {
      wnd.size.width = @as(i16, @intCast(LOWORD(lParam)));
      wnd.size.height = @as(i16, @intCast(HIWORD(lParam)));
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

pub extern "user32" fn WaitMessage(
) callconv(WINAPI) win.BOOL;

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
