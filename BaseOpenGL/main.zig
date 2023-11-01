// Port from https://www.opengl.org/archives/resources/code/samples/win32_tutorial/animate.c
// An example of an OpenGL animation loop using the Win32 API. Also
// demonstrates palette management for RGB and color index modes and
// general strategies for message handling.

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
var wnd_palette: HPALETTE = undefined;

var gl_HWND: gl.HWND = undefined;
var gl_HDC : gl.HDC = undefined;
var gl_RC : gl.HGLRC = undefined;

var gl_anim: gl.GLboolean = gl.GL_TRUE;
var gl_buffer: c_int = gl.PFD_DOUBLEBUFFER;
var gl_coloridx: c_int = gl.PFD_TYPE_RGBA;

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  wnd = CreateWindowOpenGL(hInstance, 0, 0, g_width, g_height, gl_coloridx, gl_buffer).?;
  defer _ = win.ReleaseDC(wnd, wnd_dc);
  defer _ = win.DestroyWindow(wnd);
  defer _ = win.UnregisterClassW(wnd_classname, hInstance);

  @setRuntimeSafety(false);
  gl_HWND = @as(gl.HWND, @alignCast(@ptrCast(wnd)));
  @setRuntimeSafety(true);

  gl_HDC = gl.GetDC(gl_HWND);
  gl_RC = gl.wglCreateContext(gl_HDC);
  defer _ = gl.wglDeleteContext(gl_RC);
  _ = gl.wglMakeCurrent(gl_HDC, gl_RC);
  defer _ = gl.wglMakeCurrent(null, null);

  _ = win.ShowWindow(wnd, nCmdShow);
  _ = win.UpdateWindow(wnd);

  var done: bool = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done) {
    while (win.PeekMessageW(&msg, null, 0, 0, win.PM_REMOVE) != 0) {
      _ = win.TranslateMessage(&msg);
      _ = win.DispatchMessageW(&msg);
      if (msg.message == win.WM_QUIT) { done = true; }
    }
    if (done) break;

    glDisplay();
  }

  if (wnd_palette != undefined) { 
    _ = DeleteObject(ToWinObj(HGDIOBJ, &wnd_palette)); }

  return 0;
}

fn glDisplay() void {
  gl.glClear(gl.GL_COLOR_BUFFER_BIT);
  if (gl_anim == gl.GL_TRUE) {
    gl.glRotatef(1.0, 0.0, 0.0, 1.0); }
  gl.glBegin(gl.GL_TRIANGLES);
  gl.glIndexi(1);
  gl.glColor3f(1.0, 0.0, 0.0);
  gl.glVertex2i(0,  1);
  gl.glIndexi(2);
  gl.glColor3f(0.0, 1.0, 0.0);
  gl.glVertex2i(-1, -1);
  gl.glIndexi(3);
  gl.glColor3f(0.0, 0.0, 1.0);
  gl.glVertex2i(1, -1);
  gl.glEnd();
  gl.glFlush();
  _ = win.SwapBuffers(wnd_dc);
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
    win.WM_ACTIVATE => {
      if (IsIconic(wnd) != 0) {
        gl_anim = gl.GL_FALSE;
      } else {
        gl_anim = gl.GL_TRUE;
      }
    },
    win.WM_PALETTECHANGED,
    win.WM_QUERYNEWPALETTE => {
      if (wnd_palette != undefined) {
        _ = UnrealizeObject(ToWinObj(HGDIOBJ, &wnd_palette));
        _ = SelectPalette(wnd_dc, ToWinObj(HPALETTE, &wnd_palette), win.FALSE);
        _ = RealizePalette(wnd_dc);
        return 1;
      }
      return 0;
    },
    else => {},
  }

  return win.DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

fn CreateWindowOpenGL(hInstance: win.HINSTANCE, x: c_int, y: c_int, 
  width: c_int, height: c_int, pxtype: c_int , flags: c_int
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
  pfd.iPixelType = @as(u8, @intCast(pxtype));
  pfd.cColorBits = 32;

  const pf = win.ChoosePixelFormat(wnd_dc, &pfd);
  if (pf == 0) { return null; }
  if (win.SetPixelFormat(wnd_dc, pf, &pfd) == false) { return null; }

  _ = DescribePixelFormat(wnd_dc, pf, pfd_size, &pfd);

  var lpPal: LOGPALETTE = undefined;
  lpPal.palVersion = 0x300;
  lpPal.palNumEntries = 4;
  lpPal.palPalEntry[0].peRed = 0;
  lpPal.palPalEntry[0].peGreen = 0;
  lpPal.palPalEntry[0].peBlue = 0;
  lpPal.palPalEntry[0].peFlags = gl.PC_NOCOLLAPSE;
  lpPal.palPalEntry[1].peRed = 255;
  lpPal.palPalEntry[1].peGreen = 0;
  lpPal.palPalEntry[1].peBlue = 0;
  lpPal.palPalEntry[1].peFlags = gl.PC_NOCOLLAPSE;
  lpPal.palPalEntry[2].peRed = 0;
  lpPal.palPalEntry[2].peGreen = 255;
  lpPal.palPalEntry[2].peBlue = 0;
  lpPal.palPalEntry[2].peFlags = gl.PC_NOCOLLAPSE;
  lpPal.palPalEntry[3].peRed = 0;
  lpPal.palPalEntry[3].peGreen = 0;
  lpPal.palPalEntry[3].peBlue = 255;
  lpPal.palPalEntry[3].peFlags = gl.PC_NOCOLLAPSE;

  var new_palette = CreatePalette(&lpPal).?;
  wnd_palette = SelectPalette(wnd_dc, new_palette, win.FALSE);
  _ = RealizePalette(wnd_dc);
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

pub extern "user32" fn IsIconic(
  hWnd: win.HWND,
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn DescribePixelFormat(
  hDC: win.HDC,
  iPixelFormat: win.INT,
  nBytes: win.UINT,
  ppfd: *win.PIXELFORMATDESCRIPTOR,
) callconv(WINAPI) win.INT;

pub fn ToWinObj(comptime T: type, obj: anytype) T {
  return @as(T, @ptrCast(obj.*));
}
pub const HGDIOBJ = *opaque{};
pub const HPALETTE = *opaque{};
pub extern "gdi32" fn DeleteObject(
  ho: HGDIOBJ
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn UnrealizeObject(
  ho: HGDIOBJ
) callconv(WINAPI) win.BOOL;

pub extern "gdi32" fn RealizePalette(
  hdc: win.HDC
) callconv(WINAPI) win.UINT;

pub extern "gdi32" fn SelectPalette(
  hdc: win.HDC,
  hPal: HPALETTE,
  bForceBkgd: win.BOOL
) callconv(WINAPI) HPALETTE;

const PALETTEENTRY = struct {
  peRed: win.BYTE,
  peGreen: win.BYTE,
  peBlue: win.BYTE,
  peFlags: win.BYTE
};
const LOGPALETTE = struct {
  palVersion: win.WORD,
  palNumEntries : win.WORD,
  palPalEntry: [4]PALETTEENTRY
};

pub extern "gdi32" fn CreatePalette(
  plpal: *LOGPALETTE
) callconv(WINAPI) ?HPALETTE;
