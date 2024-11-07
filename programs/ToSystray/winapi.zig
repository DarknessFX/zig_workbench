//!zig-autodoc-section: Windows API
//! Windows API
const std = @import("std");
usingnamespace std.os.windows;
usingnamespace std.os.windows.kernel32;

pub const wnd = struct {
  pub var handle: HWND = undefined;
  pub var hInstance: HINSTANCE = undefined;
  pub var path: [*:0]const u8 = "";
  pub var title: [*:0]const u8= "";
  pub var title_buf: [255:0]u8 = std.mem.zeroes([255:0]u8);
  pub var size: RECT= .{
    .left=0, 
    .top=0, 
    .right=1280, 
    .bottom=720 
  };
  pub var width: INT = 1280;
  pub var height: INT = 720;
  pub var hdc: HDC = undefined;
  pub var dpi: UINT = 0;
  pub var hRC: HGLRC = undefined;
  pub var msg: MSG = std.mem.zeroes(MSG);
  pub var class: WNDCLASSEXA = std.mem.zeroes(WNDCLASSEXA);
  pub var icon: HICON = undefined;
  pub var iconsmall: HICON = undefined;
  pub var guid: GUID = .{
    .Data1 = 0xFF6E5556,
    .Data2 = 0xB53F,
    .Data3 = 0x4B8A,
    .Data4 = .{0x81, 0x63, 0x32, 0x4C, 0x8C, 0x9E, 0x93, 0x98}
  };
  pub var appProcess: DWORD = undefined;
  pub var appHwnd: HWND = undefined;
  pub var consolehwnd: HWND = undefined;
  pub var visible: bool = false;
  pub var exit: bool = false;
};

pub fn Create() ?void {
  CreateWindow(wnd.hInstance) 
    orelse return null;

  _ = UpdateWindow(wnd.handle);
}

