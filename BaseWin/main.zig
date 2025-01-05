//!zig-autodoc-section: BaseWin
//!  Template for a Windows program.
// Build using Zig 0.13.0

const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;

  pub const MSG = extern struct {
    hWnd: ?win.HWND,
    message: win.UINT,
    wParam: win.WPARAM,
    lParam: win.LPARAM,
    time: win.DWORD,
    pt: win.POINT,
    lPrivate: win.DWORD,
  };

  pub const WNDPROC = *const fn (hwnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) callconv(WINAPI) win.LRESULT;
  pub const WNDCLASSEXW = extern struct {
    cbSize: win.UINT = @sizeOf(WNDCLASSEXW),
    style: win.UINT,
    lpfnWndProc: win.WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: win.HINSTANCE,
    hIcon: ?win.HICON,
    hCursor: ?win.HCURSOR,
    hbrBackground: ?win.HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
    hIconSm: ?win.HICON,
  };
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

pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  CreateWindow(hInstance, nCmdShow);
  defer _ = ReleaseDC(wnd, wnd_dc);
  defer _ = DestroyWindow(wnd);
  defer _ = UnregisterClassW(wnd_title, hInstance);

  var done: bool = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done) {
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
      _ = TranslateMessage(&msg);
      _ = DispatchMessageW(&msg);
      if (msg.message == WM_QUIT) { done = true; }
    }
    if (done) break;

  }

  return 0;
}

fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  switch (uMsg) {
    WM_DESTROY,
    WM_CLOSE => {
      PostQuitMessage(0);
      return 0;
    },
    WM_PAINT => {
      _ = BeginPaint(hWnd, &ps).?;
      _ = FillRect(wnd_dc, &ps.rcPaint, CreateSolidBrush(wnd_color));
      _ = EndPaint(hWnd, &ps);
      return 0;
    },
    WM_SIZE => {
      g_width = @as(i32, @intCast(LOWORD(lParam)));
      g_height = @as(i32, @intCast(HIWORD(lParam)));
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
    else => _=.{},
  }

  return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

fn CreateWindow(hInstance: win.HINSTANCE, nCmdShow: win.INT) void {
  const wnd_class: win.WNDCLASSEXW = .{
    .cbSize = @sizeOf(win.WNDCLASSEXW),
    .style = CS_DBLCLKS,
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
  _ = AdjustWindowRectEx(&wnd_size, WS_OVERLAPPEDWINDOW, win.FALSE, WS_EX_APPWINDOW);

  wnd = CreateWindowExW(
    WS_EX_APPWINDOW, wnd_classname, wnd_title, WS_OVERLAPPEDWINDOW | WS_VISIBLE,
    CW_USEDEFAULT, CW_USEDEFAULT, 0, 0, null, null, hInstance, null).?;

  wnd_dc = GetDC(wnd).?;
  wnd_dpi = GetDpiForWindow(wnd);
  const xCenter = @divFloor(GetSystemMetricsForDpi(SM_CXSCREEN, wnd_dpi), 2);
  const yCenter = @divFloor(GetSystemMetricsForDpi(SM_CYSCREEN, wnd_dpi), 2);
  const div_w = @divFloor(wnd_size.right, 2);
  const div_h = @divFloor(wnd_size.bottom, 2);
  wnd_size.left = xCenter - div_w;
  wnd_size.top  = yCenter - div_h;
  wnd_size.right = wnd_size.left + div_w;
  wnd_size.bottom = wnd_size.top + div_h;
  _ = SetWindowPos( wnd, null, wnd_size.left, wnd_size.top, wnd_size.right, wnd_size.bottom, SWP_NOCOPYBITS );

  _ = ShowWindow(wnd, nCmdShow);
  _ = UpdateWindow(wnd);
}


// Fix for libc linking error.
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return wWinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}



pub fn LOWORD(l: win.LONG_PTR) win.UINT { return @as(u32, @intCast(l)) & 0xFFFF; }
pub fn HIWORD(l: win.LONG_PTR) win.UINT { return (@as(u32, @intCast(l)) >> 16) & 0xFFFF; }

pub const VK_ESCAPE = 27;
pub const VK_LSHIFT = 160;

pub const CS_DBLCLKS = 0x0008;
pub const WM_QUIT = 0x0012;
pub const WM_NULL = 0x0000;
pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_MOVE = 0x0003;
pub const WM_SIZE = 0x0005;
pub const WM_ACTIVATE = 0x0006;
pub const WM_SETFOCUS = 0x0007;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_ENABLE = 0x000A;
pub const WM_SETREDRAW = 0x000B;
pub const WM_SETTEXT = 0x000C;
pub const WM_GETTEXT = 0x000D;
pub const WM_GETTEXTLENGTH = 0x000E;
pub const WM_PAINT = 0x000F;
pub const WM_CLOSE = 0x0010;
pub const WM_QUERYENDSESSION = 0x0011;
pub const WM_QUERYOPEN = 0x0013;
pub const WM_ERASEBKGND = 0x0014;
pub const WM_SYSCOLORCHANGE = 0x0015;
pub const WM_ENDSESSION = 0x0016;
pub const WM_SHOWWINDOW = 0x0018;
pub const WM_CTLCOLOR = 0x0019;
pub const WM_WININICHANGE = 0x001A;
pub const WM_DEVMODECHANGE = 0x001B;
pub const WM_ACTIVATEAPP = 0x001C;
pub const WM_FONTCHANGE = 0x001D;
pub const WM_TIMECHANGE = 0x001E;
pub const WM_CANCELMODE = 0x001F;
pub const WM_SETCURSOR = 0x0020;
pub const WM_MOUSEACTIVATE = 0x0021;
pub const WM_CHILDACTIVATE = 0x0022;
pub const WM_QUEUESYNC = 0x0023;
pub const WM_GETMINMAXINFO = 0x0024;
pub const WM_PAINTICON = 0x0026;
pub const WM_ICONERASEBKGND = 0x0027;
pub const WM_NEXTDLGCTL = 0x0028;
pub const WM_SPOOLERSTATUS = 0x002A;
pub const WM_DRAWITEM = 0x002B;
pub const WM_MEASUREITEM = 0x002C;
pub const WM_DELETEITEM = 0x002D;
pub const WM_VKEYTOITEM = 0x002E;
pub const WM_CHARTOITEM = 0x002F;
pub const WM_SETFONT = 0x0030;
pub const WM_GETFONT = 0x0031;
pub const WM_SETHOTKEY = 0x0032;
pub const WM_GETHOTKEY = 0x0033;
pub const WM_QUERYDRAGICON = 0x0037;
pub const WM_COMPAREITEM = 0x0039;
pub const WM_GETOBJECT = 0x003D;
pub const WM_COMPACTING = 0x0041;
pub const WM_COMMNOTIFY = 0x0044;
pub const WM_WINDOWPOSCHANGING = 0x0046;
pub const WM_WINDOWPOSCHANGED = 0x0047;
pub const WM_POWER = 0x0048;
pub const WM_COPYGLOBALDATA = 0x0049;
pub const WM_COPYDATA = 0x004A;
pub const WM_CANCELJOURNAL = 0x004B;
pub const WM_NOTIFY = 0x004E;
pub const WM_INPUTLANGCHANGEREQUEST = 0x0050;
pub const WM_INPUTLANGCHANGE = 0x0051;
pub const WM_TCARD = 0x0052;
pub const WM_HELP = 0x0053;
pub const WM_USERCHANGED = 0x0054;
pub const WM_NOTIFYFORMAT = 0x0055;
pub const WM_CONTEXTMENU = 0x007B;
pub const WM_STYLECHANGING = 0x007C;
pub const WM_STYLECHANGED = 0x007D;
pub const WM_DISPLAYCHANGE = 0x007E;
pub const WM_GETICON = 0x007F;
pub const WM_SETICON = 0x0080;
pub const WM_NCCREATE = 0x0081;
pub const WM_NCDESTROY = 0x0082;
pub const WM_NCCALCSIZE = 0x0083;
pub const WM_NCHITTEST = 0x0084;
pub const WM_NCPAINT = 0x0085;
pub const WM_NCACTIVATE = 0x0086;
pub const WM_GETDLGCODE = 0x0087;
pub const WM_SYNCPAINT = 0x0088;
pub const WM_NCMOUSEMOVE = 0x00A0;
pub const WM_NCLBUTTONDOWN = 0x00A1;
pub const WM_NCLBUTTONUP = 0x00A2;
pub const WM_NCLBUTTONDBLCLK = 0x00A3;
pub const WM_NCRBUTTONDOWN = 0x00A4;
pub const WM_NCRBUTTONUP = 0x00A5;
pub const WM_NCRBUTTONDBLCLK = 0x00A6;
pub const WM_NCMBUTTONDOWN = 0x00A7;
pub const WM_NCMBUTTONUP = 0x00A8;
pub const WM_NCMBUTTONDBLCLK = 0x00A9;
pub const WM_NCXBUTTONDOWN = 0x00AB;
pub const WM_NCXBUTTONUP = 0x00AC;
pub const WM_NCXBUTTONDBLCLK = 0x00AD;
pub const WM_INPUT = 0x00FF;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_CHAR = 0x0102;
pub const WM_DEADCHAR = 0x0103;
pub const WM_SYSKEYDOWN = 0x0104;
pub const WM_SYSKEYUP = 0x0105;
pub const WM_SYSCHAR = 0x0106;
pub const WM_SYSDEADCHAR = 0x0107;
pub const WM_UNICHAR = 0x0109;
pub const WM_WNT_CONVERTREQUESTEX = 0x0109;
pub const WM_CONVERTREQUEST = 0x010A;
pub const WM_CONVERTRESULT = 0x010B;
pub const WM_INTERIM = 0x010C;
pub const WM_IME_STARTCOMPOSITION = 0x010D;
pub const WM_IME_ENDCOMPOSITION = 0x010E;
pub const WM_IME_COMPOSITION = 0x010F;
pub const WM_INITDIALOG = 0x0110;
pub const WM_COMMAND = 0x0111;
pub const WM_SYSCOMMAND = 0x0112;
pub const WM_TIMER = 0x0113;
pub const WM_HSCROLL = 0x0114;
pub const WM_VSCROLL = 0x0115;
pub const WM_INITMENU = 0x0116;
pub const WM_INITMENUPOPUP = 0x0117;
pub const WM_SYSTIMER = 0x0118;
pub const WM_MENUSELECT = 0x011F;
pub const WM_MENUCHAR = 0x0120;
pub const WM_ENTERIDLE = 0x0121;
pub const WM_MENURBUTTONUP = 0x0122;
pub const WM_MENUDRAG = 0x0123;
pub const WM_MENUGETOBJECT = 0x0124;
pub const WM_UNINITMENUPOPUP = 0x0125;
pub const WM_MENUCOMMAND = 0x0126;
pub const WM_CHANGEUISTATE = 0x0127;
pub const WM_UPDATEUISTATE = 0x0128;
pub const WM_QUERYUISTATE = 0x0129;
pub const WM_CTLCOLORMSGBOX = 0x0132;
pub const WM_CTLCOLOREDIT = 0x0133;
pub const WM_CTLCOLORLISTBOX = 0x0134;
pub const WM_CTLCOLORBTN = 0x0135;
pub const WM_CTLCOLORDLG = 0x0136;
pub const WM_CTLCOLORSCROLLBAR = 0x0137;
pub const WM_CTLCOLORSTATIC = 0x0138;
pub const WM_MOUSEMOVE = 0x0200;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_LBUTTONDBLCLK = 0x0203;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_RBUTTONDBLCLK = 0x0206;
pub const WM_MBUTTONDOWN = 0x0207;
pub const WM_MBUTTONUP = 0x0208;
pub const WM_MBUTTONDBLCLK = 0x0209;
pub const WM_MOUSEWHEEL = 0x020A;
pub const WM_XBUTTONDOWN = 0x020B;
pub const WM_XBUTTONUP = 0x020C;
pub const WM_XBUTTONDBLCLK = 0x020D;
pub const WM_MOUSEHWHEEL = 0x020E;
pub const WM_PARENTNOTIFY = 0x0210;
pub const WM_ENTERMENULOOP = 0x0211;
pub const WM_EXITMENULOOP = 0x0212;
pub const WM_NEXTMENU = 0x0213;
pub const WM_SIZING = 0x0214;
pub const WM_CAPTURECHANGED = 0x0215;
pub const WM_MOVING = 0x0216;
pub const WM_POWERBROADCAST = 0x0218;
pub const WM_DEVICECHANGE = 0x0219;
pub const WM_MDICREATE = 0x0220;
pub const WM_MDIDESTROY = 0x0221;
pub const WM_MDIACTIVATE = 0x0222;
pub const WM_MDIRESTORE = 0x0223;
pub const WM_MDINEXT = 0x0224;
pub const WM_MDIMAXIMIZE = 0x0225;
pub const WM_MDITILE = 0x0226;
pub const WM_MDICASCADE = 0x0227;
pub const WM_MDIICONARRANGE = 0x0228;
pub const WM_MDIGETACTIVE = 0x0229;
pub const WM_MDISETMENU = 0x0230;
pub const WM_ENTERSIZEMOVE = 0x0231;
pub const WM_EXITSIZEMOVE = 0x0232;
pub const WM_DROPFILES = 0x0233;
pub const WM_MDIREFRESHMENU = 0x0234;
pub const WM_IME_REPORT = 0x0280;
pub const WM_IME_SETCONTEXT = 0x0281;
pub const WM_IME_NOTIFY = 0x0282;
pub const WM_IME_CONTROL = 0x0283;
pub const WM_IME_COMPOSITIONFULL = 0x0284;
pub const WM_IME_SELECT = 0x0285;
pub const WM_IME_CHAR = 0x0286;
pub const WM_IME_REQUEST = 0x0288;
pub const WM_IMEKEYDOWN = 0x0290;
pub const WM_IME_KEYDOWN = 0x0290;
pub const WM_IMEKEYUP = 0x0291;
pub const WM_IME_KEYUP = 0x0291;
pub const WM_NCMOUSEHOVER = 0x02A0;
pub const WM_MOUSEHOVER = 0x02A1;
pub const WM_NCMOUSELEAVE = 0x02A2;
pub const WM_MOUSELEAVE = 0x02A3;
pub const WM_CUT = 0x0300;
pub const WM_COPY = 0x0301;
pub const WM_PASTE = 0x0302;
pub const WM_CLEAR = 0x0303;
pub const WM_UNDO = 0x0304;
pub const WM_RENDERFORMAT = 0x0305;
pub const WM_RENDERALLFORMATS = 0x0306;
pub const WM_DESTROYCLIPBOARD = 0x0307;
pub const WM_DRAWCLIPBOARD = 0x0308;
pub const WM_PAINTCLIPBOARD = 0x0309;
pub const WM_VSCROLLCLIPBOARD = 0x030A;
pub const WM_SIZECLIPBOARD = 0x030B;
pub const WM_ASKCBFORMATNAME = 0x030C;
pub const WM_CHANGECBCHAIN = 0x030D;
pub const WM_HSCROLLCLIPBOARD = 0x030E;
pub const WM_QUERYNEWPALETTE = 0x030F;
pub const WM_PALETTEISCHANGING = 0x0310;
pub const WM_PALETTECHANGED = 0x0311;
pub const WM_HOTKEY = 0x0312;
pub const WM_PRINT = 0x0317;
pub const WM_PRINTCLIENT = 0x0318;
pub const WM_APPCOMMAND = 0x0319;
pub const WM_RCRESULT = 0x0381;
pub const WM_HOOKRCRESULT = 0x0382;
pub const WM_GLOBALRCCHANGE = 0x0383;
pub const WM_PENMISCINFO = 0x0383;
pub const WM_SKB = 0x0384;
pub const WM_HEDITCTL = 0x0385;
pub const WM_PENCTL = 0x0385;
pub const WM_PENMISC = 0x0386;
pub const WM_CTLINIT = 0x0387;
pub const WM_PENEVENT = 0x0388;
pub const WM_CARET_CREATE = 0x03E0;
pub const WM_CARET_DESTROY = 0x03E1;
pub const WM_CARET_BLINK = 0x03E2;
pub const WM_FDINPUT = 0x03F0;
pub const WM_FDOUTPUT = 0x03F1;
pub const WM_FDEXCEPT = 0x03F2;

pub const WS_OVERLAPPED = 0x00000000;
pub const WS_POPUP = 0x80000000;
pub const WS_CHILD = 0x40000000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_CAPTION = WS_BORDER | WS_DLGFRAME;
pub const WS_BORDER = 0x00800000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_VSCROLL = 0x00200000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_GROUP = 0x00020000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_TILED = WS_OVERLAPPED;
pub const WS_ICONIC = WS_MINIMIZE;
pub const WS_SIZEBOX = WS_THICKFRAME;
pub const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
pub const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
pub const WS_EX_APPWINDOW = 0x00040000;
pub const WS_EX_LAYERED = 0x00080000;
pub const WS_EX_WINDOWEDGE = 0x00000100;
pub const WS_EX_CLIENTEDGE = 0x00000200;
pub const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;

pub const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
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

pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: win.INT
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn UpdateWindow(
  hWnd: win.HWND
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn GetDC(
  hWnd: ?win.HWND
) callconv(WINAPI) ?win.HDC;

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

pub extern "user32" fn PostQuitMessage(
  nExitCode: win.INT
) callconv(WINAPI) void;

pub extern "user32" fn DefWindowProcW(
  hWnd: win.HWND,
  Msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(WINAPI) win.LRESULT;

pub extern "user32" fn PostMessageW(
  hWnd: ?win.HWND,
  Msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(WINAPI) win.BOOL;

pub const PM_REMOVE = 0x0001;
pub extern "user32" fn PeekMessageW(
  lpMsg: *win.MSG,
  hWnd: ?win.HWND,
  wMsgFilterMin: win.UINT,
  wMsgFilterMax: win.UINT,
  wRemoveMsg: win.UINT
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn TranslateMessage(
  lpMsg: *const win.MSG
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn DispatchMessageW(
  lpMsg: *const win.MSG
) callconv(WINAPI) win.LRESULT;

pub extern "user32" fn UnregisterClassW(
  lpClassName: [*:0]const u16,
  hInstance: win.HINSTANCE
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn DestroyWindow(
  hWnd: win.HWND
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn ReleaseDC(
  hWnd: ?win.HWND,
  hDC: win.HDC
) callconv(WINAPI) win.INT;

pub extern "user32" fn RegisterClassExW(
  *const win.WNDCLASSEXW
) callconv(WINAPI) win.ATOM;

pub extern "user32" fn AdjustWindowRectEx(
  lpRect: *win.RECT,
  dwStyle: win.DWORD,
  bMenu: win.BOOL,
  dwExStyle: win.DWORD
) callconv(WINAPI) win.BOOL;

pub extern "user32" fn CreateWindowExW(
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
) callconv(WINAPI) ?win.HWND;