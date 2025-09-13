//!zig-autodoc-section: BaseMicroui.Main
//! BaseMicroui//main.zig :
//!  Template using Microui and Windows GDI.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const win = std.os.windows;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_microui/lib/SDL2/include/SDL.h"); 
//
// Verify other .ZIG files, there are cInclude too that need full path.
//
pub const mu =  @import("microui.zig").mu;

// Demos:
//   gui_min.zig - minimal window with one button.
//const gui = @import("gui_min.zig");
//
//   gui_demo.zig - microui default SDL2 demo sample.
const gui = @import("gui.zig");

var wnd: win.HWND = undefined;
var hFont: ?HFONT = undefined;
var mHDC: win.HDC = undefined;
var mBDC: win.HDC = undefined;
var Client_Rect: win.RECT = undefined;
var mPS: PAINTSTRUCT = undefined;
var mBitmap: HBITMAP = undefined;

var ctx: *mu.mu_Context = undefined;

var width: c_int = 1024;
var height: c_int = 768;

var buf_idx: c_int = 0;
var bg: [3]c_int = [3]c_int { 50, 50, 50 };


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  const wnd_name = L("microui_GDI");
  const class_name = wnd_name;
  const wnd_class: WNDCLASSEXW = .{
    .cbSize = @sizeOf(WNDCLASSEXW),
    .style = CS_CLASSDC | CS_HREDRAW | CS_VREDRAW,
    .lpfnWndProc = WindowProc,
    .cbClsExtra = 0, 
    .cbWndExtra = 0,
    .hInstance = hInstance,
    .hIcon = null, 
    .hCursor = LoadCursorW(null, IDC_ARROW),
    .hbrBackground = null, 
    .lpszMenuName = null,
    .lpszClassName = class_name,
    .hIconSm = null,
  };

  _ = RegisterClassExW(&wnd_class);
  defer _ = UnregisterClassW(class_name, hInstance);
  const hwnd = CreateWindowExW(
    WS_EX_APPWINDOW, class_name, wnd_name, WS_OVERLAPPEDWINDOW | WS_VISIBLE,
    CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
    null, null, hInstance, null) orelse undefined; 
  defer _ = DestroyWindow(hwnd);
  wnd = hwnd;
  hFont = GetStockObject(ANSI_VAR_FONT);
  
  var ctx_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer ctx_arena.deinit();
  const ctx_alloc = ctx_arena.allocator();
  ctx = ctx_alloc.create(mu.mu_Context) catch unreachable;
  defer ctx_alloc.destroy(ctx);
  mu.mu_init(ctx);
  ctx.text_width = text_width;
  ctx.text_height = text_height;

  _ = ShowWindow(wnd, nCmdShow);
  _ = UpdateWindow(wnd);
  _ = SetForegroundWindow(wnd);
  _ = SetCursor(LoadCursorW(null, IDC_ARROW)); // @constCast(L("IDC_ARROW"))));

  var msg: MSG = std.mem.zeroes(MSG);
  while (GetMessageW(&msg, null, 0, 0) != 0) {
    _ = TranslateMessage(&msg);
    _ = DispatchMessageW(&msg);

    gui.present(ctx);
    r_begin();
    r_clear(mu.mu_color(bg[0], bg[1], bg[2], 255));
    var cmd: [*c]mu.mu_Command = null;
    while (mu.mu_next_command(ctx, &cmd) != 0) {
      switch (cmd.*.type) {
        mu.MU_COMMAND_TEXT => { r_draw_text(&cmd.*.text.str, cmd.*.text.pos, cmd.*.text.color); },
        mu.MU_COMMAND_RECT => { r_draw_rect(cmd.*.rect.rect, cmd.*.rect.color); },
        mu.MU_COMMAND_ICON => { r_draw_icon(cmd.*.icon.id, cmd.*.icon.rect, cmd.*.icon.color); },
        mu.MU_COMMAND_CLIP => { r_set_clip_rect(cmd.*.clip.rect); },
        else => {  }
      }
    }
    r_end();

  }

  return 0;
}
//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(.winapi) win.LRESULT {
  switch (uMsg) {
    WM_DESTROY => {
      PostQuitMessage(0);
      return 0;
    },
    WM_PAINT => {
      const hdc: win.HDC = BeginPaint(hWnd, &ps) orelse undefined;
      _ = FillRect(hdc, &ps.rcPaint, @ptrFromInt(COLOR_WINDOW+1));
      _ = EndPaint(hWnd, &ps);
      mPS = ps;
    },
    //win.WM_SETCURSOR => { },

    //r_handle_input(ctx);
    WM_KEYDOWN,
    WM_KEYUP,
    WM_SYSKEYDOWN,
    WM_SYSKEYUP => {
      switch (wParam) {
        VK_SHIFT,
        VK_LSHIFT,
        VK_RSHIFT => {
          mu.mu_input_keydown(ctx, mu.MU_KEY_SHIFT);
        },
        VK_BACK,
        VK_DELETE => {
          mu.mu_input_keydown(ctx, mu.MU_KEY_BACKSPACE);
        },
        VK_RETURN => {
          mu.mu_input_keydown(ctx, mu.MU_KEY_RETURN);            
        },
        VK_MENU,
        VK_RMENU,
        VK_LMENU => {
          mu.mu_input_keydown(ctx, mu.MU_KEY_ALT);
        },
        VK_TAB,
        VK_LEFT,
        VK_RIGHT,
        VK_HOME,
        VK_END,
        VK_NEXT,
        VK_PRIOR => {
        },
        else => _=.{},
      }
    },
    WM_CHAR => {
      const result: [*c]const u8 = @as([*c]const u8, @ptrCast(&wParam));
      mu.mu_input_text(ctx, result);
    },
    WM_MOUSEMOVE => {
      mu.mu_input_mousemove(ctx, LOWORD(lParam), HIWORD(lParam));
    },
    WM_LBUTTONUP,
    WM_LBUTTONDOWN,
    WM_RBUTTONDOWN,
    WM_RBUTTONUP => {
      if (wParam == MK_LBUTTON)      {
        mu.mu_input_mousedown(ctx, LOWORD(lParam), HIWORD(lParam), 1);
        _ = SetCapture(wnd);
      } else {
        mu.mu_input_mouseup(ctx, LOWORD(lParam), HIWORD(lParam), 1);
        _ = ReleaseCapture();
      }
      if (wParam == MK_RBUTTON) {
        mu.mu_input_mousedown(ctx, LOWORD(lParam), HIWORD(lParam), 2);
        _ = SetCapture(wnd);           
      } else {
        mu.mu_input_mouseup(ctx, LOWORD(lParam), HIWORD(lParam), 2);
        _ = ReleaseCapture();
      }
    },
    else => _=.{},
  }

  return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

