// Port from https://www.opengl.org/archives/resources/code/samples/win32_tutorial/minimal.c
// An example of the minimal Win32 & OpenGL program.  It only works in
// 16 bit color modes or higher (since it doesn't create a
// palette).

const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
  usingnamespace std.os.windows.gdi32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

const gl = @cImport({
  @cInclude("lib/opengl/gl.h");
  @cInclude("lib/opengl/glu.h");
});

var g_width: i32 = 1280;
var g_height: i32 = 720;

var wnd: win.HWND = undefined;
const wnd_title = L("BaseOpenGL");
const wnd_classname = wnd_title ++ L("_class");
var wnd_size: win.RECT = .{ .left=0, .top=0, .right=1280, .bottom=720 };
var wnd_dc: win.HDC = undefined;
var wnd_dpi: win.UINT = 96;

var gl_HWND: gl.HWND = undefined;
var gl_HDC : gl.HDC = undefined;
var gl_RC : gl.HGLRC = undefined;

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  wnd = CreateWindowOpenGL(hInstance, 0, 0, g_width, g_height, gl.PFD_TYPE_RGBA, 0).?;
  defer _ = gl.wglMakeCurrent(null, null);
  defer _ = win.ReleaseDC(wnd, wnd_dc);
  defer _ = gl.wglDeleteContext(gl_RC);
  defer _ = win.DestroyWindow(wnd);
  defer _ = win.UnregisterClassW(wnd_classname, hInstance);

  @setRuntimeSafety(false);
  gl_HWND = @as(gl.HWND, @alignCast(@ptrCast(wnd)));
  @setRuntimeSafety(true);
  gl_HDC = gl.GetDC(gl_HWND);
  gl_RC = gl.wglCreateContext(gl_HDC);
  _ = gl.wglMakeCurrent(gl_HDC, gl_RC);
  _ = win.ShowWindow(wnd, nCmdShow);

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

fn glDisplay() void {
  gl.glClear(gl.GL_COLOR_BUFFER_BIT);
  gl.glBegin(gl.GL_TRIANGLES);
  gl.glColor3f(1.0, 0.0, 0.0);
  gl.glVertex2i(0,  1);
  gl.glColor3f(0.0, 1.0, 0.0);
  gl.glVertex2i(-1, -1);
  gl.glColor3f(0.0, 0.0, 1.0);
  gl.glVertex2i(1, -1);
  gl.glEnd();
  gl.glFlush();
}

fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  switch (uMsg) {
    win.WM_DESTROY,
    win.WM_CLOSE => {
      win.PostQuitMessage(0);
      return 0;
    },
    win.WM_PAINT => {
      glDisplay();
      _ = BeginPaint(hWnd, &ps).?;
      _ = EndPaint(hWnd, &ps);
      return 0;
    },
    win.WM_SIZE => {
      g_width = @as(i32, @intCast(LOWORD(lParam)));
      g_height = @as(i32, @intCast(HIWORD(lParam)));
      gl.glViewport(0, 0, @as(gl.GLsizei , g_width), @as(gl.GLsizei , g_height));
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

fn CreateWindowOpenGL(hInstance: win.HINSTANCE, x: c_int, y: c_int, 
  width: c_int, height: c_int, pxtype: win.BYTE , flags: c_int
  ) ?win.HWND {

  const wnd_class: win.WNDCLASSEXW = .{
    .cbSize = @sizeOf(win.WNDCLASSEXW),
    .style = win.CS_OWNDC,
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

  wnd = win.CreateWindowExW(
    0, wnd_classname, wnd_title,
    win.WS_OVERLAPPEDWINDOW | win.WS_CLIPSIBLINGS | win.WS_CLIPCHILDREN, 
    x, y, width, height, null, null, hInstance, null).?;

  wnd_dc = win.GetDC(wnd).?;

  var pfd: win.PIXELFORMATDESCRIPTOR = std.mem.zeroes(win.PIXELFORMATDESCRIPTOR);
  const pfd_size = @sizeOf(win.PIXELFORMATDESCRIPTOR);
  pfd.nSize = pfd_size;
  pfd.nVersion = 1;
  pfd.dwFlags = @as(u32, @intCast(gl.PFD_DRAW_TO_WINDOW | gl.PFD_SUPPORT_OPENGL | flags));
  pfd.iPixelType = pxtype;
  pfd.cColorBits = 32;

  const pf = win.ChoosePixelFormat(wnd_dc, &pfd);
  if (pf == 0) { return null; }
  if (win.SetPixelFormat(wnd_dc, pf, &pfd) == false) { return null; }

  _ = DescribePixelFormat(wnd_dc, pf, pfd_size, &pfd);
  _ = win.ReleaseDC(wnd, wnd_dc);
  return wnd;
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}

fn LOWORD(l: win.LONG_PTR) win.UINT { return @as(u32, @intCast(l)) & 0xFFFF; }
fn HIWORD(l: win.LONG_PTR) win.UINT { return (@as(u32, @intCast(l)) >> 16) & 0xFFFF; }

const VK_ESCAPE = 27;
const VK_LSHIFT = 160;

const COLOR_WINDOW = 5;
pub const HBRUSH = *opaque{};
var ps: PAINTSTRUCT = undefined;
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

pub extern "user32" fn FillRect(
  hDC: ?win.HDC,
  lprc: ?*const win.RECT,
  hbr: ?HBRUSH
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

pub extern "user32" fn PostMessageW(
  hWnd: ?win.HWND,
  Msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn DescribePixelFormat(
  hDC: win.HDC,
  iPixelFormat: win.INT,
  nBytes: win.UINT,
  ppfd: *win.PIXELFORMATDESCRIPTOR,
) callconv(WINAPI) win.INT;