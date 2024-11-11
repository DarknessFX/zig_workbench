//!zig-autodoc-section: BaseWebGPU\\app.zig
//! app.zig :
//!	  Platform application source code (Windows/Linux/Mac).
//!   Using SDL2 and Dawn WebGPU.
// Build using Zig 0.13.0
const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
pub const gpu = @cImport({
  // NOTE: May need full path to cIncludes
  @cInclude("SDL.h");
  @cInclude("SDL_syswm.h");
  @cInclude("webgpu.h");
});

const app = struct {
  var isRunning: bool = false;
  var window: *(gpu.SDL_Window) = undefined;

  var instance: gpu.WGPUInstance = null;
  var adapter: gpu.WGPUAdapter = null;
  var device: gpu.WGPUDevice = null;
  var surface: gpu.WGPUSurface = null;
  var pipeline: gpu.WGPURenderPipeline = null;
  var queue: gpu.WGPUQueue = null;

  var vbuffer: gpu.WGPUBuffer = null;
  var ibuffer: gpu.WGPUBuffer = null;
  var ubuffer: gpu.WGPUBuffer = null;
  var bindgroup: gpu.WGPUBindGroup = null;
  var vars_rot: f32 = 0.0;
};


// ============================================================================
// Main
//
pub fn main() void {
  HideConsoleWindow();

  // Start WebGPU
  {
    startWindow();
    startInstanceSurface();
    startAdapterDevice();
    win.Sleep(250); // Wait for Get Adapter and Device callbacks to resolve
    startQueueSurfaceConfig();
    startRenderPipeline();
    startShaderData();
  }

  app.isRunning = true;
	while (app.isRunning) {
    ProcessInput();
    RenderFrame();
  }

  // Stop WebGPU
  {
    stopAll();
    stopWindow();
  }
}


// ============================================================================
// Functions
//
fn ProcessInput() void {
	var event: gpu.SDL_Event = undefined;
  while (gpu.SDL_PollEvent(&event) != 0) {
    switch (event.type) {
      gpu.SDL_QUIT => {
        app.isRunning = false;
        break;
      },
      gpu.SDL_KEYDOWN => {
        if ((event.key.keysym.sym == gpu.SDLK_ESCAPE) and 
            (event.key.keysym.mod & gpu.SDLK_LSHIFT == 1)) {
          app.isRunning = false;
          break;
        }
      },
      else => {},
    }
  }
}

