//!zig-autodoc-section: BaseOpenGL.Main
//! BaseOpenGL//main.zig :
//!   Template using OpenGL and Windows GDI.
// Build using Zig 0.15.1

// Port from https://www.opengl.org/archives/resources/code/samples/win32_tutorial/animate.c
// An example of an OpenGL animation loop using the Win32 API. Also
// demonstrates palette management for RGB and color index modes and
// general strategies for message handling.

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const win = std.os.windows;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseOpenGL/lib/opengl/gl.h");
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
var wnd_palette: ?HPALETTE = null;

var gl_HWND: gl.HWND = undefined;
var gl_HDC : gl.HDC = undefined;
var gl_RC : gl.HGLRC = undefined;

var gl_anim: gl.GLboolean = gl.GL_TRUE;
var gl_buffer: c_int = gl.PFD_DOUBLEBUFFER;
var gl_coloridx: c_int = gl.PFD_TYPE_RGBA;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  wnd = CreateWindowOpenGL(hInstance, 0, 0, g_width, g_height, gl_coloridx, gl_buffer).?;
  defer _ = ReleaseDC(wnd, wnd_dc);
  defer _ = DestroyWindow(wnd);
  defer _ = UnregisterClassW(wnd_classname, hInstance);

  @setRuntimeSafety(false);
  gl_HWND = @as(gl.HWND, @alignCast(@ptrCast(wnd)));
  @setRuntimeSafety(true);

  gl_HDC = gl.GetDC(gl_HWND);
  gl_RC = gl.wglCreateContext(gl_HDC);
  defer _ = gl.wglDeleteContext(gl_RC);
  _ = gl.wglMakeCurrent(gl_HDC, gl_RC);
  defer _ = gl.wglMakeCurrent(null, null);

  _ = ShowWindow(wnd, nCmdShow);
  _ = UpdateWindow(wnd);

  var done: bool = false;
  var msg: MSG = std.mem.zeroes(MSG);
  while (!done) {
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
      _ = TranslateMessage(&msg);
      _ = DispatchMessageW(&msg);
      if (msg.message == WM_QUIT) { done = true; }
    }
    if (done) break;

    glDisplay();
  }

  if (wnd_palette != null) { 
    _ = DeleteObject(ToWinObj(HGDIOBJ, &wnd_palette)); }

  return 0;
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

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
  _ = SwapBuffers(wnd_dc);
}

fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(.winapi) win.LRESULT {
  switch (uMsg) {
    WM_DESTROY,
    WM_CLOSE => {
      PostQuitMessage(0);
      return 0;
    },
    WM_PAINT => {
      glDisplay();
      _ = BeginPaint(hWnd, &ps).?;
      _ = EndPaint(hWnd, &ps);
      return 0;
    },
    WM_SIZE => {
      g_width = @as(i32, @intCast(LOWORD(lParam)));
      g_height = @as(i32, @intCast(HIWORD(lParam)));
      gl.glViewport(0, 0, @as(gl.GLsizei , g_width), @as(gl.GLsizei , g_height));
      _ = PostMessageW(hWnd, WM_PAINT, 0, 0);
      return 0;
    },
		WM_KEYDOWN,
		WM_SYSKEYDOWN => {
			switch (wParam) {
				VK_ESCAPE => { //SHIFT+ESC = EXIT
					if (GetAsyncKeyState(VK_LSHIFT) & 0x01 == 1) {
						PostQuitMessage(0);
						return 0;
					}
        },
        else => {}
      }
    },
    WM_ACTIVATE => {
      if (IsIconic(wnd) != 0) {
        gl_anim = gl.GL_FALSE;
      } else {
        gl_anim = gl.GL_TRUE;
      }
    },
    WM_PALETTECHANGED,
    WM_QUERYNEWPALETTE => {
      if (wnd_palette != null) {
        _ = UnrealizeObject(ToWinObj(HGDIOBJ, &wnd_palette));
        _ = SelectPalette(wnd_dc, ToWinObj(HPALETTE, &wnd_palette), win.FALSE);
        _ = RealizePalette(wnd_dc);
        return 1;
      }
      return 0;
    },
    else => {},
  }

  return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

fn CreateWindowOpenGL(hInstance: win.HINSTANCE, x: c_int, y: c_int, 
  width: c_int, height: c_int, pxtype: c_int , flags: c_int
  ) ?win.HWND {

  const wnd_class: WNDCLASSEXW = .{
    .cbSize = @sizeOf(WNDCLASSEXW),
    .style = CS_OWNDC,
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
  _ = RegisterClassExW(&wnd_class);

  wnd = CreateWindowExW(
    0, wnd_classname, wnd_title,
    WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN, 
    x, y, width, height, null, null, hInstance, null).?;

  wnd_dc = GetDC(wnd).?;

  var pfd: PIXELFORMATDESCRIPTOR = std.mem.zeroes(PIXELFORMATDESCRIPTOR);
  const pfd_size = @sizeOf(PIXELFORMATDESCRIPTOR);
  pfd.nSize = pfd_size;
  pfd.nVersion = 1;
  pfd.dwFlags = @as(u32, @intCast(gl.PFD_DRAW_TO_WINDOW | gl.PFD_SUPPORT_OPENGL | flags));
  pfd.iPixelType = @as(u8, @intCast(pxtype));
  pfd.cColorBits = 32;

  const pf = ChoosePixelFormat(wnd_dc, &pfd);
  if (pf == 0) { return null; }
  if (SetPixelFormat(wnd_dc, pf, &pfd) == false) { return null; }

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

  const new_palette = CreatePalette(&lpPal).?;
  wnd_palette = SelectPalette(wnd_dc, new_palette, win.FALSE);
  _ = RealizePalette(wnd_dc);
  _ = ReleaseDC(wnd, wnd_dc);

  return wnd;
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}

fn LOWORD(l: win.LONG_PTR) win.UINT { return @as(u32, @intCast(l)) & 0xFFFF; }
fn HIWORD(l: win.LONG_PTR) win.UINT { return (@as(u32, @intCast(l)) >> 16) & 0xFFFF; }

//#endregion ==================================================================
//#region MARK: CONST
//=============================================================================
const VK_ESCAPE = 27;
const VK_LSHIFT = 160;
const PM_REMOVE = 0x0001;
const WM_QUIT = 0x0012;
const IDC_ARROW: win.LONG = 32512;
const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
const CS_DBLCLKS = 0x0008;
const CS_OWNDC = 0x0020;
const CS_VREDRAW = 0x0001;
const CS_HREDRAW = 0x0002;
const CS_CLASSDC = 0x0040;
const WS_OVERLAPPED = 0x00000000;
const WS_POPUP = 0x80000000;
const WS_CHILD = 0x40000000;
const WS_MINIMIZE = 0x20000000;
const WS_VISIBLE = 0x10000000;
const WS_DISABLED = 0x08000000;
const WS_CLIPSIBLINGS = 0x04000000;
const WS_CLIPCHILDREN = 0x02000000;
const WS_MAXIMIZE = 0x01000000;
const WS_CAPTION = WS_BORDER | WS_DLGFRAME;
const WS_BORDER = 0x00800000;
const WS_DLGFRAME = 0x00400000;
const WS_VSCROLL = 0x00200000;
const WS_HSCROLL = 0x00100000;
const WS_SYSMENU = 0x00080000;
const WS_THICKFRAME = 0x00040000;
const WS_GROUP = 0x00020000;
const WS_TABSTOP = 0x00010000;
const WS_MINIMIZEBOX = 0x00020000;
const WS_MAXIMIZEBOX = 0x00010000;
const WS_TILED = WS_OVERLAPPED;
const WS_ICONIC = WS_MINIMIZE;
const WS_SIZEBOX = WS_THICKFRAME;
const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
const WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU;
const WS_CHILDWINDOW = WS_CHILD;
const COLOR_WINDOW = 5;
const WM_DESTROY = 0x0002;
const WM_CLOSE = 0x0010;
const WM_PAINT = 0x000F;
const WM_SIZE = 0x0005;
const WM_KEYDOWN = 0x0100;
const WM_SYSKEYDOWN = 0x0104;
const WM_ACTIVATE = 0x0006;
const WM_PALETTECHANGED = 0x0311;
const WM_QUERYNEWPALETTE = 0x030F;

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

const WNDCLASSEXW = extern struct {
  cbSize: win.UINT = @sizeOf(WNDCLASSEXW),
  style: win.UINT,
  lpfnWndProc: WNDPROC,
  cbClsExtra: i32 = 0,
  cbWndExtra: i32 = 0,
  hInstance: win.HINSTANCE,
  hIcon: ?win.HICON,
  hCursor: ?win.HCURSOR,
  hbrBackground: ?HBRUSH,
  lpszMenuName: ?[*:0]const u16,
  lpszClassName: [*:0]const u16,
  hIconSm: ?win.HICON,
};

const WNDPROC = *const fn (
  hwnd: win.HWND, 
  uMsg: win.UINT, 
  wParam: win.WPARAM, 
  lParam: win.LPARAM
) callconv(.winapi) win.LRESULT;

//#endregion ==================================================================
//#region MARK: WNIAPI
//=============================================================================
extern "user32" fn RegisterClassExW(
  *const WNDCLASSEXW
) callconv(.winapi) win.ATOM;

extern "user32" fn CreateWindowExW(
  dwExStyle: win.DWORD,
  lpClassName: [*:0]const u16,
  lpWindowName: [*:0]const u16,
  dwStyle: win.DWORD,
  X: i32,
  Y: i32,
  nWidth: i32,
  nHeight: i32,
  hWindParent: ?win.HWND,
  hMenu: ?win.HMENU,
  hInstance: win.HINSTANCE,
  lpParam: ?win.LPVOID
) callconv(.winapi) ?win.HWND;

pub extern "user32" fn BeginPaint(
  hWnd: ?win.HWND,
  lpPaint: ?*PAINTSTRUCT,
) callconv(.winapi) ?win.HDC;

pub extern "user32" fn FillRect(
  hDC: ?win.HDC,
  lprc: ?*const win.RECT,
  hbr: ?HBRUSH
) callconv(.winapi) win.INT;

pub extern "user32" fn EndPaint(
  hWnd: win.HWND,
  lpPaint: *const PAINTSTRUCT
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn TextOutW(
  hDC: ?win.HDC,
  x: win.INT,
  y: win.INT,
  lpString: win.LPCWSTR,
  c: win.INT
) callconv(.winapi) win.BOOL;

pub extern "user32" fn GetAsyncKeyState(
  nKey: c_int
) callconv(.winapi) win.INT;

pub extern "user32" fn LoadCursorW(
  hInstance: ?win.HINSTANCE,
  lpCursorName: win.LONG,
) callconv(.winapi) win.HCURSOR;

//   _ = win.MessageBoxA(null, "Sample text.", "Title", win.MB_OK);
//  _ = OutputDebugStringA("\x1b[31mRed\x1b[0m");
pub extern "kernel32" fn OutputDebugStringA(
  lpOutputString: win.LPCSTR
) callconv(.winapi) win.INT;

pub extern "user32" fn GetWindowRect(
  hWnd: win.HWND,
  lpRect: *win.RECT
) callconv(.winapi) win.INT;

pub const SM_CXSCREEN = 0;
pub const SM_CYSCREEN = 1;
pub extern "user32" fn GetSystemMetricsForDpi(
  nIndex: win.INT,
  dpi: win.UINT
) callconv(.winapi) win.INT;

pub extern "user32" fn GetDpiForWindow(
  hWnd: win.HWND,
) callconv(.winapi) win.UINT;

pub const SWP_NOCOPYBITS = 0x0100;
pub extern "user32" fn SetWindowPos(
  hWnd: win.HWND,
  hWndInsertAfter: ?win.HWND,
  X: win.INT,
  Y: win.INT,
  cx: win.INT,
  cy: win.INT,
  uFlags: win.UINT,        
) callconv(.winapi) win.BOOL;

pub extern "user32" fn PostMessageW(
  hWnd: ?win.HWND,
  Msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(.winapi) win.BOOL;

pub extern "user32" fn IsIconic(
  hWnd: win.HWND,
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn DescribePixelFormat(
  hDC: win.HDC,
  iPixelFormat: win.INT,
  nBytes: win.UINT,
  ppfd: *PIXELFORMATDESCRIPTOR,
) callconv(.winapi) win.INT;

pub fn ToWinObj(comptime T: type, obj: anytype) T {
  return @as(T, @ptrCast(obj.*));
}
pub const HGDIOBJ = *opaque{};
pub const HPALETTE = *opaque{};
pub extern "gdi32" fn DeleteObject(
  ho: HGDIOBJ
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn UnrealizeObject(
  ho: HGDIOBJ
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn RealizePalette(
  hdc: win.HDC
) callconv(.winapi) win.UINT;

pub extern "gdi32" fn SelectPalette(
  hdc: win.HDC,
  hPal: HPALETTE,
  bForceBkgd: win.BOOL
) callconv(.winapi) HPALETTE;

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

extern "gdi32" fn CreatePalette(
  plpal: *LOGPALETTE
) callconv(.winapi) ?HPALETTE;

extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: win.INT
) callconv(.winapi) void;

extern "user32" fn UpdateWindow(
  hWnd: win.HWND
) callconv(.winapi) win.BOOL;

const MSG = extern struct {
  hWnd: ?win.HWND,
  message: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM,
  time: win.DWORD,
  pt: win.POINT,
  lPrivate: win.DWORD,
};

extern "user32" fn PeekMessageW(
  lpMsg: *MSG,
  hWnd: ?win.HWND, 
  wMsgFilterMin: win.UINT, 
  wMsgFilterMax: win.UINT, 
  wRemoveMsg: win.UINT
) callconv(.winapi) win.BOOL;

extern "user32" fn TranslateMessage(
  lpMsg: *const MSG
) callconv(.winapi) win.BOOL;

extern "user32" fn DispatchMessageW(
  lpMsg: *const MSG
) callconv(.winapi) win.LRESULT;

extern "user32" fn UnregisterClassW(
  lpClassName: [*:0]const u16, 
  hInstance: win.HINSTANCE
) callconv(.winapi) win.BOOL;

extern "user32" fn DestroyWindow(
  hWnd: win.HWND
) callconv(.winapi) win.BOOL;

extern "user32" fn GetDC(
  hWnd: ?win.HWND
) callconv(.winapi) ?win.HDC;

extern "user32" fn ReleaseDC(
  hWnd: ?win.HWND, 
  hDC: win.HDC
) callconv(.winapi) win.INT;

pub const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: win.WORD = @sizeOf(PIXELFORMATDESCRIPTOR),
    nVersion: win.WORD,
    dwFlags: win.DWORD,
    iPixelType: win.BYTE,
    cColorBits: win.BYTE,
    cRedBits: win.BYTE,
    cRedShift: win.BYTE,
    cGreenBits: win.BYTE,
    cGreenShift: win.BYTE,
    cBlueBits: win.BYTE,
    cBlueShift: win.BYTE,
    cAlphaBits: win.BYTE,
    cAlphaShift: win.BYTE,
    cAccumBits: win.BYTE,
    cAccumRedBits: win.BYTE,
    cAccumGreenBits: win.BYTE,
    cAccumBlueBits: win.BYTE,
    cAccumAlphaBits: win.BYTE,
    cDepthBits: win.BYTE,
    cStencilBits: win.BYTE,
    cAuxBuffers: win.BYTE,
    iLayerType: win.BYTE,
    bReserved: win.BYTE,
    dwLayerMask: win.DWORD,
    dwVisibleMask: win.DWORD,
    dwDamageMask: win.DWORD,
};

pub extern "gdi32" fn SetPixelFormat(
    hdc: ?win.HDC,
    format: win.INT,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(.winapi) bool;

pub extern "gdi32" fn ChoosePixelFormat(
    hdc: ?win.HDC,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(.winapi) win.INT;

pub extern "gdi32" fn SwapBuffers(hdc: ?win.HDC) callconv(.winapi) bool;
pub extern "gdi32" fn wglCreateContext(hdc: ?win.HDC) callconv(.winapi) ?win.HGLRC;
pub extern "gdi32" fn wglMakeCurrent(hdc: ?win.HDC, hglrc: ?win.HGLRC) callconv(.winapi) bool;
pub extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
pub extern "user32" fn DefWindowProcW(hWnd: win.HWND, Msg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) callconv(.winapi) win.LRESULT;

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================