fn CreateWindow(hInstance: HINSTANCE) ?void {
  const wndpath = toRemoveQuotes(wnd.path);
  if ( @as(usize, @intFromPtr(ExtractIconA(hInstance, wndpath, 0))) > 0) {
    wnd.icon = ExtractIconA(hInstance, wndpath, 0).?;
  }
  wnd.class = .{
    .cbSize = @sizeOf(WNDCLASSEXA),
    .style = CS_DBLCLKS | CS_OWNDC,
    .lpfnWndProc = WindowProc,
    .cbClsExtra = 0, 
    .cbWndExtra = 0,
    .hInstance = hInstance,
    .hIcon = wnd.icon, 
    .hCursor = LoadCursorA(null, IDC_ARROW),
    .hbrBackground = null, 
    .lpszMenuName = null,
    .lpszClassName = wnd.title,
    .hIconSm = null,
  };
  _ = RegisterClassExA(&wnd.class);
  _ = AdjustWindowRectEx(&wnd.size, WS_OVERLAPPEDWINDOW, FALSE, WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
  // wnd.title, WS_OVERLAPPEDWINDOW | WS_VISIBLE
  if (CreateWindowExA(
    WS_EX_APPWINDOW | WS_EX_WINDOWEDGE, wnd.title, wnd.title, WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, CW_USEDEFAULT, 0, 0, 
    null, null, hInstance, null)
    ) |hwnd| {
       wnd.handle = hwnd; 
  } else {
    return null;
  }
  wnd.hdc = GetDC(wnd.handle).?;
}

pub fn CreateProcess(CmdLine: []const u8) ?*PROCESS_INFORMATION {
  wnd.title_buf = toStringBuffer(wnd.title);
  wnd.guid.Data4[7] = GetRandom();

  _ = SetCurrentDirectoryA(toPathString(wnd.path)); 

  var CmdLine_: ?[*:0]u8 = undefined;
  var cmdlinebuf = std.mem.zeroes([255]u8); _ = &cmdlinebuf;
  const cmdlineUpper = std.ascii.upperString(&cmdlinebuf, CmdLine);
  if (std.mem.indexOf(u8, cmdlineUpper, "BAT") != null) {
    _ = ShowWindow(wnd.consolehwnd, SW_SHOW);
  }
  cmdlinebuf = std.mem.zeroes([255]u8);
  const cmdline_ins = "CMD.EXE /C \"";
  var idx: u8 = 0;
  while (idx < 255) : (idx += 1) {
    if (idx < cmdline_ins.len) {
      cmdlinebuf[idx] = cmdline_ins[idx];
    } else {
      if (idx - cmdline_ins.len >= CmdLine.len) break;
      cmdlinebuf[idx] = CmdLine[idx - cmdline_ins.len];
    }
  }
  cmdlinebuf[idx] = '\"';
  CmdLine_ = @as(?[*:0]u8, @ptrCast(@constCast(&cmdlinebuf)));

  var startInfo: STARTUPINFOA = std.mem.zeroes(STARTUPINFOA);
  var lpProcessInformation: PROCESS_INFORMATION = std.mem.zeroes(PROCESS_INFORMATION);
  startInfo.cb = @sizeOf(STARTUPINFOA);

  const result: BOOL = CreateProcessA(null, 
    CmdLine_, null, null, FALSE, 0, null, null,
    &startInfo, &lpProcessInformation 
  );
  if (result == FALSE) return null;

  _ = WaitForInputIdle( lpProcessInformation.hProcess, INFINITE );
  std.time.sleep(std.time.ns_per_s * 0.5);
  var retries: u8 = 0;
  while (wnd.appHwnd == undefined) {
    ProcessMsg();
    EnumWindows(EnumWindowProc, 0);
    std.time.sleep(std.time.ns_per_s * 1);
    retries += 1;
    if (retries > 15) return null;
  }

  const wndstyle: LONG = GetWindowLongA(wnd.appHwnd, GWL_EXSTYLE);
  _ = SetWindowLongA(wnd.appHwnd, GWL_EXSTYLE, wndstyle | WS_VISIBLE);
  wnd.appProcess = lpProcessInformation.dwProcessId;
  wnd.visible = true;
  return &lpProcessInformation;
}

pub fn ProcessMsg() void {
  while (PeekMessageA(&wnd.msg, null, 0, 0, PM_REMOVE) != 0) {
    _ = TranslateMessage(&wnd.msg);
    _ = DispatchMessageA(&wnd.msg);
    if (wnd.msg.message == WM_QUIT) { wnd.exit = true;  }
  }
}

pub export fn EnumWindowProc(hwnd: HWND, lParam: LPARAM) 
  callconv(WINAPI) INT { _ = &lParam;

  if (IsWindowVisible(hwnd) == FALSE) return TRUE;

  const wndtext_len: usize = 
    @as(usize, @intCast(GetWindowTextLengthA(hwnd))); _ = &wndtext_len;
  if (wndtext_len == 0) return TRUE;

  var wndtext: [255:0]u8 = std.mem.zeroes([255:0]u8); _ = &wndtext;
  _ = GetWindowTextA(hwnd, &wndtext, 255);

  var wndtextbuf = std.mem.zeroes([255]u8); _ = &wndtextbuf;
  const wndtextUpper = std.ascii.upperString(&wndtextbuf, &wndtext);
  var wndtitlebuf = std.mem.zeroes([255]u8); _ = &wndtitlebuf;
  const wndtitletmp = std.mem.sliceTo(wnd.title, 0);
  var count: usize = 0;
  for (wndtitletmp, 0..wndtitletmp.len) |char, idx| {
    wndtitlebuf[idx] = std.ascii.toUpper(char);
    count = idx;
  }
  const wndtmp: []const u8 = wndtitlebuf[0..count];
  if (std.mem.indexOf(u8, wndtextUpper, wndtmp) != null) {
    wnd.appHwnd = hwnd;
    return FALSE;
  }

  return TRUE;
}

fn AddNotificationIcon(hWnd: HWND) void {
  var tooltip: [128]CHAR = std.mem.zeroes([128]CHAR);
  const tooltip_msg = "Click to toogle Show/Hide program.\nRight-click to remove systray icon.";
  @memcpy(tooltip[0..tooltip_msg.len], tooltip_msg);

  var nid: NOTIFYICONDATAA = std.mem.zeroes(NOTIFYICONDATAA);
  nid.cbSize = @sizeOf(NOTIFYICONDATAA);
  nid.hWnd = hWnd;
  nid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP | NIF_GUID;
  nid.uCallbackMessage = WMAPP_NOTIFYCALLBACK;
  nid.guidItem = wnd.guid;
  nid.hIcon = wnd.icon;
  nid.szTip = tooltip;
  _ = Shell_NotifyIconA(NIM_ADD, &nid);
  nid.DUMMYUNIONNAME.uVersion = NOTIFYICON_VERSION_4;
  _ = Shell_NotifyIconA(NIM_SETVERSION, &nid);
}

fn DeleteNotificationIcon() void {
  var nid: NOTIFYICONDATAA = std.mem.zeroes(NOTIFYICONDATAA);
  nid.cbSize = @sizeOf(NOTIFYICONDATAA);
  nid.uFlags = NIF_GUID;
  nid.guidItem = wnd.guid;
  _ = Shell_NotifyIconA(NIM_DELETE, &nid);
}


fn WindowProc( hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM ) callconv(WINAPI) LRESULT {
  switch (uMsg) {
    WM_CREATE => {
      AddNotificationIcon(hWnd);
    },
    WM_DESTROY => {
      PostQuitMessage(0);
      return 0;
    },
    WM_PAINT => {
      var ps: PAINTSTRUCT = undefined;
      const hdc: HDC =  BeginPaint(hWnd, &ps) orelse undefined;
      _ = FillRect(hdc, &ps.rcPaint, @ptrFromInt( COLOR_WINDOW+1));
      _ = EndPaint(hWnd, &ps);
    },
    WM_SIZE => {
      wnd.width = @as(INT, @intCast(LOWORD(lParam)));
      wnd.height = @as(INT, @intCast(HIWORD(lParam)));
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
    WMAPP_NOTIFYCALLBACK => {
      switch (LOWORD(lParam)) {
        WM_LBUTTONDOWN => {
          TogleWindow();
        },
        WM_RBUTTONDOWN => {
          if (!wnd.visible) TogleWindow();
          wnd.exit = true;
          return 0;
        },
        WM_CONTEXTMENU => {
          // POINT const pt = { LOWORD(wParam), HIWORD(wParam) };
          // ShowContextMenu(hwnd, pt);          
        },
        else => {},
      }
    },
    else => _=.{},
  }

  return DefWindowProcA(hWnd, uMsg, wParam, lParam);
}

pub fn Destroy() void {
  _ = ReleaseDC(wnd.handle, wnd.hdc);
  _ = UnregisterClassA(wnd.title, wnd.hInstance);
  _ = DestroyWindow(wnd.handle);
}

pub fn CloseAppHandles(hProcess: HANDLE, hThread: HANDLE) void {
  std.os.windows.CloseHandle(hThread);
  std.os.windows.CloseHandle(hProcess);
  _ = DestroyIcon(wnd.icon);
  DeleteNotificationIcon();
}

fn TogleWindow() void {
  wnd.visible = !wnd.visible;
  ShowWindow(wnd.appHwnd, if (wnd.visible) SW_SHOW else SW_HIDE);
}

inline fn toStringA(string: []const u8) [*:0]const u8 { return @as([*:0]const u8, @ptrCast(string)); }

fn toStringBuffer(string: [*:0]const u8) [255:0]u8 {
  var ret: [255:0]u8 = std.mem.zeroes([255:0]u8); 
  for (std.mem.span(string), 0..) |char, idx| {
    ret[idx] = char;
  }
  return ret;
}

fn toPathString(string: [*:0]const u8) [*:0]const u8 {
  var ret: [255]u8 = std.mem.zeroes([255]u8); 
  var count: usize = 0;
  var offset: usize = 0;
  for (std.mem.span(string), 0..) |char, idx| {
    if (char == '\"') {
      offset += 1;
      continue;
    }
    ret[idx - offset] = char;
    count = idx - offset;
  }
  const rettmp: []const u8 = ret[0..(count+1)];
  const dirname = std.heap.page_allocator.dupe(u8, std.fs.path.dirname(rettmp).?) catch unreachable;
  const dirappend = '\\';
  ret = std.mem.zeroes([255]u8); count = 0; offset = 0;
  for (dirname, 0..dirname.len) |char, idx| {
    ret[idx] = char;
    count = idx;
  }
  ret[count + 1] = dirappend;
  const ret_cpy = std.heap.page_allocator.dupe(u8, &ret) catch unreachable;
  const ret2: [*:0]const u8 = @as([*:0]const u8, @ptrCast(ret_cpy));
  return ret2;
}

inline fn toRetCopy(any: anytype) @TypeOf(any) { 
  const any_cpy = std.heap.page_allocator.dupe(
    @typeInfo(@TypeOf(any)).Pointer.child, any) catch unreachable;
  return @as(@TypeOf(any), @ptrCast(any_cpy));
}

fn GetRandom() u8 {
  var prng = std.rand.DefaultPrng.init(blk: {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    break :blk seed;
  });
  const rand = prng.random();
  return rand.int(u8);
}

fn toRemoveQuotes(string: [*:0]const u8) [*:0]const u8 {
  const str2 = std.mem.sliceTo(string, 0);
  var strbuf: [255]u8 = std.mem.zeroes([255]u8);
  var offset: u8 = 0;
  for (str2, 0..str2.len) |char, idx| {
    if (char == '\"') {
      offset += 1;
      continue;
    }
    strbuf[idx - offset] = char;
  }
  const strtmp: []const u8 = &strbuf;
  const strtmp2 = toRetCopy(strtmp);
  return toStringA(strtmp2);
}

pub fn HideConsoleWindow() void {
  const BUF_TITLE = 1024;
  var pszWindowTitle: [BUF_TITLE:0]CHAR = std.mem.zeroes([BUF_TITLE:0]CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  wnd.consolehwnd = FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(wnd.consolehwnd, SW_HIDE);
}

const TRUE = std.os.windows.TRUE;
const FALSE = std.os.windows.FALSE;

pub const WINAPI = std.os.windows.WINAPI;
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
const WM_QUIT = 0x0012;
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
const PM_REMOVE = 0x0001;
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

const MSG = extern struct {
  hWnd: ?HWND,
  message: UINT,
  wParam: WPARAM,
  lParam: LPARAM,
  time: DWORD,
  pt: POINT,
  lPrivate: DWORD,
};

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

extern "user32" fn UpdateWindow(
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

extern "user32" fn DestroyWindow(
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

extern "user32" fn PeekMessageA(
  lpMsg: *MSG,
  hWnd: ?HWND, 
  wMsgFilterMin: UINT, 
  wMsgFilterMax: UINT, 
  wRemoveMsg: UINT
) callconv(WINAPI) BOOL;

extern "user32" fn TranslateMessage(
  lpMsg: *const MSG
) callconv(WINAPI) BOOL;

extern "user32" fn DispatchMessageA(
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

extern "user32" fn ShowWindow(
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