//
// RENDERER
//

pub fn r_begin() void {
  _ = DeleteDC(mHDC);
  _ = GetClientRect(wnd, &Client_Rect);
  _ = InvalidateRect(wnd, &Client_Rect, win.FALSE);
  width = Client_Rect.right - Client_Rect.left;
  height = Client_Rect.bottom + Client_Rect.left;
  mBDC = BeginPaint(wnd, &mPS) orelse undefined;

  mHDC = CreateCompatibleDC(mBDC);
  mBitmap = CreateCompatibleBitmap(mBDC, width, height);
  const cBitmap: selObj = @as(selObj, @ptrCast(mBitmap));
  _ = SelectObject(mHDC, cBitmap);
}

pub fn r_clear(clr: mu.mu_Color) void {
  var rect: win.RECT = undefined;
  _ = SetRect(&rect, Client_Rect.left, Client_Rect.top, Client_Rect.right, Client_Rect.bottom);
  _ = SetBkColor(mHDC, RGB(clr.r, clr.g, clr.b));
  _ = ExtTextOutA(mHDC, 0, 0, ETO_OPAQUE, &rect, null, 0, null);
}

pub fn r_end() void {
  _ = BitBlt(mBDC, 0, 0, width, height, mHDC, 0, 0, SRCCOPY);
  _ = DeleteDC(mBDC);
  const cBitmap: HGDIOBJ = @as(HGDIOBJ, @ptrCast(mBitmap));
  _ = DeleteObject(cBitmap);
  _ = EndPaint(wnd, &mPS);
  const cPS: HGDIOBJ = @as(HGDIOBJ, @ptrCast(mPS.hdc));
  _ = DeleteObject(cPS);
}


pub fn text_width(font: ?*anyopaque, text: [*c]const u8, len: c_int) callconv(.c) c_int {
  _ = font;
  return r_get_text_width(text, len);
}

pub fn text_height(font: ?*anyopaque) callconv(.c) c_int {
  _ = font;
  return r_get_text_height();
}

pub fn r_get_text_width(text: [*c]const u8, len: c_int) callconv(.c) c_int {
  _ = len;
  var res: usize = 0;
  var p = text;
  while (p.* != 0) : (p += 1) { res += 1; }

  var size : SIZE = undefined;
  const cFont: selObj = @as(selObj, @ptrCast(hFont));
  _ = SelectObject(mHDC, cFont);
  _ = GetTextExtentPoint32A(mHDC, @as([*:0]u8, @ptrCast(@constCast(text[0..res]))), @as(c_int, @intCast(res)), &size);

  //return size.cx;
  return @as(c_int, @intCast(res * 18));
}

pub fn r_get_text_height() callconv(.c) c_int {
  var size : SIZE = undefined;
  const cFont: selObj = @as(selObj, @ptrCast(hFont));
  _ = SelectObject(mHDC, cFont);
  _ = GetTextExtentPoint32A(mHDC, @as([*:0]u8, @ptrCast(@constCast("E"))), 1, &size);
  return size.cy;
}

fn push_quad(dst: mu.mu_Rect, color: mu.mu_Color) void {
  if (color.a < 1) { return;  }
  var rect: win.RECT = undefined;
  _ = SetRect(&rect, dst.x, dst.y, dst.x + dst.w, dst.y + dst.h);
  _ = SetBkColor(mHDC, RGB(color.r, color.g, color.b));
  _ = ExtTextOutA(mHDC, 0, 0, ETO_OPAQUE, &rect, null, 0, null);
}

pub fn r_draw_rect(rect: mu.mu_Rect, color: mu.mu_Color) void {
  push_quad(rect, color);
}

pub fn r_draw_text(text: []const u8, pos: mu.mu_Vec2, color: mu.mu_Color) void {
  var res: u8 = 0;
  while (text.ptr[res] != 0) { res += 1; }

  const cFont: selObj = @as(selObj, @ptrCast(hFont));
  _ = SelectObject(mHDC, cFont);
  _ = SetBkMode(mHDC, TRANSPARENT);
  _ = SetTextColor(mHDC, RGB(color.r, color.g, color.b));
  _ = ExtTextOutA(mHDC, pos.x, pos.y, ETO_OPAQUE, null, @as(win.LPSTR, @ptrCast(@constCast(text))), @as(c_uint, @intCast(res)), null);
}

pub fn r_draw_icon(id: c_int, rect: mu.mu_Rect, color: mu.mu_Color) void {
  var c: c_int = 0;
  var w: c_int = 0;
  var h: c_int = 0;
  var pos: mu.mu_Vec2 = undefined;
  var buf: [2]u8 = undefined;

  switch (id) {
    mu.MU_ICON_CLOSE=> { c = 'x'; },
    mu.MU_ICON_CHECK=> { c = 'X'; },
    mu.MU_ICON_COLLAPSED=> {c = '>'; },
    mu.MU_ICON_EXPANDED=> {c = 'v'; }, 
    else => {}
  }
  buf[0] = @as(u8, @intCast(c));
  buf[1] = 0;
  w = r_get_text_width(@as([*c]const u8, @constCast(&buf)), 1);
  h = r_get_text_height();
  pos.x = rect.x; //@divFloor( rect.x + (rect.w - w) , 2);
  pos.y = rect.y; //@divFloor( rect.y + (rect.h - h) , 2);
  r_draw_text(&buf, pos, color);
}

pub fn r_set_clip_rect(rect: mu.mu_Rect) void {
  _ = SelectClipRgn(mHDC, null);
  _ = IntersectClipRect(mHDC, rect.x, rect.y, rect.x + rect.w, rect.y + rect.h);
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(.winapi) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}