fn RenderFrame() void {
  // Update rotation
  app.vars_rot += 0.1;
  app.vars_rot = if (app.vars_rot >= 360) 0.0 else app.vars_rot;
  gpu.wgpuQueueWriteBuffer(app.queue, app.ubuffer, 0, &app.vars_rot, @sizeOf(@TypeOf(app.vars_rot)));

  // Swapchain-less
  var back_buffer: gpu.WGPUTextureView = undefined;
  var surface_texture: gpu.WGPUSurfaceTexture = gpu.WGPUSurfaceTexture{};
  gpu.wgpuSurfaceGetCurrentTexture(app.surface, &surface_texture);
  switch (surface_texture.status) {
    gpu.WGPUSurfaceGetCurrentTextureStatus_Success => {
      back_buffer = gpu.wgpuTextureCreateView(surface_texture.texture, null);
    },
    gpu.WGPUSurfaceGetCurrentTextureStatus_Timeout => {},
    gpu.WGPUSurfaceGetCurrentTextureStatus_Outdated => {},
    gpu.WGPUSurfaceGetCurrentTextureStatus_Lost => {},
    gpu.WGPUSurfaceGetCurrentTextureStatus_OutOfMemory => {},
    gpu.WGPUSurfaceGetCurrentTextureStatus_DeviceLost => {},
    else => {},
  }

  const cmd_encoder = gpu.wgpuDeviceCreateCommandEncoder(app.device, null);
  const render_pass = gpu.wgpuCommandEncoderBeginRenderPass(cmd_encoder, &gpu.WGPURenderPassDescriptor{
    .colorAttachmentCount = 1,
    .colorAttachments = &gpu.WGPURenderPassColorAttachment{
      .view = back_buffer,
      .depthSlice = gpu.WGPU_DEPTH_SLICE_UNDEFINED,
      .loadOp = gpu.WGPULoadOp_Clear,
      .storeOp = gpu.WGPUStoreOp_Store,
      .clearValue = gpu.WGPUColor{ .r = 0.2, .g = 0.2, .b = 0.3, .a = 1.0 },
    },
  });

  gpu.wgpuRenderPassEncoderSetPipeline(render_pass, app.pipeline);
  gpu.wgpuRenderPassEncoderSetBindGroup(render_pass, 0, app.bindgroup, 0, 0);
  gpu.wgpuRenderPassEncoderSetVertexBuffer(render_pass, 0, app.vbuffer, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderSetIndexBuffer(render_pass, app.ibuffer, gpu.WGPUIndexFormat_Uint16, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderDrawIndexed(render_pass, 6, 1, 0, 0, 0);

  gpu.wgpuRenderPassEncoderEnd(render_pass);
  const cmd_buffer = gpu.wgpuCommandEncoderFinish(cmd_encoder, null); // after 'end render pass'

  gpu.wgpuQueueSubmit(app.queue, 1, &cmd_buffer);
  gpu.wgpuSurfacePresent(app.surface);

  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuTextureViewRelease(back_buffer);
}

fn startWindow() void {
  // NOTE: Probably could be changed to use GLFW3 window
  _ = gpu.SDL_Init(gpu.SDL_INIT_EVERYTHING);
  app.window = gpu.SDL_CreateWindow(
    "BaseWebGPU", gpu.SDL_WINDOWPOS_CENTERED, gpu.SDL_WINDOWPOS_CENTERED, 1280, 720, 0)
    orelse undefined;
  // _ = gpu.SDL_SetRelativeMouseMode(gpu.SDL_TRUE); // Capture Mouse?
}

fn startInstanceSurface() void {
  app.instance = gpu.wgpuCreateInstance(&gpu.WGPUInstanceDescriptor{ .nextInChain = null, });
  var windowWMInfo: gpu.SDL_SysWMinfo = std.mem.zeroes(gpu.SDL_SysWMinfo);
  _ = gpu.SDL_GetWindowWMInfo(app.window, &windowWMInfo);
  var fromWindowsHWND: gpu.WGPUSurfaceDescriptorFromWindowsHWND = gpu.WGPUSurfaceDescriptorFromWindowsHWND{
    .chain = .{
      .next = null,
      .sType =  gpu.WGPUSType_SurfaceSourceWindowsHWND,
    },
    .hinstance = GetModuleHandleA(null),
    .hwnd = windowWMInfo.info.win.window,
  };
  app.surface = gpu.wgpuInstanceCreateSurface(app.instance, &gpu.WGPUSurfaceDescriptor{
    .nextInChain = &fromWindowsHWND.chain,
    .label = .{ 
      .data = null,
      .length = 0 
    },
  });
}

fn startAdapterDevice() void {
  var adapter_options = [_]gpu.WGPURequestAdapterOptions{
    gpu.WGPURequestAdapterOptions{
      .nextInChain = null,
      .compatibleSurface = app.surface,
      .powerPreference = gpu.WGPUPowerPreference_Undefined,
      .backendType = gpu.WGPUBackendType_Undefined,
      .forceFallbackAdapter = 0,
    },
  };
  _ = gpu.wgpuInstanceRequestAdapter(
    app.instance,
    &adapter_options,
    requestAdapterCallback,
    null);
  _ = gpu.wgpuAdapterRequestDevice(
    app.adapter, 
    &[_]gpu.WGPUDeviceDescriptor{
      gpu.WGPUDeviceDescriptor{},
    },
    requestDeviceCallback,
    null);
}

fn startQueueSurfaceConfig() void {
  app.queue = gpu.wgpuDeviceGetQueue(app.device);

  const surface_Config = [_]gpu.WGPUSurfaceConfiguration{
    gpu.WGPUSurfaceConfiguration{
      .nextInChain = null,
      .device = app.device,
      .width = 1280,
      .height = 720,
      .format = gpu.WGPUTextureFormat_BGRA8Unorm,
      .usage = gpu.WGPUTextureUsage_RenderAttachment,
      .presentMode = gpu.WGPUPresentMode_Fifo,
      .viewFormatCount = 0,
      .viewFormats = null,
      .alphaMode = gpu.WGPUCompositeAlphaMode_Opaque,
    },
  };
  gpu.wgpuSurfaceConfigure(app.surface, &surface_Config);
}

fn startRenderPipeline() void {
  const shader_triangle = createShader(wgsl_triangle, "triangle");
  const vertex_attributes = [2]gpu.WGPUVertexAttribute{
    .{
      .format = gpu.WGPUVertexFormat_Float32x2,
      .offset = 0,
      .shaderLocation = 0,
    },
    .{
      .format = gpu.WGPUVertexFormat_Float32x3,
      .offset = 2 * @sizeOf(f32),
      .shaderLocation = 1,
    },
  };
  const vertex_buffer_layout = gpu.WGPUVertexBufferLayout{
    .arrayStride = 5 * @sizeOf(f32),
    .attributeCount = 2,
    .attributes = &vertex_attributes,
  };

  const bindgroup_layout = gpu.wgpuDeviceCreateBindGroupLayout(app.device, &gpu.WGPUBindGroupLayoutDescriptor{
    .entryCount = 1,
    .entries = &gpu.WGPUBindGroupLayoutEntry{
      .binding = 0,
      .visibility = gpu.WGPUShaderStage_Vertex,
      .buffer = .{
        .type = gpu.WGPUBufferBindingType_Uniform,
      }
    }
  });
  const pipeline_layout = gpu.wgpuDeviceCreatePipelineLayout(app.device, &gpu.WGPUPipelineLayoutDescriptor{
    .bindGroupLayoutCount = 1,
    .bindGroupLayouts = &bindgroup_layout,
  });

  app.pipeline = gpu.wgpuDeviceCreateRenderPipeline(app.device, &gpu.WGPURenderPipelineDescriptor{
    .layout = pipeline_layout,
    .primitive = .{
      .frontFace = gpu.WGPUFrontFace_CCW,
      .cullMode = gpu.WGPUCullMode_None,
      .topology = gpu.WGPUPrimitiveTopology_TriangleList,
      .stripIndexFormat = gpu.WGPUIndexFormat_Undefined,
    },
    .vertex = .{
      .module = shader_triangle,
      .entryPoint = .{
        .data = "vs_main",
        .length = 7,
      },
      .bufferCount = 1,
      .buffers = &vertex_buffer_layout,
    },
    .fragment = &gpu.WGPUFragmentState{
      .module = shader_triangle,
      .entryPoint = .{
        .data = "fs_main",
        .length = 7,
      },
      .targetCount = 1,
      .targets = &gpu.WGPUColorTargetState{
        .format = gpu.WGPUTextureFormat_BGRA8Unorm,
        .writeMask = gpu.WGPUColorWriteMask_All,
        .blend = &gpu.WGPUBlendState{
          .color = .{
            .operation = gpu.WGPUBlendOperation_Add,
            .srcFactor = gpu.WGPUBlendFactor_One,
            .dstFactor = gpu.WGPUBlendFactor_One,
          },
          .alpha = .{
            .operation = gpu.WGPUBlendOperation_Add,
            .srcFactor = gpu.WGPUBlendFactor_One,
            .dstFactor = gpu.WGPUBlendFactor_One,
          },
        },
      },
    },
    .multisample = .{
      .count = 1,
      .mask = 0xFFFFFFFF,
      .alphaToCoverageEnabled = 0,
    },
    .depthStencil = null,
  });

  gpu.wgpuBindGroupLayoutRelease(bindgroup_layout);
  gpu.wgpuPipelineLayoutRelease(pipeline_layout);
  gpu.wgpuShaderModuleRelease(shader_triangle);
}

fn startShaderData() void {
  const vertex_data = [_]f32{
    // x, y          // r, g, b
    -0.5, -0.5,     1.0, 0.0, 0.0, // bottom-left
     0.5, -0.5,     0.0, 1.0, 0.0, // bottom-right
     0.5,  0.5,     0.0, 0.0, 1.0, // top-right
    -0.5,  0.5,     1.0, 1.0, 0.0, // top-left
  };
  const index_data = [_]u16{
    0, 1, 2,
    0, 2, 3,
  };
  app.vbuffer = createBuffer(&vertex_data, @sizeOf(@TypeOf(vertex_data)), gpu.WGPUBufferUsage_Vertex);
  app.ibuffer = createBuffer(&index_data, @sizeOf(@TypeOf(index_data)), gpu.WGPUBufferUsage_Index);
  app.ubuffer = createBuffer(&app.vars_rot, @sizeOf(@TypeOf(app.vars_rot)), gpu.WGPUBufferUsage_Uniform);
  app.bindgroup = gpu.wgpuDeviceCreateBindGroup(app.device, &gpu.WGPUBindGroupDescriptor{
    .layout = gpu.wgpuRenderPipelineGetBindGroupLayout(app.pipeline, 0),
    .entryCount = 1,
    .entries = &gpu.WGPUBindGroupEntry{
      .binding = 0,
      .offset = 0,
      .buffer = app.ubuffer,
      .size = @sizeOf(@TypeOf(app.vars_rot)),
    },
  });
}

fn stopAll() void {
  gpu.wgpuQueueRelease(app.queue);
  gpu.wgpuRenderPipelineRelease(app.pipeline);
  gpu.wgpuSurfaceRelease(app.surface);
  gpu.wgpuAdapterRelease(app.adapter);
  gpu.wgpuDeviceRelease(app.device);
  gpu.wgpuInstanceRelease(app.instance);
}

fn stopWindow() void {
  gpu.SDL_DestroyWindow(app.window);
  gpu.SDL_Quit();
}


// ============================================================================
// Callbacks
//
pub fn requestAdapterCallback (
  status: gpu.WGPURequestAdapterStatus, 
  adapter: gpu.WGPUAdapter, 
  message: gpu.WGPUStringView, 
  userdata: ?*anyopaque,
) callconv(.C) void {
  if (status == gpu.WGPURequestAdapterStatus_Success) {
    app.adapter = adapter;
    //std.debug.print("Adapter callback message: {}\n", .{message});
    if (userdata) |user| {
      std.debug.print("UserData1 callback message: {}\n", .{user});
    }
  } else {
    std.debug.print("Runtime error: {}\n", .{message});
    unreachable;
  }
}

pub fn requestDeviceCallback (
  status: gpu.WGPURequestDeviceStatus, 
  device: gpu.WGPUDevice, 
  message: gpu.WGPUStringView, 
  userdata: ?*anyopaque,
) callconv(.C) void {
  if (status == gpu.WGPURequestDeviceStatus_Success) {
    app.device = device;
    //std.debug.print("Device callback message: {}\n", .{message});
    if (userdata) |user| {
      std.debug.print("UserData1 callback message: {}\n", .{user});
    }
  } else {
    std.debug.print("Runtime error: {}\n", .{message});
    unreachable;
  }
}


// ============================================================================
// Tools
//
fn createShader(code: [*:0]const u8, label: [*:0]const u8) gpu.WGPUShaderModule {
  const wgsl = gpu.WGPUShaderModuleWGSLDescriptor{
    .chain = .{ .sType = gpu.WGPUSType_ShaderSourceWGSL },
    .code = .{
      .data = code,
      .length = std.mem.len(code),
    },    
  };

  return gpu.wgpuDeviceCreateShaderModule(app.device, &gpu.WGPUShaderModuleDescriptor{
    .nextInChain = @ptrCast(&wgsl),
    .label = .{
      .data = label,
      .length = std.mem.len(label),
    },    
  });
}

fn createBuffer(data: ?*const anyopaque, size: usize, usage: gpu.WGPUBufferUsage) gpu.WGPUBuffer {
  const buffer = gpu.wgpuDeviceCreateBuffer(app.device, &gpu.WGPUBufferDescriptor{
    .usage = gpu.WGPUBufferUsage_CopyDst | usage,
    .size = size,
  });
  gpu.wgpuQueueWriteBuffer(app.queue, buffer, 0, data, size);
  return buffer;
}

fn printAdapterInfo() void {
  var info: gpu.WGPUAdapterInfo = std.mem.zeroes(gpu.WGPUAdapterInfo);
  _ = gpu.wgpuAdapterGetInfo(app.adapter, &info);
  std.debug.print("", .{});
  std.debug.print("Driver: {s}\n", .{ info.description.data });
  std.debug.print("Vendor: {s}\n", .{ info.vendor.data });
  std.debug.print("Architecture: {s}\n", .{ info.architecture.data });
  std.debug.print("Device: {s}\n", .{ info.device.data });
  std.debug.print("Backend type: {}\n", .{ info.backendType });
  std.debug.print("Adapter type: {}\n", .{ info.adapterType });
  std.debug.print("VendorID: {}\n", .{ info.vendorID });
  std.debug.print("DeviceID: {}\n", .{ info.deviceID });
  gpu.wgpuAdapterInfoFreeMembers(info);  
  gpu.wgpuAdapterInfoFreeMembers(info);
}

fn HideConsoleWindow() void {
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);

  // _ = MessageBoxA(null, "Console window is hided.", "BaseWebGPU", MB_OK);
}


// ============================================================================
// Shaders
//
const wgsl_triangle = 
\\  /* attribute/uniform decls */
\\  
\\  struct VertexIn {
\\      @location(0) aPos : vec2<f32>,
\\      @location(1) aCol : vec3<f32>,
\\  };
\\  struct VertexOut {
\\      @location(0) vCol : vec3<f32>,
\\      @builtin(position) Position : vec4<f32>,
\\  };
\\  struct Rotation {
\\      @location(0) degs : f32,
\\  };
\\  @group(0) @binding(0) var<uniform> uRot : Rotation;
\\  
\\  /* vertex shader */
\\  
\\  @vertex
\\  fn vs_main(input : VertexIn) -> VertexOut {
\\      var rads : f32 = radians(uRot.degs);
\\      var cosA : f32 = cos(rads);
\\      var sinA : f32 = sin(rads);
\\      var rot : mat3x3<f32> = mat3x3<f32>(
\\          vec3<f32>( cosA, sinA, 0.0),
\\          vec3<f32>(-sinA, cosA, 0.0),
\\          vec3<f32>( 0.0,  0.0,  1.0));
\\      var output : VertexOut;
\\      output.Position = vec4<f32>(rot * vec3<f32>(input.aPos, 1.0), 1.0);
\\      output.vCol = input.aCol;
\\      return output;
\\  }
\\  
\\  /* fragment shader */
\\  
\\  @fragment
\\  fn fs_main(@location(0) vCol : vec3<f32>) -> @location(0) vec4<f32> {
\\      return vec4<f32>(vCol, 1.0);
\\  }
;


// ============================================================================
// Win32API
//
pub extern "kernel32" fn GetConsoleTitleA(
  lpConsoleTitle: win.LPSTR,
  nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

pub extern "kernel32" fn FindWindowA(
  lpClassName: ?win.LPSTR,
  lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;

pub const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: i32
) callconv(win.WINAPI) win.BOOL;

pub const MB_OK = 0x00000000;
pub extern "user32" fn MessageBoxA(
  hWnd: ?win.HWND,
  lpText: [*:0]const u8,
  lpCaption: [*:0]const u8,
  uType: win.UINT
) callconv(win.WINAPI) win.INT;

extern "kernel32" fn GetModuleHandleA(
  lpModuleName: ?[*:0]const u8
) callconv(win.WINAPI) win.HINSTANCE;

// ============================================================================
// Tests
//
test " " {
}