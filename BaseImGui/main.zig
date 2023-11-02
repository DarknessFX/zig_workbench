const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
  usingnamespace std.os.windows.gdi32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_microui/lib/SDL2/include/SDL.h"); 
const im = @cImport({
  @cInclude("lib/imgui/cimgui.h");
  @cInclude("lib/imgui/cimgui_impl_opengl3.h");
  @cInclude("lib/imgui/cimgui_impl_win32.h");
});

const gl = @cImport({
  @cInclude("lib/opengl/gl.h");
});

var wnd: win.HWND = undefined;
const wnd_title = L("BaseImGui");
var wnd_size: win.RECT = .{ .left=0, .top=0, .right=1200, .bottom=800 };
var wnd_dc: win.HDC = undefined;
var wnd_dpi: win.UINT = 0;
var wnd_hRC: win.HGLRC = undefined;

const WGL_WindowData = struct  { hDC: gl.HDC };
var gl_HWND: gl.HWND = undefined;
var g_hRC: gl.HGLRC = undefined;
var g_MainWindow: WGL_WindowData = std.mem.zeroes(WGL_WindowData);
var g_width: i16 = 1200;
var g_height: i16 = 800;

const ImVec4 = struct {
  x: f32,
  y: f32,
  w: f32,
  z: f32
};

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hPrevInstance;
  _ = pCmdLine;

  CreateWindow(hInstance);
  defer _ = win.ReleaseDC(wnd, wnd_dc);
  defer _ = win.UnregisterClassW(wnd_title, hInstance);
  defer _ = win.DestroyWindow(wnd);

  @setRuntimeSafety(false);
  gl_HWND = @as(gl.HWND, @alignCast(@ptrCast(wnd)));
  @setRuntimeSafety(true);
  
  _ = CreateDeviceWGL(wnd, &g_MainWindow);
  _ = gl.wglMakeCurrent(g_MainWindow.hDC, g_hRC);

  _ = win.ShowWindow(wnd, nCmdShow);
  _ = win.updateWindow(wnd) catch undefined;

  _ = im.ImGui_CreateContext(null);
  var io: *im.struct_ImGuiIO_t = im.ImGui_GetIO();
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard;   // Enable Keyboard Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad;    // Enable Gamepad Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable;       // Enable Docking
//  io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable;     // Enable Multi-Viewport / Platform Windows

  im.ImGui_StyleColorsDark(null);

  var style: im.ImGuiStyle = im.ImGui_GetStyle().*;
  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
    style.WindowRounding = 0.0;
    style.Colors[im.ImGuiCol_WindowBg].w = 1.0;
  }

  _ = im.cImGui_ImplWin32_InitForOpenGL(wnd);
  _ = im.cImGui_ImplOpenGL3_Init();

  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0)
  {
    var platform_io: *im.struct_ImGuiPlatformIO_t = im.ImGui_GetPlatformIO();
    platform_io.Renderer_CreateWindow = Hook_Renderer_CreateWindow;
    platform_io.Renderer_DestroyWindow = Hook_Renderer_DestroyWindow;
    platform_io.Renderer_SwapBuffers = Hook_Renderer_SwapBuffers;
    platform_io.Platform_RenderWindow = Hook_Platform_RenderWindow;
  }


  var show_demo_window = true;
  var show_another_window = false;
  var clear_color: ImVec4 = .{ .x=0.45, .y=0.55, .w=0.60, .z=1.00 };
  var f: f32 = 0.0;
  var counter: u16 = 0;

  var done = false;
  var msg: win.MSG = std.mem.zeroes(win.MSG);
  while (!done)
  {
    while (win.PeekMessageA(&msg, null, 0, 0, win.PM_REMOVE) != 0) {
      _ = win.TranslateMessage(&msg);
      _ = win.DispatchMessageW(&msg);
      if (msg.message == win.WM_QUIT) { done = true;  }
    }
    if (done) break;

    im.cImGui_ImplOpenGL3_NewFrame();
    im.cImGui_ImplWin32_NewFrame();
    im.ImGui_NewFrame();

    _ = im.ImGui_DockSpaceOverViewport();
    
    if (show_demo_window)
      im.ImGui_ShowDemoWindow(&show_demo_window);

    {
      _ = im.ImGui_Begin("Hello, world!", null, im.ImGuiWindowFlags_NoSavedSettings);
      im.ImGui_Text("This is some useful text.");
      _ = im.ImGui_Checkbox("Demo Window", &show_demo_window);
      _ = im.ImGui_Checkbox("Another Window", &show_another_window);

      _ = im.ImGui_SliderFloat("float", &f, 0.0, 1.0);
      _ = im.ImGui_ColorEdit3("clear color", @as([*c]f32,  &clear_color.x), 0);

      if (im.ImGui_Button("Button"))
          counter += 1;
      im.ImGui_SameLine();
      im.ImGui_Text("counter = %d", counter);

      im.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate);
      im.ImGui_End();
    }

    if (show_another_window) {
      _ = im.ImGui_Begin("Hello, world!", &show_another_window, im.ImGuiWindowFlags_NoSavedSettings);
      im.ImGui_Text("Hello from another window");
      if (im.ImGui_Button("Close Me"))
        show_another_window = false;
      im.ImGui_End();
    }

    im.ImGui_Render();
    gl.glViewport(0, 0, g_width, g_height);
    gl.glClearColor(clear_color.x, clear_color.y, clear_color.w, clear_color.z);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    im.cImGui_ImplOpenGL3_RenderDrawData(im.ImGui_GetDrawData());

    if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
      im.ImGui_UpdatePlatformWindows();
      im.ImGui_RenderPlatformWindowsDefault();
      _ = gl.wglMakeCurrent(g_MainWindow.hDC, g_hRC);
    }

    _ = gl.SwapBuffers(g_MainWindow.hDC);
  }

  im.cImGui_ImplOpenGL3_Shutdown();
  im.cImGui_ImplWin32_Shutdown();
  im.ImGui_DestroyContext(null);

  CleanupDeviceWGL(wnd, &g_MainWindow);
  _ = gl.wglDeleteContext(g_hRC);
  return 0;
}