//#endregion ==================================================================
//#region MARK: CONST
//=============================================================================
fn LOWORD(l: win.LONG_PTR) win.INT { return @as(i32, @intCast(l)) & 0xFFFF; }
fn HIWORD(l: win.LONG_PTR) win.INT { return (@as(i32, @intCast(l)) >> 16) & 0xFFFF; }

const HFONT = win.HANDLE;

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
const WM_KEYUP = 0x0101;
const WM_SYSKEYUP = 0x0105;
const WM_CHAR = 0x0102;
const WM_MOUSEMOVE = 0x0200;
const WM_LBUTTONDOWN = 0x0201;
const WM_LBUTTONUP = 0x0202;
const WM_LBUTTONDBLCLK = 0x0203;
const WM_RBUTTONDOWN = 0x0204;
const WM_RBUTTONUP = 0x0205;
const WM_RBUTTONDBLCLK = 0x0206;
const WM_MBUTTONDOWN = 0x0207;
const WM_MBUTTONUP = 0x0208;
const WM_MBUTTONDBLCLK = 0x0209;
const WM_MOUSEWHEEL = 0x020A;
const MK_LBUTTON = 1;
const MK_RBUTTON = 2;
const WS_EX_APPWINDOW = 0x00040000;
const ANSI_VAR_FONT = 12;


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

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================

const WNDPROC = *const fn (
  hwnd: win.HWND, 
  uMsg: win.UINT, 
  wParam: win.WPARAM, 
  lParam: win.LPARAM
) callconv(.winapi) win.LRESULT;

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

pub extern "gdi32" fn GetStockObject(
  i: win.INT,
) callconv(.winapi) ?HFONT;

pub extern "user32" fn SetRect(
  lprc: *win.RECT,
  xLeft: win.INT,
  yTop: win.INT,
  xRight: win.INT,
  yBottom: win.INT
) callconv(.winapi) win.BOOL;

const COLORREF = win.DWORD;
const LPCOLORREF = win.DWORD_PTR;
pub extern "gdi32" fn SetBkColor(
  hdc: win.HDC,
  color: COLORREF
) callconv(.winapi) COLORREF;

pub extern "gdi32" fn SetBkMode(
  hdc: win.HDC,
  mode: win.INT
) callconv(.winapi) win.INT;

const TRANSPARENT = 1;
const OPAQUE = 2;
pub extern "gdi32" fn SetTextColor(
  hdc: win.HDC,
  mode: COLORREF
) callconv(.winapi) COLORREF;

pub fn RGB(r: u8, g: u8, b: u8) COLORREF {
  const gs = @as(u32, @intCast(g)) << 8;
  const bs = @as(u32, @intCast(b)) << 16;
  return @as(COLORREF, r | gs | bs);
}

