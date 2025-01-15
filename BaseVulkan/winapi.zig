//!zig-autodoc-section: Windows API
//! Windows API
pub const win = @This();
const std = @import("std");
usingnamespace std.os.windows;
usingnamespace std.os.windows.kernel32;
pub const WINAPI = std.os.windows.WINAPI;

const SIZE = struct {
  width: i16,
  height: i16,
};

pub const wnd_type = struct {
  hInstance: HINSTANCE = undefined,
  hWnd: HWND = undefined,
  name: [*:0]const u8 = undefined,
  classname: [*:0]const u8 = undefined,
  size: SIZE = .{
    .width = 1280,
    .height = 720
  },
  pos: RECT = .{
    .left = 0,
    .top = 0,
    .right = 1280,
    .bottom = 720
  },
  hdc: HDC = undefined,
  dpi: UINT = 96
};
pub var wnd: wnd_type = .{};

pub fn CreateWindow(comptime title: []const u8, hInstance: HINSTANCE, nCmdShow: INT) void {
  _ = nCmdShow;

  wnd.hInstance = hInstance;
  wnd.name = @as([*:0]const u8, @ptrCast(title));
  wnd.classname = title ++ "_class";
  const wnd_class: win.WNDCLASSEXA = .{
    .cbSize = @sizeOf(win.WNDCLASSEXA),
    .style = win.CS_CLASSDC | win.CS_HREDRAW | win.CS_VREDRAW,
    .lpfnWndProc = WindowProc,
    .cbClsExtra = 0, 
    .cbWndExtra = 0,
    .hInstance = hInstance,
    .hIcon = null, 
    .hCursor = win.LoadCursorA(null, win.IDC_ARROW),
    .hbrBackground = null, 
    .lpszMenuName = null,
    .lpszClassName = wnd.classname,
    .hIconSm = null,
  };

  _ = win.RegisterClassExA(&wnd_class);

  wnd.hWnd = win.CreateWindowExA(
    0, wnd.classname, wnd.name, win.WS_OVERLAPPEDWINDOW,
    win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
    null, null, hInstance, null) orelse undefined;

  std.debug.print("{d}\n", .{ wnd.hWnd });

  wnd.hdc = GetDC(wnd.hWnd).?;
  wnd.dpi = GetDpiForWindow(wnd.hWnd);
  const xCenter = @divFloor(GetSystemMetricsForDpi(SM_CXSCREEN, wnd.dpi), 2);
  const yCenter = @divFloor(GetSystemMetricsForDpi(SM_CYSCREEN, wnd.dpi), 2);
  const div_w = @divFloor(wnd.size.width, 2);
  const div_h = @divFloor(wnd.size.height, 2);
  wnd.pos.left = xCenter - div_w;
  wnd.pos.top  = yCenter - div_h;
  wnd.pos.right = wnd.pos.left + div_w;
  wnd.pos.bottom = wnd.pos.top + div_h;
  _ = SetWindowPos( wnd.hWnd, null, wnd.pos.left, wnd.pos.top, wnd.pos.right, wnd.pos.bottom, SWP_NOCOPYBITS );

  std.debug.print("{d}\n", .{ wnd.hdc });
  std.debug.print("{d}\n", .{ wnd.dpi });

}

pub fn ProcessMsg() void {
  while (PeekMessageA(&wnd.msg, null, 0, 0, PM_REMOVE) != 0) {
    _ = TranslateMessage(&wnd.msg);
    _ = DispatchMessageA(&wnd.msg);
    if (wnd.msg.message == WM_QUIT) { wnd.exit = true;  }
  }
}