pub extern fn cImGui_ImplWin32_WndProcHandler(
  hWnd: win.HWND,
  msg: win.UINT,
  wParam: win.WPARAM,
  lParam: win.LPARAM
) callconv(.C) win.LRESULT;

fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
  if (cImGui_ImplWin32_WndProcHandler(hWnd, uMsg, wParam, lParam) != 0) { return 1; }

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
    win.WM_SIZE => {
      wnd_size.right = @as(i32, @intCast(LOWORD(lParam)));
      wnd_size.bottom = @as(i32, @intCast(HIWORD(lParam)));
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


fn CreateWindow(hInstance: win.HINSTANCE) void {
  const wnd_class: win.WNDCLASSEXW = .{
    .cbSize = @sizeOf(win.WNDCLASSEXW),
    .style = win.CS_DBLCLKS | win.CS_OWNDC,
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
  _ = win.AdjustWindowRectEx(&wnd_size, win.WS_OVERLAPPEDWINDOW, win.FALSE, win.WS_EX_APPWINDOW | win.WS_EX_WINDOWEDGE);
  wnd = win.CreateWindowExW(
    win.WS_EX_APPWINDOW | win.WS_EX_WINDOWEDGE, wnd_title, wnd_title, win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
    win.CW_USEDEFAULT, win.CW_USEDEFAULT, 0, 0, 
    null, null, hInstance, null).?;

  wnd_dc = win.GetDC(wnd).?;
  var dpi = GetDpiForWindow(wnd);
  var xCenter = @divFloor(GetSystemMetricsForDpi(SM_CXSCREEN, dpi), 2);
  var yCenter = @divFloor(GetSystemMetricsForDpi(SM_CYSCREEN, dpi), 2);
  wnd_size.left = xCenter - @divFloor(g_width, 2);
  wnd_size.top  = yCenter - @divFloor(g_height, 2);
  wnd_size.right = wnd_size.left + @divFloor(g_width, 2);
  wnd_size.bottom = wnd_size.top + @divFloor(g_height, 2);
  _ = SetWindowPos( wnd, null, wnd_size.left, wnd_size.top, wnd_size.right, wnd_size.bottom, SWP_NOCOPYBITS );
}

fn CreateDeviceWGL(hWnd: win.HWND , data: *WGL_WindowData) bool {
  const hDc = win.GetDC(wnd).?;
  var pfd: win.PIXELFORMATDESCRIPTOR = std.mem.zeroes(win.PIXELFORMATDESCRIPTOR);
  const pfd_size = @sizeOf(win.PIXELFORMATDESCRIPTOR);
  pfd.nSize = pfd_size;
  pfd.nVersion = 1;
  pfd.dwFlags = gl.PFD_DRAW_TO_WINDOW | gl.PFD_SUPPORT_OPENGL | gl.PFD_DOUBLEBUFFER;
  pfd.iPixelType = gl.PFD_TYPE_RGBA;
  pfd.cColorBits = 32;

  const pf = win.ChoosePixelFormat(hDc, &pfd);
  if (pf == 0) { return false; }
  if (win.SetPixelFormat(hDc, pf, &pfd) == false) { return false; }

  _ = win.ReleaseDC(hWnd, hDc);

  @setRuntimeSafety(false);
  var glhwnd = @as(gl.HWND, @alignCast(@ptrCast(hWnd)));
  @setRuntimeSafety(true);
  data.hDC = gl.GetDC(glhwnd);
  if (g_hRC == null) { g_hRC = gl.wglCreateContext(data.hDC); }
  return true;
}

fn CleanupDeviceWGL(hWnd: win.HWND , data: *WGL_WindowData) void {
  _ = hWnd;
  _ = data;

  _ = gl.wglMakeCurrent(null, null);
}

var g_viewport_hwnd: win.HWND = undefined;
var g_viewport_dc: win.HDC = undefined;

fn Hook_Renderer_CreateWindow(viewport: [*c]im.ImGuiViewport) callconv(.C) void {
  if (viewport.*.PlatformHandle != null and viewport.*.RendererUserData == null) {
    var data: WGL_WindowData = std.mem.zeroes(WGL_WindowData);
    _ = CreateDeviceWGL(@as(win.HWND, @ptrCast(viewport.*.PlatformHandle.?)), &data);
    viewport.*.RendererUserData = &data;
  }
}

fn Hook_Renderer_DestroyWindow(viewport: [*c]im.ImGuiViewport) callconv(.C) void {
  if (viewport.*.RendererUserData != null) {
    CleanupDeviceWGL(
      @as(win.HWND, @ptrCast(viewport.*.PlatformHandle.?)),
      @as(*WGL_WindowData, @alignCast(@ptrCast(viewport.*.RendererUserData.?)))
    );
    viewport.*.RendererUserData = null;
  }
}

fn Hook_Platform_RenderWindow(viewport: [*c]im.ImGuiViewport, pvoid: ?*anyopaque) callconv(.C) void {
  _ = pvoid;
  if (viewport.*.RendererUserData != null) {
    var data = @as(*WGL_WindowData, @alignCast(@ptrCast(viewport.*.RendererUserData.?))); 
    _ = gl.wglMakeCurrent(data.hDC, g_hRC);
  }
}

fn Hook_Renderer_SwapBuffers(viewport: [*c]im.ImGuiViewport, pvoid: ?*anyopaque) callconv(.C) void {
  _ = pvoid;
  if (viewport.*.RendererUserData != null) {
    var data = @as(*WGL_WindowData, @alignCast(@ptrCast(viewport.*.RendererUserData.?))); 
    _ = win.SwapBuffers(@as(win.HDC, @alignCast(@ptrCast(data.hDC))));

  }
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