const ETO_OPAQUE = 0x00000002;
pub extern "gdi32" fn ExtTextOutA(
  hdc: win.HDC,
  x: win.INT,
  y: win.INT,
  options: win.UINT,
  lprect: ?*const win.RECT,
  lpString: ?win.LPCSTR,
  c: win.UINT,
  lpDx: ?*const win.INT
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn DeleteDC(
  hdc: win.HDC
) callconv(.winapi) win.BOOL;

pub extern "user32" fn GetClientRect(
  hWnd: win.HWND,
  lpRect: *win.RECT
) callconv(.winapi) win.BOOL;

pub extern "user32" fn InvalidateRect(
  hWnd: win.HWND,
  lpRect: *const win.RECT,
  bErase: win.BOOL
) callconv(.winapi) win.BOOL;

pub extern "gdi32" fn CreateCompatibleDC(
  hdc: win.HDC
) callconv(.winapi) win.HDC;

pub const BITMAP = extern struct {
  bmType: win.INT,
  bmWidth: win.INT,
  bmHeight: win.INT,
  bmWidthBytes: win.INT,
  bmPlanes: win.INT,
  bmBitsPixel: win.INT,
  bmBits: win.INT
};
pub const HBITMAP = *BITMAP;

pub extern "gdi32" fn CreateCompatibleBitmap(
  hdc: win.HDC,
  cx: win.INT,
  cy: win.INT
) callconv(.winapi) HBITMAP;

const selObj = *opaque{};
const delObj = *opaque{};
pub extern "gdi32" fn SelectObject(
  hdc: win.HDC,
  h: selObj
) callconv(.winapi) HGDIOBJ;

const SRCCOPY = 0xCC0020;
pub extern "gdi32" fn BitBlt(
  hdc: win.HDC,
  x: win.INT,
  y: win.INT,
  cx: win.INT,
  cy: win.INT,
  hdcSrc: win.HDC,
  x1: win.INT,
  y1: win.INT,
  rop: win.DWORD 
) callconv(.winapi) win.BOOL;

pub const SIZE = extern struct {
  cx: win.LONG,
  cy: win.LONG
};
const PSIZE = *SIZE;
const LPSIZE = *SIZE;

pub extern "gdi32" fn GetTextExtentPoint32A(
  hdc: win.HDC,
  lpString: win.LPSTR,
  c: win.INT,
  psizl: LPSIZE
) callconv(.winapi) win.BOOL;

const HRGN = ?*opaque{};
pub extern "gdi32" fn SelectClipRgn(
  hdc: win.HDC,
  hrgn: HRGN
) callconv(.winapi) win.INT;

 pub extern "gdi32" fn IntersectClipRect(
  hdc: win.HDC,
  left: win.INT,
  top: win.INT,
  right: win.INT,
  bottom: win.INT
) callconv(.winapi) win.INT;

pub extern "gdi32" fn TextOutA(
  hDC: ?win.HDC,
  x: win.INT,
  y: win.INT,
  lpString: win.LPCSTR,
  c: win.INT
) callconv(.winapi) win.BOOL;

pub extern "user32" fn SetForegroundWindow(
  hWnd: win.HWND,
) callconv(.winapi) win.BOOL;

pub extern "user32" fn SetCursor(
  hCursor: ?win.HCURSOR,
) callconv(.winapi) win.HCURSOR;

pub extern "user32" fn GetMessageW(
  lpMsg: *MSG,
  hWnd: ?win.HWND,
  wMsgFilterMin: win.UINT,
  wMsgFilterMax: win.UINT
) callconv(.winapi) win.BOOL;

pub extern "user32" fn SetCapture(
  hWnd: win.HWND
) callconv(.winapi) win.HWND;

pub extern "user32" fn ReleaseCapture(
) callconv(.winapi) win.BOOL;


//#endregion ==================================================================
//#region MARK: VIRTUALKEYS
//=============================================================================

// VIRTUAL_KEYS
// Copied from marlersoft zigwin32 
// https://github.com/marlersoft/zigwin32/blob/main/win32/ui/input/keyboard_and_mouse.zig
//
pub const VIRTUAL_KEY = enum(u16) {
    @"0" = 48,
    @"1" = 49,
    @"2" = 50,
    @"3" = 51,
    @"4" = 52,
    @"5" = 53,
    @"6" = 54,
    @"7" = 55,
    @"8" = 56,
    @"9" = 57,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LBUTTON = 1,
    RBUTTON = 2,
    CANCEL = 3,
    MBUTTON = 4,
    XBUTTON1 = 5,
    XBUTTON2 = 6,
    BACK = 8,
    TAB = 9,
    CLEAR = 12,
    RETURN = 13,
    SHIFT = 16,
    CONTROL = 17,
    MENU = 18,
    PAUSE = 19,
    CAPITAL = 20,
    KANA = 21,
    // HANGEUL = 21, this enum value conflicts with KANA
    // HANGUL = 21, this enum value conflicts with KANA
    IME_ON = 22,
    JUNJA = 23,
    FINAL = 24,
    HANJA = 25,
    // KANJI = 25, this enum value conflicts with HANJA
    IME_OFF = 26,
    ESCAPE = 27,
    CONVERT = 28,
    NONCONVERT = 29,
    ACCEPT = 30,
    MODECHANGE = 31,
    SPACE = 32,
    PRIOR = 33,
    NEXT = 34,
    END = 35,
    HOME = 36,
    LEFT = 37,
    UP = 38,
    RIGHT = 39,
    DOWN = 40,
    SELECT = 41,
    PRINT = 42,
    EXECUTE = 43,
    SNAPSHOT = 44,
    INSERT = 45,
    DELETE = 46,
    HELP = 47,
    LWIN = 91,
    RWIN = 92,
    APPS = 93,
    SLEEP = 95,
    NUMPAD0 = 96,
    NUMPAD1 = 97,
    NUMPAD2 = 98,
    NUMPAD3 = 99,
    NUMPAD4 = 100,
    NUMPAD5 = 101,
    NUMPAD6 = 102,
    NUMPAD7 = 103,
    NUMPAD8 = 104,
    NUMPAD9 = 105,
    MULTIPLY = 106,
    ADD = 107,
    SEPARATOR = 108,
    SUBTRACT = 109,
    DECIMAL = 110,
    DIVIDE = 111,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    F13 = 124,
    F14 = 125,
    F15 = 126,
    F16 = 127,
    F17 = 128,
    F18 = 129,
    F19 = 130,
    F20 = 131,
    F21 = 132,
    F22 = 133,
    F23 = 134,
    F24 = 135,
    NAVIGATION_VIEW = 136,
    NAVIGATION_MENU = 137,
    NAVIGATION_UP = 138,
    NAVIGATION_DOWN = 139,
    NAVIGATION_LEFT = 140,
    NAVIGATION_RIGHT = 141,
    NAVIGATION_ACCEPT = 142,
    NAVIGATION_CANCEL = 143,
    NUMLOCK = 144,
    SCROLL = 145,
    OEM_NEC_EQUAL = 146,
    // OEM_FJ_JISHO = 146, this enum value conflicts with OEM_NEC_EQUAL
    OEM_FJ_MASSHOU = 147,
    OEM_FJ_TOUROKU = 148,
    OEM_FJ_LOYA = 149,
    OEM_FJ_ROYA = 150,
    LSHIFT = 160,
    RSHIFT = 161,
    LCONTROL = 162,
    RCONTROL = 163,
    LMENU = 164,
    RMENU = 165,
    BROWSER_BACK = 166,
    BROWSER_FORWARD = 167,
    BROWSER_REFRESH = 168,
    BROWSER_STOP = 169,
    BROWSER_SEARCH = 170,
    BROWSER_FAVORITES = 171,
    BROWSER_HOME = 172,
    VOLUME_MUTE = 173,
    VOLUME_DOWN = 174,
    VOLUME_UP = 175,
    MEDIA_NEXT_TRACK = 176,
    MEDIA_PREV_TRACK = 177,
    MEDIA_STOP = 178,
    MEDIA_PLAY_PAUSE = 179,
    LAUNCH_MAIL = 180,
    LAUNCH_MEDIA_SELECT = 181,
    LAUNCH_APP1 = 182,
    LAUNCH_APP2 = 183,
    OEM_1 = 186,
    OEM_PLUS = 187,
    OEM_COMMA = 188,
    OEM_MINUS = 189,
    OEM_PERIOD = 190,
    OEM_2 = 191,
    OEM_3 = 192,
    GAMEPAD_A = 195,
    GAMEPAD_B = 196,
    GAMEPAD_X = 197,
    GAMEPAD_Y = 198,
    GAMEPAD_RIGHT_SHOULDER = 199,
    GAMEPAD_LEFT_SHOULDER = 200,
    GAMEPAD_LEFT_TRIGGER = 201,
    GAMEPAD_RIGHT_TRIGGER = 202,
    GAMEPAD_DPAD_UP = 203,
    GAMEPAD_DPAD_DOWN = 204,
    GAMEPAD_DPAD_LEFT = 205,
    GAMEPAD_DPAD_RIGHT = 206,
    GAMEPAD_MENU = 207,
    GAMEPAD_VIEW = 208,
    GAMEPAD_LEFT_THUMBSTICK_BUTTON = 209,
    GAMEPAD_RIGHT_THUMBSTICK_BUTTON = 210,
    GAMEPAD_LEFT_THUMBSTICK_UP = 211,
    GAMEPAD_LEFT_THUMBSTICK_DOWN = 212,
    GAMEPAD_LEFT_THUMBSTICK_RIGHT = 213,
    GAMEPAD_LEFT_THUMBSTICK_LEFT = 214,
    GAMEPAD_RIGHT_THUMBSTICK_UP = 215,
    GAMEPAD_RIGHT_THUMBSTICK_DOWN = 216,
    GAMEPAD_RIGHT_THUMBSTICK_RIGHT = 217,
    GAMEPAD_RIGHT_THUMBSTICK_LEFT = 218,
    OEM_4 = 219,
    OEM_5 = 220,
    OEM_6 = 221,
    OEM_7 = 222,
    OEM_8 = 223,
    OEM_AX = 225,
    OEM_102 = 226,
    ICO_HELP = 227,
    ICO_00 = 228,
    PROCESSKEY = 229,
    ICO_CLEAR = 230,
    PACKET = 231,
    OEM_RESET = 233,
    OEM_JUMP = 234,
    OEM_PA1 = 235,
    OEM_PA2 = 236,
    OEM_PA3 = 237,
    OEM_WSCTRL = 238,
    OEM_CUSEL = 239,
    OEM_ATTN = 240,
    OEM_FINISH = 241,
    OEM_COPY = 242,
    OEM_AUTO = 243,
    OEM_ENLW = 244,
    OEM_BACKTAB = 245,
    ATTN = 246,
    CRSEL = 247,
    EXSEL = 248,
    EREOF = 249,
    PLAY = 250,
    ZOOM = 251,
    NONAME = 252,
    PA1 = 253,
    OEM_CLEAR = 254,
};
pub const VK_0 = @intFromEnum(VIRTUAL_KEY.@"0");
pub const VK_1 = @intFromEnum(VIRTUAL_KEY.@"1");
pub const VK_2 = @intFromEnum(VIRTUAL_KEY.@"2");
pub const VK_3 = @intFromEnum(VIRTUAL_KEY.@"3");
pub const VK_4 = @intFromEnum(VIRTUAL_KEY.@"4");
pub const VK_5 = @intFromEnum(VIRTUAL_KEY.@"5");
pub const VK_6 = @intFromEnum(VIRTUAL_KEY.@"6");
pub const VK_7 = @intFromEnum(VIRTUAL_KEY.@"7");
pub const VK_8 = @intFromEnum(VIRTUAL_KEY.@"8");
pub const VK_9 = @intFromEnum(VIRTUAL_KEY.@"9");
pub const VK_A = @intFromEnum(VIRTUAL_KEY.A);
pub const VK_B = @intFromEnum(VIRTUAL_KEY.B);
pub const VK_C = @intFromEnum(VIRTUAL_KEY.C);
pub const VK_D = @intFromEnum(VIRTUAL_KEY.D);
pub const VK_E = @intFromEnum(VIRTUAL_KEY.E);
pub const VK_F = @intFromEnum(VIRTUAL_KEY.F);
pub const VK_G = @intFromEnum(VIRTUAL_KEY.G);
pub const VK_H = @intFromEnum(VIRTUAL_KEY.H);
pub const VK_I = @intFromEnum(VIRTUAL_KEY.I);
pub const VK_J = @intFromEnum(VIRTUAL_KEY.J);
pub const VK_K = @intFromEnum(VIRTUAL_KEY.K);
pub const VK_L = @intFromEnum(VIRTUAL_KEY.L);
pub const VK_M = @intFromEnum(VIRTUAL_KEY.M);
pub const VK_N = @intFromEnum(VIRTUAL_KEY.N);
pub const VK_O = @intFromEnum(VIRTUAL_KEY.O);
pub const VK_P = @intFromEnum(VIRTUAL_KEY.P);
pub const VK_Q = @intFromEnum(VIRTUAL_KEY.Q);
pub const VK_R = @intFromEnum(VIRTUAL_KEY.R);
pub const VK_S = @intFromEnum(VIRTUAL_KEY.S);
pub const VK_T = @intFromEnum(VIRTUAL_KEY.T);
pub const VK_U = @intFromEnum(VIRTUAL_KEY.U);
pub const VK_V = @intFromEnum(VIRTUAL_KEY.V);
pub const VK_W = @intFromEnum(VIRTUAL_KEY.W);
pub const VK_X = @intFromEnum(VIRTUAL_KEY.X);
pub const VK_Y = @intFromEnum(VIRTUAL_KEY.Y);
pub const VK_Z = @intFromEnum(VIRTUAL_KEY.Z);
pub const VK_LBUTTON = @intFromEnum(VIRTUAL_KEY.LBUTTON);
pub const VK_RBUTTON = @intFromEnum(VIRTUAL_KEY.RBUTTON);
pub const VK_CANCEL = @intFromEnum(VIRTUAL_KEY.CANCEL);
pub const VK_MBUTTON = @intFromEnum(VIRTUAL_KEY.MBUTTON);
pub const VK_XBUTTON1 = @intFromEnum(VIRTUAL_KEY.XBUTTON1);
pub const VK_XBUTTON2 = @intFromEnum(VIRTUAL_KEY.XBUTTON2);
pub const VK_BACK = @intFromEnum(VIRTUAL_KEY.BACK);
pub const VK_TAB = @intFromEnum(VIRTUAL_KEY.TAB);
pub const VK_CLEAR = @intFromEnum(VIRTUAL_KEY.CLEAR);
pub const VK_RETURN = @intFromEnum(VIRTUAL_KEY.RETURN);
pub const VK_SHIFT = @intFromEnum(VIRTUAL_KEY.SHIFT);
pub const VK_CONTROL = @intFromEnum(VIRTUAL_KEY.CONTROL);
pub const VK_MENU = @intFromEnum(VIRTUAL_KEY.MENU);
pub const VK_PAUSE = @intFromEnum(VIRTUAL_KEY.PAUSE);
pub const VK_CAPITAL = @intFromEnum(VIRTUAL_KEY.CAPITAL);
pub const VK_KANA = @intFromEnum(VIRTUAL_KEY.KANA);
pub const VK_HANGEUL = @intFromEnum(VIRTUAL_KEY.KANA);
pub const VK_HANGUL = @intFromEnum(VIRTUAL_KEY.KANA);
pub const VK_IME_ON = @intFromEnum(VIRTUAL_KEY.IME_ON);
pub const VK_JUNJA = @intFromEnum(VIRTUAL_KEY.JUNJA);
pub const VK_FINAL = @intFromEnum(VIRTUAL_KEY.FINAL);
pub const VK_HANJA = @intFromEnum(VIRTUAL_KEY.HANJA);
pub const VK_KANJI = @intFromEnum(VIRTUAL_KEY.HANJA);
pub const VK_IME_OFF = @intFromEnum(VIRTUAL_KEY.IME_OFF);
pub const VK_ESCAPE = @intFromEnum(VIRTUAL_KEY.ESCAPE);
pub const VK_CONVERT = @intFromEnum(VIRTUAL_KEY.CONVERT);
pub const VK_NONCONVERT = @intFromEnum(VIRTUAL_KEY.NONCONVERT);
pub const VK_ACCEPT = @intFromEnum(VIRTUAL_KEY.ACCEPT);
pub const VK_MODECHANGE = @intFromEnum(VIRTUAL_KEY.MODECHANGE);
pub const VK_SPACE = @intFromEnum(VIRTUAL_KEY.SPACE);
pub const VK_PRIOR = @intFromEnum(VIRTUAL_KEY.PRIOR);
pub const VK_NEXT = @intFromEnum(VIRTUAL_KEY.NEXT);
pub const VK_END = @intFromEnum(VIRTUAL_KEY.END);
pub const VK_HOME = @intFromEnum(VIRTUAL_KEY.HOME);
pub const VK_LEFT = @intFromEnum(VIRTUAL_KEY.LEFT);
pub const VK_UP = @intFromEnum(VIRTUAL_KEY.UP);
pub const VK_RIGHT = @intFromEnum(VIRTUAL_KEY.RIGHT);
pub const VK_DOWN = @intFromEnum(VIRTUAL_KEY.DOWN);
pub const VK_SELECT = @intFromEnum(VIRTUAL_KEY.SELECT);
pub const VK_PRINT = @intFromEnum(VIRTUAL_KEY.PRINT);
pub const VK_EXECUTE = @intFromEnum(VIRTUAL_KEY.EXECUTE);
pub const VK_SNAPSHOT = @intFromEnum(VIRTUAL_KEY.SNAPSHOT);
pub const VK_INSERT = @intFromEnum(VIRTUAL_KEY.INSERT);
pub const VK_DELETE = @intFromEnum(VIRTUAL_KEY.DELETE);
pub const VK_HELP = @intFromEnum(VIRTUAL_KEY.HELP);
pub const VK_LWIN = @intFromEnum(VIRTUAL_KEY.LWIN);
pub const VK_RWIN = @intFromEnum(VIRTUAL_KEY.RWIN);
pub const VK_APPS = @intFromEnum(VIRTUAL_KEY.APPS);
pub const VK_SLEEP = @intFromEnum(VIRTUAL_KEY.SLEEP);
pub const VK_NUMPAD0 = @intFromEnum(VIRTUAL_KEY.NUMPAD0);
pub const VK_NUMPAD1 = @intFromEnum(VIRTUAL_KEY.NUMPAD1);
pub const VK_NUMPAD2 = @intFromEnum(VIRTUAL_KEY.NUMPAD2);
pub const VK_NUMPAD3 = @intFromEnum(VIRTUAL_KEY.NUMPAD3);
pub const VK_NUMPAD4 = @intFromEnum(VIRTUAL_KEY.NUMPAD4);
pub const VK_NUMPAD5 = @intFromEnum(VIRTUAL_KEY.NUMPAD5);
pub const VK_NUMPAD6 = @intFromEnum(VIRTUAL_KEY.NUMPAD6);
pub const VK_NUMPAD7 = @intFromEnum(VIRTUAL_KEY.NUMPAD7);
pub const VK_NUMPAD8 = @intFromEnum(VIRTUAL_KEY.NUMPAD8);
pub const VK_NUMPAD9 = @intFromEnum(VIRTUAL_KEY.NUMPAD9);
pub const VK_MULTIPLY = @intFromEnum(VIRTUAL_KEY.MULTIPLY);
pub const VK_ADD = @intFromEnum(VIRTUAL_KEY.ADD);
pub const VK_SEPARATOR = @intFromEnum(VIRTUAL_KEY.SEPARATOR);
pub const VK_SUBTRACT = @intFromEnum(VIRTUAL_KEY.SUBTRACT);
pub const VK_DECIMAL = @intFromEnum(VIRTUAL_KEY.DECIMAL);
pub const VK_DIVIDE = @intFromEnum(VIRTUAL_KEY.DIVIDE);
pub const VK_F1 = @intFromEnum(VIRTUAL_KEY.F1);
pub const VK_F2 = @intFromEnum(VIRTUAL_KEY.F2);
pub const VK_F3 = @intFromEnum(VIRTUAL_KEY.F3);
pub const VK_F4 = @intFromEnum(VIRTUAL_KEY.F4);
pub const VK_F5 = @intFromEnum(VIRTUAL_KEY.F5);
pub const VK_F6 = @intFromEnum(VIRTUAL_KEY.F6);
pub const VK_F7 = @intFromEnum(VIRTUAL_KEY.F7);
pub const VK_F8 = @intFromEnum(VIRTUAL_KEY.F8);
pub const VK_F9 = @intFromEnum(VIRTUAL_KEY.F9);
pub const VK_F10 = @intFromEnum(VIRTUAL_KEY.F10);
pub const VK_F11 = @intFromEnum(VIRTUAL_KEY.F11);
pub const VK_F12 = @intFromEnum(VIRTUAL_KEY.F12);
pub const VK_F13 = @intFromEnum(VIRTUAL_KEY.F13);
pub const VK_F14 = @intFromEnum(VIRTUAL_KEY.F14);
pub const VK_F15 = @intFromEnum(VIRTUAL_KEY.F15);
pub const VK_F16 = @intFromEnum(VIRTUAL_KEY.F16);
pub const VK_F17 = @intFromEnum(VIRTUAL_KEY.F17);
pub const VK_F18 = @intFromEnum(VIRTUAL_KEY.F18);
pub const VK_F19 = @intFromEnum(VIRTUAL_KEY.F19);
pub const VK_F20 = @intFromEnum(VIRTUAL_KEY.F20);
pub const VK_F21 = @intFromEnum(VIRTUAL_KEY.F21);
pub const VK_F22 = @intFromEnum(VIRTUAL_KEY.F22);
pub const VK_F23 = @intFromEnum(VIRTUAL_KEY.F23);
pub const VK_F24 = @intFromEnum(VIRTUAL_KEY.F24);
pub const VK_NAVIGATION_VIEW = @intFromEnum(VIRTUAL_KEY.NAVIGATION_VIEW);
pub const VK_NAVIGATION_MENU = @intFromEnum(VIRTUAL_KEY.NAVIGATION_MENU);
pub const VK_NAVIGATION_UP = @intFromEnum(VIRTUAL_KEY.NAVIGATION_UP);
pub const VK_NAVIGATION_DOWN = @intFromEnum(VIRTUAL_KEY.NAVIGATION_DOWN);
pub const VK_NAVIGATION_LEFT = @intFromEnum(VIRTUAL_KEY.NAVIGATION_LEFT);
pub const VK_NAVIGATION_RIGHT = @intFromEnum(VIRTUAL_KEY.NAVIGATION_RIGHT);
pub const VK_NAVIGATION_ACCEPT = @intFromEnum(VIRTUAL_KEY.NAVIGATION_ACCEPT);
pub const VK_NAVIGATION_CANCEL = @intFromEnum(VIRTUAL_KEY.NAVIGATION_CANCEL);
pub const VK_NUMLOCK = @intFromEnum(VIRTUAL_KEY.NUMLOCK);
pub const VK_SCROLL = @intFromEnum(VIRTUAL_KEY.SCROLL);
pub const VK_OEM_NEC_EQUAL = @intFromEnum(VIRTUAL_KEY.OEM_NEC_EQUAL);
pub const VK_OEM_FJ_JISHO = @intFromEnum(VIRTUAL_KEY.OEM_NEC_EQUAL);
pub const VK_OEM_FJ_MASSHOU = @intFromEnum(VIRTUAL_KEY.OEM_FJ_MASSHOU);
pub const VK_OEM_FJ_TOUROKU = @intFromEnum(VIRTUAL_KEY.OEM_FJ_TOUROKU);
pub const VK_OEM_FJ_LOYA = @intFromEnum(VIRTUAL_KEY.OEM_FJ_LOYA);
pub const VK_OEM_FJ_ROYA = @intFromEnum(VIRTUAL_KEY.OEM_FJ_ROYA);
pub const VK_LSHIFT = @intFromEnum(VIRTUAL_KEY.LSHIFT);
pub const VK_RSHIFT = @intFromEnum(VIRTUAL_KEY.RSHIFT);
pub const VK_LCONTROL = @intFromEnum(VIRTUAL_KEY.LCONTROL);
pub const VK_RCONTROL = @intFromEnum(VIRTUAL_KEY.RCONTROL);
pub const VK_LMENU = @intFromEnum(VIRTUAL_KEY.LMENU);
pub const VK_RMENU = @intFromEnum(VIRTUAL_KEY.RMENU);
pub const VK_BROWSER_BACK = @intFromEnum(VIRTUAL_KEY.BROWSER_BACK);
pub const VK_BROWSER_FORWARD = @intFromEnum(VIRTUAL_KEY.BROWSER_FORWARD);
pub const VK_BROWSER_REFRESH = @intFromEnum(VIRTUAL_KEY.BROWSER_REFRESH);
pub const VK_BROWSER_STOP = @intFromEnum(VIRTUAL_KEY.BROWSER_STOP);
pub const VK_BROWSER_SEARCH = @intFromEnum(VIRTUAL_KEY.BROWSER_SEARCH);
pub const VK_BROWSER_FAVORITES = @intFromEnum(VIRTUAL_KEY.BROWSER_FAVORITES);
pub const VK_BROWSER_HOME = @intFromEnum(VIRTUAL_KEY.BROWSER_HOME);
pub const VK_VOLUME_MUTE = @intFromEnum(VIRTUAL_KEY.VOLUME_MUTE);
pub const VK_VOLUME_DOWN = @intFromEnum(VIRTUAL_KEY.VOLUME_DOWN);
pub const VK_VOLUME_UP = @intFromEnum(VIRTUAL_KEY.VOLUME_UP);
pub const VK_MEDIA_NEXT_TRACK = @intFromEnum(VIRTUAL_KEY.MEDIA_NEXT_TRACK);
pub const VK_MEDIA_PREV_TRACK = @intFromEnum(VIRTUAL_KEY.MEDIA_PREV_TRACK);
pub const VK_MEDIA_STOP = @intFromEnum(VIRTUAL_KEY.MEDIA_STOP);
pub const VK_MEDIA_PLAY_PAUSE = @intFromEnum(VIRTUAL_KEY.MEDIA_PLAY_PAUSE);
pub const VK_LAUNCH_MAIL = @intFromEnum(VIRTUAL_KEY.LAUNCH_MAIL);
pub const VK_LAUNCH_MEDIA_SELECT = @intFromEnum(VIRTUAL_KEY.LAUNCH_MEDIA_SELECT);
pub const VK_LAUNCH_APP1 = @intFromEnum(VIRTUAL_KEY.LAUNCH_APP1);
pub const VK_LAUNCH_APP2 = @intFromEnum(VIRTUAL_KEY.LAUNCH_APP2);
pub const VK_OEM_1 = @intFromEnum(VIRTUAL_KEY.OEM_1);
pub const VK_OEM_PLUS = @intFromEnum(VIRTUAL_KEY.OEM_PLUS);
pub const VK_OEM_COMMA = @intFromEnum(VIRTUAL_KEY.OEM_COMMA);
pub const VK_OEM_MINUS = @intFromEnum(VIRTUAL_KEY.OEM_MINUS);
pub const VK_OEM_PERIOD = @intFromEnum(VIRTUAL_KEY.OEM_PERIOD);
pub const VK_OEM_2 = @intFromEnum(VIRTUAL_KEY.OEM_2);
pub const VK_OEM_3 = @intFromEnum(VIRTUAL_KEY.OEM_3);
pub const VK_GAMEPAD_A = @intFromEnum(VIRTUAL_KEY.GAMEPAD_A);
pub const VK_GAMEPAD_B = @intFromEnum(VIRTUAL_KEY.GAMEPAD_B);
pub const VK_GAMEPAD_X = @intFromEnum(VIRTUAL_KEY.GAMEPAD_X);
pub const VK_GAMEPAD_Y = @intFromEnum(VIRTUAL_KEY.GAMEPAD_Y);
pub const VK_GAMEPAD_RIGHT_SHOULDER = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_SHOULDER);
pub const VK_GAMEPAD_LEFT_SHOULDER = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_SHOULDER);
pub const VK_GAMEPAD_LEFT_TRIGGER = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_TRIGGER);
pub const VK_GAMEPAD_RIGHT_TRIGGER = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_TRIGGER);
pub const VK_GAMEPAD_DPAD_UP = @intFromEnum(VIRTUAL_KEY.GAMEPAD_DPAD_UP);
pub const VK_GAMEPAD_DPAD_DOWN = @intFromEnum(VIRTUAL_KEY.GAMEPAD_DPAD_DOWN);
pub const VK_GAMEPAD_DPAD_LEFT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_DPAD_LEFT);
pub const VK_GAMEPAD_DPAD_RIGHT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_DPAD_RIGHT);
pub const VK_GAMEPAD_MENU = @intFromEnum(VIRTUAL_KEY.GAMEPAD_MENU);
pub const VK_GAMEPAD_VIEW = @intFromEnum(VIRTUAL_KEY.GAMEPAD_VIEW);
pub const VK_GAMEPAD_LEFT_THUMBSTICK_BUTTON = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_THUMBSTICK_BUTTON);
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_BUTTON = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_THUMBSTICK_BUTTON);
pub const VK_GAMEPAD_LEFT_THUMBSTICK_UP = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_THUMBSTICK_UP);
pub const VK_GAMEPAD_LEFT_THUMBSTICK_DOWN = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_THUMBSTICK_DOWN);
pub const VK_GAMEPAD_LEFT_THUMBSTICK_RIGHT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_THUMBSTICK_RIGHT);
pub const VK_GAMEPAD_LEFT_THUMBSTICK_LEFT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_LEFT_THUMBSTICK_LEFT);
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_UP = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_THUMBSTICK_UP);
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_DOWN = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_THUMBSTICK_DOWN);
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_RIGHT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_THUMBSTICK_RIGHT);
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_LEFT = @intFromEnum(VIRTUAL_KEY.GAMEPAD_RIGHT_THUMBSTICK_LEFT);
pub const VK_OEM_4 = @intFromEnum(VIRTUAL_KEY.OEM_4);
pub const VK_OEM_5 = @intFromEnum(VIRTUAL_KEY.OEM_5);
pub const VK_OEM_6 = @intFromEnum(VIRTUAL_KEY.OEM_6);
pub const VK_OEM_7 = @intFromEnum(VIRTUAL_KEY.OEM_7);
pub const VK_OEM_8 = @intFromEnum(VIRTUAL_KEY.OEM_8);
pub const VK_OEM_AX = @intFromEnum(VIRTUAL_KEY.OEM_AX);
pub const VK_OEM_102 = @intFromEnum(VIRTUAL_KEY.OEM_102);
pub const VK_ICO_HELP = @intFromEnum(VIRTUAL_KEY.ICO_HELP);
pub const VK_ICO_00 = @intFromEnum(VIRTUAL_KEY.ICO_00);
pub const VK_PROCESSKEY = @intFromEnum(VIRTUAL_KEY.PROCESSKEY);
pub const VK_ICO_CLEAR = @intFromEnum(VIRTUAL_KEY.ICO_CLEAR);
pub const VK_PACKET = @intFromEnum(VIRTUAL_KEY.PACKET);
pub const VK_OEM_RESET = @intFromEnum(VIRTUAL_KEY.OEM_RESET);
pub const VK_OEM_JUMP = @intFromEnum(VIRTUAL_KEY.OEM_JUMP);
pub const VK_OEM_PA1 = @intFromEnum(VIRTUAL_KEY.OEM_PA1);
pub const VK_OEM_PA2 = @intFromEnum(VIRTUAL_KEY.OEM_PA2);
pub const VK_OEM_PA3 = @intFromEnum(VIRTUAL_KEY.OEM_PA3);
pub const VK_OEM_WSCTRL = @intFromEnum(VIRTUAL_KEY.OEM_WSCTRL);
pub const VK_OEM_CUSEL = @intFromEnum(VIRTUAL_KEY.OEM_CUSEL);
pub const VK_OEM_ATTN = @intFromEnum(VIRTUAL_KEY.OEM_ATTN);
pub const VK_OEM_FINISH = @intFromEnum(VIRTUAL_KEY.OEM_FINISH);
pub const VK_OEM_COPY = @intFromEnum(VIRTUAL_KEY.OEM_COPY);
pub const VK_OEM_AUTO = @intFromEnum(VIRTUAL_KEY.OEM_AUTO);
pub const VK_OEM_ENLW = @intFromEnum(VIRTUAL_KEY.OEM_ENLW);
pub const VK_OEM_BACKTAB = @intFromEnum(VIRTUAL_KEY.OEM_BACKTAB);
pub const VK_ATTN = @intFromEnum(VIRTUAL_KEY.ATTN);
pub const VK_CRSEL = @intFromEnum(VIRTUAL_KEY.CRSEL);
pub const VK_EXSEL = @intFromEnum(VIRTUAL_KEY.EXSEL);
pub const VK_EREOF = @intFromEnum(VIRTUAL_KEY.EREOF);
pub const VK_PLAY = @intFromEnum(VIRTUAL_KEY.PLAY);
pub const VK_ZOOM = @intFromEnum(VIRTUAL_KEY.ZOOM);
pub const VK_NONAME = @intFromEnum(VIRTUAL_KEY.NONAME);
pub const VK_PA1 = @intFromEnum(VIRTUAL_KEY.PA1);
pub const VK_OEM_CLEAR = @intFromEnum(VIRTUAL_KEY.OEM_CLEAR);


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================