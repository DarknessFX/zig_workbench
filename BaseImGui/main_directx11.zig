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
//   @cInclude("C:/zig_workbench/lib/SDL2/include/SDL.h"); 
const im = @cImport({
  @cInclude("lib/imgui/cimgui.h");
  @cInclude("lib/imgui/cimgui_impl_dx11.h");
  @cInclude("lib/imgui/cimgui_impl_win32.h");
});

const dx = @cImport({
  @cInclude("lib/DX11/DX11.h");
});

var wnd: win.HWND = undefined;
const wnd_title = L("BaseImGui");
var wnd_size: win.RECT = .{ .left=0, .top=0, .right=1280, .bottom=720 };
var wnd_dc: win.HDC = undefined;
var wnd_dpi: win.UINT = 0;
var wnd_hRC: win.HGLRC = undefined;

var g_width: win.INT = 1280;
var g_height: win.INT = 720;
var g_ResizeWidth: win.UINT = 0;
var g_ResizeHeight: win.UINT = 0;
var g_pd3dDevice: ?*dx.ID3D11Device = null;
var g_pd3dDeviceContext: ?*dx.ID3D11DeviceContext = null;
var g_pSwapChain: ?*dx.IDXGISwapChain = null;
var g_mainRenderTargetView: ?*dx.ID3D11RenderTargetView = null;

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

    if (!CreateDeviceD3D(wnd)) {
      CleanupDeviceD3D();
      return 1;
    }

  _ = win.ShowWindow(wnd, nCmdShow);
  _ = win.updateWindow(wnd) catch undefined;

  _ = im.ImGui_CreateContext(null);
  var io: *im.struct_ImGuiIO_t = im.ImGui_GetIO();
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard;   // Enable Keyboard Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad;    // Enable Gamepad Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable;       // Enable Docking
  io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable;     // Enable Multi-Viewport / Platform Windows

  im.ImGui_StyleColorsDark(null);

  var style: im.ImGuiStyle = im.ImGui_GetStyle().*;
  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
    style.WindowRounding = 0.0;
    style.Colors[im.ImGuiCol_WindowBg].w = 1.0;
  }

  _ = im.cImGui_ImplWin32_Init(wnd);
  _ = im.cImGui_ImplDX11_Init(
    @as(?*im.ID3D11Device, @ptrCast(g_pd3dDevice)), 
    @as(?*im.ID3D11DeviceContext, @ptrCast(g_pd3dDeviceContext))
  );

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

    if (g_ResizeWidth != 0 and g_ResizeHeight != 0) {
      CleanupRenderTarget();
      _ = g_pSwapChain.?.lpVtbl.*.ResizeBuffers.?(g_pSwapChain, 0, g_ResizeWidth, g_ResizeHeight, dx.DXGI_FORMAT_UNKNOWN, 0);
      g_ResizeWidth = 0; g_ResizeHeight = 0;
      CreateRenderTarget();
    }

    im.cImGui_ImplDX11_NewFrame();
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
    g_pd3dDeviceContext.?.lpVtbl.*.OMSetRenderTargets.?(g_pd3dDeviceContext, 1, &g_mainRenderTargetView, null);
    g_pd3dDeviceContext.?.lpVtbl.*.ClearRenderTargetView.?(g_pd3dDeviceContext, g_mainRenderTargetView, @as([*c]f32,  &clear_color.x));
    im.cImGui_ImplDX11_RenderDrawData(im.ImGui_GetDrawData());

    if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
      im.ImGui_UpdatePlatformWindows();
      im.ImGui_RenderPlatformWindowsDefault();
    }

    _ = g_pSwapChain.?.lpVtbl.*.Present.?(g_pSwapChain, 1, 0);
  }

  im.cImGui_ImplDX11_Shutdown();
  im.cImGui_ImplWin32_Shutdown();
  im.ImGui_DestroyContext(null);

  CleanupDeviceD3D();
  return 0;
}

