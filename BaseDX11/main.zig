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
//   @cInclude("C:/zig_workbench/lib/DX11/DX11.h");
const dx = @cImport({
  @cInclude("lib/DX11/DX11.h");
});

var wnd: win.HWND = undefined;
const wnd_title = L("BaseDX11");
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
var g_pVertexShader: [*c]dx.ID3D11VertexShader = undefined;
var g_pPixelShader: [*c]dx.ID3D11PixelShader = undefined;
var g_pVertexLayout: [*c]dx.ID3D11InputLayout = undefined;
var g_pVertexBuffer: [*c]dx.ID3D11Buffer = undefined;

const XMFLOAT3 = struct { x: f32, y: f32, z: f32 };
const XMFLOAT4 = struct { r: f32, g: f32, b: f32, a: f32 };
const SimpleVertex = struct { position: XMFLOAT3, color: XMFLOAT4 };

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

  var clear_color = [_]f32{ 0.145, 0.145, 0.145, 1.0 };
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

    g_pd3dDeviceContext.?.lpVtbl.*.OMSetRenderTargets.?( g_pd3dDeviceContext, 1, &g_mainRenderTargetView, null);
    g_pd3dDeviceContext.?.lpVtbl.*.ClearRenderTargetView.?( g_pd3dDeviceContext, g_mainRenderTargetView, &clear_color);

    g_pd3dDeviceContext.?.lpVtbl.*.VSSetShader.?( g_pd3dDeviceContext, g_pVertexShader, null, 0 );
    g_pd3dDeviceContext.?.lpVtbl.*.PSSetShader.?( g_pd3dDeviceContext, g_pPixelShader, null, 0 );
    g_pd3dDeviceContext.?.lpVtbl.*.Draw.?( g_pd3dDeviceContext, 6, 0 );

    _ = g_pSwapChain.?.lpVtbl.*.Present.?(g_pSwapChain, 0, 0);


  }

  CleanupDeviceD3D();
  return 0;
}