pub fn WindowProc( hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM ) callconv(WINAPI) LRESULT {
  switch (uMsg) {
    win.WM_DESTROY => {
      win.PostQuitMessage(0);
      return 0;
    },
    win.WM_PAINT => {
      const hdc: HDC = BeginPaint(hWnd, &ps) orelse undefined;
      _ = FillRect(hdc, &ps.rcPaint, @ptrFromInt(COLOR_WINDOW + 1));
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

  return win.DefWindowProcA(hWnd, uMsg, wParam, lParam);
}

pub fn Destroy() void {
  _ = ReleaseDC(wnd.hWnd, wnd.hdc);
  _ = UnregisterClassA(wnd.name, wnd.hInstance);
  _ = DestroyWindow(wnd.hWnd);
}

const TRUE = std.os.windows.TRUE;
const FALSE = std.os.windows.FALSE;

pub const HWND = std.os.windows.HWND;
pub const HINSTANCE = std.os.windows.HINSTANCE;
pub const LPWSTR = std.os.windows.LPWSTR;
pub const LPSTR = std.os.windows.LPSTR;
pub const LPCSTR = std.os.windows.LPCSTR;
pub const INT = std.os.windows.INT;
pub const HANDLE = std.os.windows.HANDLE;
const UINT = std.os.windows.UINT;
const LONG = std.os.windows.LONG;
const BOOL = std.os.windows.BOOL;
pub const DWORD = std.os.windows.DWORD;
const WORD = std.os.windows.WORD;
const RECT = std.os.windows.RECT;
const LRESULT = std.os.windows.LRESULT;
const LONG_PTR = std.os.windows.LONG_PTR;
const WPARAM = std.os.windows.WPARAM;
const LPARAM = std.os.windows.LPARAM;
const POINT = std.os.windows.POINT;
const HDC = *opaque{};
const HBRUSH = *opaque{};
const HGLRC = std.os.windows.HGLRC;
const HICON = std.os.windows.HICON;
const HCURSOR = std.os.windows.HCURSOR;
const ATOM = std.os.windows.ATOM;
const HMENU = std.os.windows.HMENU;
const LPVOID = std.os.windows.LPVOID;
const BYTE = std.os.windows.BYTE;
const CHAR = std.os.windows.CHAR;
const GUID = std.os.windows.GUID;
const PNOTIFYICONDATAA = NOTIFYICONDATAA;
const HRESULT = std.os.windows.HRESULT;
const INFINITE = std.os.windows.INFINITE;

const IDC_ARROW: LONG = 32512;
const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
const CS_DBLCLKS = 0x0008;
const CS_OWNDC = 0x0020;
const CS_VREDRAW = 0x0001;
const CS_HREDRAW = 0x0002;
const CS_CLASSDC = 0x0040;

pub const MB_OK = 0x00000000;
pub const MB_ICONERROR = 0x00000010;
const COLOR_WINDOW = 5;
const VK_ESCAPE = 27;
const VK_LSHIFT = 160;

const GWL_STYLE: INT = -16;
const GWL_EXSTYLE: INT = -20;

const SW_HIDE: INT = 0;
const SW_SHOW: INT = 5;

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

const WS_EX_DLGMODALFRAME = 0x00000001;
const WS_EX_NOPARENTNOTIFY = 0x00000004;
const WS_EX_TOPMOST = 0x00000008;
const WS_EX_ACCEPTFILES = 0x00000010;
const WS_EX_TRANSPARENT = 0x00000020;
const WS_EX_MDICHILD = 0x00000040;
const WS_EX_TOOLWINDOW = 0x00000080;
const WS_EX_WINDOWEDGE = 0x00000100;
const WS_EX_CLIENTEDGE = 0x00000200;
const WS_EX_CONTEXTHELP = 0x00000400;
const WS_EX_RIGHT = 0x00001000;
const WS_EX_LEFT = 0x00000000;
const WS_EX_RTLREADING = 0x00002000;
const WS_EX_LTRREADING = 0x00000000;
const WS_EX_LEFTSCROLLBAR = 0x00004000;
const WS_EX_RIGHTSCROLLBAR = 0x00000000;
const WS_EX_CONTROLPARENT = 0x00010000;
const WS_EX_STATICEDGE = 0x00020000;
const WS_EX_APPWINDOW = 0x00040000;
const WS_EX_LAYERED = 0x00080000;
const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;
const WS_EX_PALETTEWINDOW = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;

const WM_NULL = 0x0000;
const WM_CREATE = 0x0001;
const WM_DESTROY = 0x0002;
const WM_MOVE = 0x0003;
const WM_SIZE = 0x0005;
const WM_ACTIVATE = 0x0006;
const WM_SETFOCUS = 0x0007;
const WM_KILLFOCUS = 0x0008;
const WM_ENABLE = 0x000A;
const WM_SETREDRAW = 0x000B;
const WM_SETTEXT = 0x000C;
const WM_GETTEXT = 0x000D;
const WM_GETTEXTLENGTH = 0x000E;
const WM_PAINT = 0x000F;
const WM_CLOSE = 0x0010;
const WM_QUERYENDSESSION = 0x0011;
pub const WM_QUIT = 0x0012;
const WM_KEYDOWN = 0x0100;
const WM_KEYUP = 0x0101;
const WM_CHAR = 0x0102;
const WM_DEADCHAR = 0x0103;
const WM_SYSKEYDOWN = 0x0104;
const WM_SYSKEYUP = 0x0105;
const WM_SYSCHAR = 0x0106;
const WM_SYSDEADCHAR = 0x0107;
const WM_CONTEXTMENU = 0x007B;
const WM_APP = 0x8000;
const WMAPP_NOTIFYCALLBACK = WM_APP + 1;
const WM_LBUTTONDOWN = 0x0201;
const WM_RBUTTONDOWN = 0x0204;

const PM_NOREMOVE = 0x0000;
pub const PM_REMOVE = 0x0001;
const PM_NOYIELD = 0x0002;

const NIM_ADD = 0x00000000;
const NIM_MODIFY = 0x00000001;
const NIM_DELETE = 0x00000002;
const NIM_SETFOCUS = 0x00000003;
const NIM_SETVERSION = 0x00000004;

const NIF_MESSAGE = 0x00000001;
const NIF_ICON = 0x00000002;
const NIF_TIP = 0x00000004;
const NIF_STATE = 0x00000008;
const NIF_INFO = 0x00000010;
const NIF_GUID = 0x00000020;
const NIF_REALTIME = 0x00000040;
const NIF_SHOWTIP = 0x00000080;

const NOTIFYICON_VERSION_4 = 4;
const LIM_SMALL = 0;

const WNDCLASSEXA = extern struct {
  cbSize: UINT = @sizeOf(WNDCLASSEXA),
  style: UINT,
  lpfnWndProc: WNDPROC,
  cbClsExtra: i32 = 0,
  cbWndExtra: i32 = 0,
  hInstance: HINSTANCE,
  hIcon: ?HICON,
  hCursor: ?HCURSOR,
  hbrBackground: ?HBRUSH,
  lpszMenuName: ?[*:0]const u8,
  lpszClassName: [*:0]const u8,
  hIconSm: ?HICON,
};

const WNDPROC = *const fn (
  hwnd: HWND, 
  uMsg: UINT, 
  wParam: WPARAM, 
  lParam: LPARAM
) callconv(WINAPI) LRESULT;

pub const MSG = extern struct {
  hWnd: ?HWND,
  message: UINT,
  wParam: WPARAM,
  lParam: LPARAM,
  time: DWORD,
  pt: POINT,
  lPrivate: DWORD,
};

pub var ps: PAINTSTRUCT = undefined;
const PAINTSTRUCT = extern struct {
  hdc: HDC,
  fErase: BOOL,
  rcPaint: RECT,
  fRestore: BOOL,
  fIncUpdate: BOOL,
  rgbReserved: [32]BYTE
};

pub const PROCESS_INFORMATION = extern struct {
  hProcess: HANDLE,
  hThread: HANDLE,
  dwProcessId: DWORD,
  dwThreadId: DWORD,
};

const SECURITY_ATTRIBUTES = extern struct {
  nLength: DWORD,
  lpSecurityDescriptor: ?*anyopaque,
  bInheritHandle: BOOL,
};

const STARTUPINFOA = extern struct {
  cb: DWORD,
  lpReserved: ?LPSTR,
  lpDesktop: ?LPSTR,
  lpTitle: ?LPSTR,
  dwX: DWORD,
  dwY: DWORD,
  dwXSize: DWORD,
  dwYSize: DWORD,
  dwXCountChars: DWORD,
  dwYCountChars: DWORD,
  dwFillAttribute: DWORD,
  dwFlags: DWORD,
  wShowWindow: WORD,
  cbReserved2: WORD,
  lpReserved2: ?*BYTE,
  hStdInput: ?HANDLE,
  hStdOutput: ?HANDLE,
  hStdError: ?HANDLE,
};

const NOTIFYICONDATAA = extern struct {
  cbSize: DWORD,
  hWnd: HWND,
  uID: UINT,
  uFlags: UINT,
  uCallbackMessage: UINT,
  hIcon: HICON,
  szTip: [128]CHAR,
  dwState: DWORD,
  dwStateMask: DWORD,
  szInfo: [256]CHAR,
  DUMMYUNIONNAME: extern union {
    uTimeout: UINT,
    uVersion: UINT
  },
  szInfoTitle: [64]CHAR,
  dwInfoFlags: DWORD,
  guidItem: GUID,
  hBalloonIcon: HICON
};


fn LOWORD(l: LONG_PTR) UINT { return @as(u32, @intCast(l)) & 0xFFFF; }
fn HIWORD(l: LONG_PTR) UINT { return (@as(u32, @intCast(l)) >> 16) & 0xFFFF; }

pub fn toUtf8(any: LPWSTR) []u8 {
  const bufU16 = std.unicode.fmtUtf16Le(std.mem.span( any )).data;
  var bufU8: [4096]u8 = undefined;
  for (bufU16, 0..) |char, i| {
    bufU8[i] = @as(u8, @truncate(char));
  }
  return bufU8[0..bufU16.len];
}

pub extern "kernel32" fn GetCommandLineA(
) callconv(WINAPI) ?LPSTR;

pub extern "user32" fn MessageBoxA(
  hWnd: ?HWND, 
  lpText: [*:0]const u8, 
  lpCaption: [*:0]const u8, 
  uType: UINT
) callconv(WINAPI) INT;

pub extern "user32" fn UpdateWindow(
  hWnd: HWND
) callconv(WINAPI) BOOL;

extern "user32" fn LoadCursorA(
  hInstance: ?HINSTANCE,
  lpCursorName: LONG,
) callconv(WINAPI) HCURSOR;

extern "user32" fn RegisterClassExA(
  *const WNDCLASSEXA
) callconv(WINAPI) ATOM;

extern "user32" fn UnregisterClassA(
  lpClassName: [*:0]const u8, 
  hInstance: HINSTANCE
) callconv(WINAPI) BOOL;

extern "user32" fn AdjustWindowRectEx(
  lpRect: *RECT, 
  dwStyle: DWORD,
  bMenu: BOOL,
  dwExStyle: DWORD
) callconv(WINAPI) BOOL;

extern "user32" fn CreateWindowExA(
  dwExStyle: DWORD,
  lpClassName: [*:0]const u8,
  lpWindowName: [*:0]const u8,
  dwStyle: DWORD,
  X: i32,
  Y: i32,
  nWidth: i32,
  nHeight: i32,
  hWindParent: ?HWND,
  hMenu: ?HMENU,
  hInstance: HINSTANCE,
  lpParam: ?LPVOID
) callconv(WINAPI) ?HWND;

pub extern "user32" fn DestroyWindow(
  hWnd: HWND
) callconv(WINAPI) BOOL;

extern "user32" fn GetDC(
  hWnd: ?HWND
) callconv(WINAPI) ?HDC;

extern "user32" fn ReleaseDC(
  hWnd: ?HWND, 
  hDC: HDC
) callconv(WINAPI) i32;

extern "user32" fn PostQuitMessage(
  nExitCode: i32
) callconv(WINAPI) void;

pub extern "user32" fn PeekMessageA(
  lpMsg: *MSG,
  hWnd: ?HWND, 
  wMsgFilterMin: UINT, 
  wMsgFilterMax: UINT, 
  wRemoveMsg: UINT
) callconv(WINAPI) BOOL;

pub extern "user32" fn TranslateMessage(
  lpMsg: *const MSG
) callconv(WINAPI) BOOL;

pub extern "user32" fn DispatchMessageA(
  lpMsg: *const MSG
) callconv(WINAPI) LRESULT;

extern "user32" fn DefWindowProcA(
  hWnd: HWND,
  Msg: UINT,
  wParam: WPARAM,
  lParam: LPARAM
) callconv(WINAPI) LRESULT;

extern "user32" fn BeginPaint(
  hWnd: ?HWND,
  lpPaint: ?*PAINTSTRUCT,
) callconv(WINAPI) ?HDC;

extern "user32" fn FillRect(
  hDC: ?HDC,
  lprc: ?*const RECT,
  hbr: ?HBRUSH
) callconv(WINAPI) INT;

extern "user32" fn EndPaint(
  hWnd: HWND,
  lpPaint: *const PAINTSTRUCT
) callconv(WINAPI) BOOL;

extern "user32" fn GetAsyncKeyState(
  nKey: c_int
) callconv(WINAPI) INT;

extern "kernel32" fn CreateProcessA(
  lpApplicationName: ?LPCSTR,
  lpCommandLine: ?LPSTR,
  lpProcessAttributes: ?*SECURITY_ATTRIBUTES,
  lpThreadAttributes: ?*SECURITY_ATTRIBUTES,
  bInheritHandles: BOOL,
  dwCreationFlags: DWORD,
  lpEnvironment: ?*anyopaque,
  lpCurrentDirectory: ?LPCSTR,
  lpStartupInfo: *STARTUPINFOA,
  lpProcessInformation: *PROCESS_INFORMATION,
) callconv(WINAPI) BOOL;

pub extern "shell32" fn ExtractIconA(
  hInst: HINSTANCE,
  pszExeFileName: LPCSTR,
  nIconIndex: UINT
) callconv(WINAPI) ?HICON;

extern "shell32" fn Shell_NotifyIconA(
  dwMessage: DWORD,
  lpData: *NOTIFYICONDATAA
) callconv(WINAPI) BOOL;

extern "user32" fn DestroyIcon(
  hIcon: HICON,
) callconv(WINAPI) BOOL;

extern "comctl32" fn LoadIconMetric(
  hInst: ?HINSTANCE,
  pszName: LPCSTR,
  lims: INT,
  phico: *HICON
) callconv(WINAPI) HRESULT;

extern "user32" fn SetWindowLongA(
  hWnd: HWND,
  nIndex: INT,
  dwNewLong: LONG
) callconv(WINAPI) HRESULT;

extern "user32" fn GetWindowLongA(
  hWnd: HWND,
  nIndex: INT
) callconv(WINAPI) LONG ;

pub extern "user32" fn ShowWindow(
  hWnd: HWND,
  nCmdShow: INT
) callconv(WINAPI) void;

extern "user32" fn EnumWindows(
  lpEnumFunc: WNDENUMPROC,
  lParam: LPARAM
) callconv(WINAPI) void;

const WNDENUMPROC = *const fn (
  hwnd: HWND, 
  lParam: LPARAM
) callconv(WINAPI) INT;

extern "user32" fn IsWindowVisible(
  hwnd: HWND 
) callconv(WINAPI) BOOL;

extern "user32" fn GetWindowTextA(
  hwnd: HWND,
  lpString: LPSTR,
  nMaxCount: INT
) callconv(WINAPI) INT;

extern "user32" fn GetWindowTextLengthA(
  hWnd: ?HWND
) callconv(WINAPI) INT;

extern "kernel32" fn SetCurrentDirectoryA(
  lpPathName: LPCSTR
) callconv(WINAPI) BOOL;

extern "user32" fn WaitForInputIdle(
  hProcess: HANDLE,
  dwMilliseconds: DWORD
) callconv(WINAPI) DWORD;

extern "kernel32" fn GetConsoleTitleA(
  lpConsoleTitle: LPSTR,
  nSize: DWORD,
) callconv(WINAPI) DWORD;

extern "kernel32" fn FindWindowA(
  lpClassName: ?LPSTR,
  lpWindowName: ?LPSTR,
) callconv(WINAPI) HWND;

extern "user32" fn LoadCursorW(
  hInstance: ?HINSTANCE,
  lpCursorName: LONG,
) callconv(WINAPI) HCURSOR;

pub extern "user32" fn WaitMessage(
) BOOL;

extern "user32" fn GetDpiForWindow(
  hWnd: HWND,
) callconv(WINAPI) UINT;

const SM_CXSCREEN = 0;
const SM_CYSCREEN = 1;
extern "user32" fn GetSystemMetricsForDpi(
  nIndex: INT,
  dpi: UINT
) callconv(WINAPI) INT;

const SWP_NOCOPYBITS = 0x0100;
extern "user32" fn SetWindowPos(
  hWnd: HWND,
  hWndInsertAfter: ?HWND,
  X: INT,
  Y: INT,
  cx: INT,
  cy: INT,
  uFlags: UINT,        
) callconv(WINAPI) BOOL;

pub extern "kernel32" fn GetModuleHandleA(
  lpModuleName: ?[*:0]const u8
) callconv(WINAPI) win.HMODULE;