// DIRECTX 11
fn CreateDeviceD3D(hWnd: win.HWND) bool { 
  var sd = std.mem.zeroes(dx.DXGI_SWAP_CHAIN_DESC);
  sd.BufferCount = 2;
  sd.BufferDesc.Width = 0;
  sd.BufferDesc.Height = 0;
  sd.BufferDesc.Format = dx.DXGI_FORMAT_R8G8B8A8_UNORM;
  sd.BufferDesc.RefreshRate.Numerator = 60;
  sd.BufferDesc.RefreshRate.Denominator = 1;
  sd.Flags = dx.DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
  sd.BufferUsage = dx.DXGI_USAGE_RENDER_TARGET_OUTPUT;
  @setRuntimeSafety(false);
  sd.OutputWindow = @as(dx.HWND, @alignCast(@ptrCast(hWnd)));
  @setRuntimeSafety(true);
  sd.SampleDesc.Count = 1;
  sd.SampleDesc.Quality = 0;
  sd.Windowed = dx.TRUE;
  sd.SwapEffect = dx.DXGI_SWAP_EFFECT_DISCARD;

  var createDeviceFlags: dx.UINT  = 0;
  //createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
  var featureLevel: dx.D3D_FEATURE_LEVEL = undefined;
  const featureLevelArray = &[_]dx.D3D_FEATURE_LEVEL{
    dx.D3D_FEATURE_LEVEL_11_0,
    dx.D3D_FEATURE_LEVEL_10_0
  };
  var res: dx.HRESULT = dx.D3D11CreateDeviceAndSwapChain(null, dx.D3D_DRIVER_TYPE_HARDWARE, 
    null, createDeviceFlags, featureLevelArray, 2, 
    dx.D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice,
    &featureLevel, &g_pd3dDeviceContext);

  if (res == dx.DXGI_ERROR_UNSUPPORTED) { // Try high-performance WARP software driver if hardware is not available.
    res = dx.D3D11CreateDeviceAndSwapChain(null, dx.D3D_DRIVER_TYPE_WARP, 
      null, createDeviceFlags, featureLevelArray, 2, 
      dx.D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, 
      &featureLevel, &g_pd3dDeviceContext);
  }
  if (res != dx.S_OK)
      return false;

  CreateRenderTarget();
  return true; 
}

fn CleanupDeviceD3D() void {
  CleanupRenderTarget();
  _ = g_pSwapChain.?.lpVtbl.*.Release.?(g_pSwapChain);
  _ = g_pd3dDeviceContext.?.lpVtbl.*.Release.?(g_pd3dDeviceContext);
  _ = g_pd3dDevice.?.lpVtbl.*.Release.?(g_pd3dDevice);
  g_pSwapChain = null;
  g_pd3dDeviceContext = null;
  g_pd3dDevice = null;
}

fn CreateRenderTarget() void {
  var pBackBuffer: ?*dx.ID3D11Texture2D = null;

  _ = g_pSwapChain.?.lpVtbl.*.GetBuffer.?(g_pSwapChain, 0,  &dx.IID_ID3D11Texture2D, @as([*c]?*anyopaque, @ptrCast(&pBackBuffer)));
  _ = g_pd3dDevice.?.lpVtbl.*.CreateRenderTargetView.?(g_pd3dDevice, @as([*c]dx.ID3D11Resource, @ptrCast(pBackBuffer.?)), null, &g_mainRenderTargetView);
  _ = pBackBuffer.?.lpVtbl.*.Release.?(pBackBuffer);
}

fn CleanupRenderTarget() void {
  if (g_mainRenderTargetView) |mRTV| {
    _ = mRTV.lpVtbl.*.Release.?(g_mainRenderTargetView);
    g_mainRenderTargetView = null;
  }
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
      g_ResizeWidth = LOWORD(lParam);
      g_ResizeHeight = HIWORD(lParam);
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
    WM_DPICHANGED => {
      if (im.ImGui_GetIO().*.ConfigFlags & im.ImGuiConfigFlags_DpiEnableScaleViewports != 0) {
        //const int dpi = HIWORD(wParam);
        //printf("WM_DPICHANGED to %d (%.0f%%)\n", dpi, (float)dpi / 96.0f * 100.0f);
        const suggested_rect: *win.RECT  = @as(*win.RECT, @constCast(@ptrCast(&lParam)));
        _ = SetWindowPos(hWnd, null, suggested_rect.left, suggested_rect.top, 
          suggested_rect.right - suggested_rect.left, suggested_rect.bottom - suggested_rect.top,
          SWP_NOZORDER | SWP_NOACTIVATE);
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
const WM_DPICHANGED = 0x02E0;
const SWP_NOZORDER = 0x0004;
const SWP_NOACTIVATE = 0x0010;
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