// DIRECTX 11
fn CreateDeviceD3D(hWnd: win.HWND) bool { 

  var rc: win.RECT = undefined;
  _ = GetClientRect( hWnd, &rc );
  var width: win.UINT = @as(c_uint, @intCast(rc.right - rc.left));
  var height: win.UINT = @as(c_uint, @intCast(rc.bottom - rc.top));

  var sd = std.mem.zeroes(dx.DXGI_SWAP_CHAIN_DESC);
  sd.BufferCount = 2;
  sd.BufferDesc.Width = width;
  sd.BufferDesc.Height = height;
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
  g_pd3dDeviceContext.?.lpVtbl.*.OMSetRenderTargets.?( g_pd3dDeviceContext, 1, &g_mainRenderTargetView, null);
  
  var vp: dx.D3D11_VIEWPORT = undefined;
    vp.Width = @as(f32, @floatFromInt(width)); vp.Height = @as(f32, @floatFromInt(height));
    vp.MinDepth = 0.0; vp.MaxDepth = 1.0; vp.TopLeftX = 0; vp.TopLeftY = 0;
  g_pd3dDeviceContext.?.lpVtbl.*.RSSetViewports.?( g_pd3dDeviceContext, 1, &vp );

  var pVSBlob: [*c]dx.ID3DBlob = undefined;
  _ = dx.D3DCompileFromFile( L("shaders.hlsl"), null, null, 
    "VSMain", "vs_4_0", dx.D3DCOMPILE_ENABLE_STRICTNESS, 0, &pVSBlob, null );
  _ = g_pd3dDevice.?.lpVtbl.*.CreateVertexShader.?( g_pd3dDevice, 
    pVSBlob.*.lpVtbl.*.GetBufferPointer.?(pVSBlob), 
    pVSBlob.*.lpVtbl.*.GetBufferSize.?(pVSBlob), 
    null, &g_pVertexShader );

  const input_layout_desc = &[_]dx.D3D11_INPUT_ELEMENT_DESC { 
    .{ .SemanticName = "POSITION", .SemanticIndex = 0, .Format = dx.DXGI_FORMAT_R32G32B32_FLOAT, .InputSlot = 0,
    .AlignedByteOffset = 0, .InputSlotClass = dx.D3D11_INPUT_PER_VERTEX_DATA, .InstanceDataStepRate = 0 },
    .{ .SemanticName = "COLOR", .SemanticIndex = 0, .Format = dx.DXGI_FORMAT_R32G32B32A32_FLOAT, .InputSlot = 0,
    .AlignedByteOffset = 12, .InputSlotClass = dx.D3D11_INPUT_PER_VERTEX_DATA, .InstanceDataStepRate = 0 }
  };
	var numElements: win.UINT = input_layout_desc.len;
	_ = g_pd3dDevice.?.lpVtbl.*.CreateInputLayout.?( g_pd3dDevice, input_layout_desc, numElements,
    pVSBlob.*.lpVtbl.*.GetBufferPointer.?(pVSBlob), 
    pVSBlob.*.lpVtbl.*.GetBufferSize.?(pVSBlob), 
    &g_pVertexLayout );
  _ = pVSBlob.*.lpVtbl.*.Release.?(pVSBlob);
  g_pd3dDeviceContext.?.lpVtbl.*.IASetInputLayout.?( g_pd3dDeviceContext, g_pVertexLayout );

  var vertices = [_]SimpleVertex {
    .{ .position=XMFLOAT3{ .x= 0.0,  .y= 0.95, .z=0.0 }, .color=XMFLOAT4{ .r=1.0, .g=0.0, .b=0.0, .a=1.0 } },
    .{ .position=XMFLOAT3{ .x= 0.95, .y=-0.95, .z=0.0 }, .color=XMFLOAT4{ .r=0.0, .g=0.0, .b=1.0, .a=1.0 } },
    .{ .position=XMFLOAT3{ .x=-0.95, .y=-0.95, .z=0.0 }, .color=XMFLOAT4{ .r=0.0, .g=1.0, .b=0.0, .a=1.0 } }
  };
  var bd: dx.D3D11_BUFFER_DESC = std.mem.zeroes(dx.D3D11_BUFFER_DESC);
  bd.Usage = dx.D3D11_USAGE_DEFAULT;
  bd.ByteWidth = @sizeOf( SimpleVertex ) * 3;
  bd.BindFlags = dx.D3D11_BIND_VERTEX_BUFFER;
	bd.CPUAccessFlags = 0;
  var InitData: dx.D3D11_SUBRESOURCE_DATA = undefined;
  InitData.pSysMem = &vertices;
  _ = g_pd3dDevice.?.lpVtbl.*.CreateBuffer.?( g_pd3dDevice, &bd, &InitData, &g_pVertexBuffer );
  var stride: win.UINT = @sizeOf( SimpleVertex );
  var offset: win.UINT = 0;
  g_pd3dDeviceContext.?.lpVtbl.*.IASetVertexBuffers.?( g_pd3dDeviceContext, 0, 1, &g_pVertexBuffer, &stride, &offset );
  g_pd3dDeviceContext.?.lpVtbl.*.IASetPrimitiveTopology.?( g_pd3dDeviceContext, dx.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST );

  var pPSBlob: [*c]dx.ID3DBlob = undefined;
  _ = dx.D3DCompileFromFile( L("shaders.hlsl"), null, null, 
    "PSMain", "ps_4_0", dx.D3DCOMPILE_ENABLE_STRICTNESS, 0, &pPSBlob, null );
  _ = g_pd3dDevice.?.lpVtbl.*.CreatePixelShader.?( g_pd3dDevice, 
    pPSBlob.*.lpVtbl.*.GetBufferPointer.?(pPSBlob), 
    pPSBlob.*.lpVtbl.*.GetBufferSize.?(pPSBlob), 
    null, &g_pPixelShader );
  _ = pPSBlob.*.lpVtbl.*.Release.?(pPSBlob);

  return true; 
}

fn CleanupDeviceD3D() void {
  CleanupRenderTarget();
  _ = g_pSwapChain.?.lpVtbl.*.Release.?(g_pSwapChain);
  _ = g_pd3dDeviceContext.?.lpVtbl.*.Release.?(g_pd3dDeviceContext);
  _ = g_pd3dDevice.?.lpVtbl.*.Release.?(g_pd3dDevice);
  g_pVertexBuffer = null;
  g_pVertexLayout = null;
  g_pVertexShader = null;
  g_pPixelShader = null;
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

fn WindowProc( hWnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM ) callconv(WINAPI) win.LRESULT {
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

pub extern "user32" fn GetClientRect(
  hWnd: win.HWND,
  lpRect: *win.RECT
) callconv(WINAPI) win.UINT;