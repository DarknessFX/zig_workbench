//!zig-autodoc-section: BaseWebGPU\\main.zig
//! main.zig :
//!  WebGPU project.
// Build using Zig 0.15.2

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const builtin = @import("builtin");
const sdl = @cImport({
  @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
  @cInclude("SDL3/SDL.h");
  @cInclude("SDL3/SDL_main.h");
});
const log = sdl.SDL_Log;

const gpu = @cImport({ 
  @cInclude("webgpu.h"); 
});

var app = struct {
  title: [*c]const u8 = "BaseSDL3",
  isReady: bool = false,

  hWnd: std.os.windows.HWND = undefined,
  hInstance: std.os.windows.HINSTANCE = undefined,
  width: c_int = 1280,
  height: c_int = 720,

  window: *sdl.SDL_Window = undefined,
  instance: gpu.WGPUInstance = null,
  adapter: gpu.WGPUAdapter = null,
  device: gpu.WGPUDevice = null,
  surface: gpu.WGPUSurface = null,
  pipeline: gpu.WGPURenderPipeline = null,  
  queue: gpu.WGPUQueue = null,
  shader: gpu.WGPUShaderModule = null,

  vbuffer: gpu.WGPUBuffer = null,
  ibuffer: gpu.WGPUBuffer = null,
  ubuffer: gpu.WGPUBuffer = null,
  bindgroup: gpu.WGPUBindGroup = null,
  vars_rot: f32 = 0.0,
}{};

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
// Zig Main, ignored, using SDL3
pub extern fn main() void;

pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  if (sdlInit() != sdl.SDL_APP_CONTINUE) return sdl.SDL_APP_FAILURE;
  if (sdlHwnd() != sdl.SDL_APP_CONTINUE) return sdl.SDL_APP_FAILURE;
  gpuInstanceSurface();
  gpuRequestAdapter();  //printAdapterInfo();
  gpuRequestDevice();
  gpuConfigureSurface();
  gpuPipeline();
  gpuShaderData();
  app.isReady = true;

  return sdl.SDL_APP_CONTINUE;
}

pub export fn SDL_AppEvent(appstate: ?*anyopaque, event: *sdl.SDL_Event) sdl.SDL_AppResult {
  _ = appstate;

  if (event.key.key == sdl.SDLK_ESCAPE 
  and event.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
    return sdl.SDL_EVENT_QUIT;
  }

  if (event.*.type == sdl.SDL_EVENT_QUIT) {
    return sdl.SDL_APP_SUCCESS;
  }
  return sdl.SDL_APP_CONTINUE;
}

pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;
  if (app.queue) |queue| gpu.wgpuQueueRelease(queue);
  if (app.pipeline) |pipeline| gpu.wgpuRenderPipelineRelease(pipeline);
  if (app.device) |device| gpu.wgpuDeviceRelease(device);
  if (app.adapter) |adapter| gpu.wgpuAdapterRelease(adapter);
  if (app.surface) |surface| gpu.wgpuSurfaceRelease(surface);
  if (app.instance) |instance| gpu.wgpuInstanceRelease(instance);  
}

//#endregion ==================================================================
//#region MARK: RENDERER
//=============================================================================
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;
  if (!app.isReady) { return sdl.SDL_APP_CONTINUE; }

  app.vars_rot += 0.1;
  app.vars_rot = if (app.vars_rot >= 360) 0.0 else app.vars_rot;
  gpu.wgpuQueueWriteBuffer(app.queue, app.ubuffer, 0, &app.vars_rot, @sizeOf(@TypeOf(app.vars_rot)));

  var back_buffer: gpu.WGPUTextureView = undefined;
  var surface_texture: gpu.WGPUSurfaceTexture = gpu.WGPUSurfaceTexture{};
  gpu.wgpuSurfaceGetCurrentTexture(app.surface, &surface_texture);
  if (surface_texture.status == gpu.WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal) {
    back_buffer = gpu.wgpuTextureCreateView(surface_texture.texture, null);
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
  _ = gpu.wgpuSurfacePresent(app.surface);

  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuTextureViewRelease(back_buffer);

  return sdl.SDL_APP_CONTINUE;
}

//#endregion ==================================================================
//#region MARK: PIPELINE
//=============================================================================
fn gpuPipeline() void {
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
  log("WebGPU Pipeline created.", .{});
}

//#endregion ==================================================================
//#region MARK: SHADERDATA
//=============================================================================
fn gpuShaderData() void {
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
  log("WebGPU ShaderData created.", .{});
}

//#endregion ==================================================================
//#region MARK: SHADERS
//=============================================================================
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

//#endregion ==================================================================
//#region MARK: SDL_UTILS
//=============================================================================
fn sdlInit() sdl.SDL_AppResult {
  log("SDL Initializing..", );

  _ = sdl.SDL_SetAppMetadata(app.title, "1.0", "com.example.webgpu");
  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
    log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  _ = sdl.SDL_SetHint("SDL_RENDER_DRIVER", "webgpu");
  const window_flags = sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | sdl.SDL_WINDOW_HIDDEN;
  app.window = sdl.SDL_CreateWindow("WebGPU", app.width, app.height, window_flags)
    orelse return sdl.SDL_APP_FAILURE;
  _ = sdl.SDL_ShowWindow(app.window);

  return sdl.SDL_APP_CONTINUE;
}

fn sdlHwnd() sdl.SDL_AppResult {
  const props = sdl.SDL_GetWindowProperties(app.window);
  if (sdl.SDL_GetPointerProperty(props, sdl.SDL_PROP_WINDOW_WIN32_HWND_POINTER, null)) |hwnd| {
    app.hWnd = @ptrCast(hwnd);
  } else {
    log("Failed to get native window handle", .{});
    return sdl.SDL_APP_FAILURE;
  }
  if (sdl.SDL_GetPointerProperty(props, sdl.SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, null)) |hinstance| {
    app.hInstance = @ptrCast(hinstance);
    if (@intFromPtr(hinstance) != @intFromPtr(GetModuleHandleA(null))) {
      log("SDL Wrong hIntance? Possible error.", .{});
    }
  } else {
    log("Failed to get native window instance", .{});
    return sdl.SDL_APP_FAILURE;
  }
  log("SDL Window HWND and hInstance found.", );

  return sdl.SDL_APP_CONTINUE;
}

//#endregion ==================================================================
//#region MARK: WEBGPU_UTILS
//=============================================================================
fn gpuInstanceSurface() void {
  const instance_desc = gpu.WGPUInstanceDescriptor{ .nextInChain = null };
  app.instance = gpu.wgpuCreateInstance(&instance_desc).?;
  log("WebGPU Instance created.", );

  var from_hwnd = gpu.WGPUSurfaceSourceWindowsHWND{
    .chain = .{ .sType = gpu.WGPUSType_SurfaceSourceWindowsHWND, .next = null, },
    .hinstance = app.hInstance,
    .hwnd = app.hWnd,
  };

  var surface_desc = gpu.WGPUSurfaceDescriptor{
    .nextInChain = @ptrCast(&from_hwnd.chain),
    .label = .{ .data = null, .length = 0, },
  };

  app.surface = gpu.wgpuInstanceCreateSurface(app.instance, &surface_desc);
  log("WebGPU Surface created.", .{});
}

fn gpuConfigureSurface() void {
  app.queue = gpu.wgpuDeviceGetQueue(app.device);
  log("WebGPU Queue acquired.", .{});    

  const config = gpu.WGPUSurfaceConfiguration{
    .nextInChain = null,
    .device = app.device,
    .width = @intCast(app.width),
    .height = @intCast(app.height),
    .format = gpu.WGPUTextureFormat_BGRA8Unorm,
    .usage = gpu.WGPUTextureUsage_RenderAttachment,
    .alphaMode = gpu.WGPUCompositeAlphaMode_Opaque,
    .presentMode = gpu.WGPUPresentMode_Fifo,
    .viewFormatCount = 0,
    .viewFormats = null,
  };
  gpu.wgpuSurfaceConfigure(app.surface, &config);
}

//#endregion ==================================================================
//#region MARK: ADAPTER
//=============================================================================
export fn gpuAdapterCallback(status: gpu.WGPURequestAdapterStatus, adapter: gpu.WGPUAdapter,
  message: gpu.WGPUStringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque,) callconv(.c) void {
  _ = message; _ = userdata1; _ = userdata2;

  log("WebGPU Adapter callback called!", .{});
  if (status == gpu.WGPURequestAdapterStatus_Success) {
    app.adapter = adapter;
    log("WebGPU Adapter received!", .{});
  } else {
    log("WebGPU Adapter request failed", .{});
  }
}

fn gpuRequestAdapter() void {
  const adapter_options = [_]gpu.WGPURequestAdapterOptions{
    gpu.WGPURequestAdapterOptions{
      .nextInChain = null,
      .compatibleSurface = app.surface,
      .powerPreference = gpu.WGPUPowerPreference_Undefined,
      .backendType = gpu.WGPUBackendType_Undefined,
      .forceFallbackAdapter = 0,
    }
  };

  const adapter_callback_info = gpu.WGPURequestAdapterCallbackInfo{
    .nextInChain = null,
    .mode = gpu.WGPUCallbackMode_AllowSpontaneous,
    .callback = gpuAdapterCallback,
    .userdata1 = null,
    .userdata2 = null,
  };

  log("WebGPU Adapter requesting...", .{});
  _ = gpu.wgpuInstanceRequestAdapter(app.instance, &adapter_options, adapter_callback_info);
}
  
//#endregion ==================================================================
//#region MARK: DEVICE
//=============================================================================
export fn gpuDeviceCallback(status: gpu.WGPURequestDeviceStatus, device: gpu.WGPUDevice, message: gpu.WGPUStringView,
  userdata1: ?*anyopaque, userdata2: ?*anyopaque,) callconv(.c) void {
  _ = message; _ = userdata1; _ = userdata2;

  log("WebGPU Device callback called!", .{});
  if (status == gpu.WGPURequestDeviceStatus_Success) {
    app.device = device;
    app.queue = gpu.wgpuDeviceGetQueue(device);
    log("WebGPU Device received!", .{});
  } else {
    log("WebGPU Device request failed", .{});
  }
}

fn gpuRequestDevice() void {
  const device_callback_info = gpu.WGPURequestDeviceCallbackInfo{
    .nextInChain = null,
    .mode = gpu.WGPUCallbackMode_AllowSpontaneous,
    .callback = gpuDeviceCallback,
    .userdata1 = null,
    .userdata2 = null,
  };

  log("WebGPU Device requesting...", .{});
  _ = gpu.wgpuAdapterRequestDevice(
    app.adapter,
    &[_]gpu.WGPUDeviceDescriptor{
      gpu.WGPUDeviceDescriptor{},
    },
    device_callback_info,
  );
}

//#endregion ==================================================================
//#region MARK: UTILS
//=============================================================================
fn createShader(code: [*:0]const u8, label: [*:0]const u8) gpu.WGPUShaderModule {
  var wgsl = gpu.WGPUShaderSourceWGSL{
    .chain = .{ .sType = gpu.WGPUSType_ShaderSourceWGSL },
    .code = .{ .data = code, .length = std.mem.len(code) },
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
  log("WebGPU Adapter info :\n", .{});
  log("  Driver: %s\n", info.description.data );
  log("  Vendor: %s\n", info.vendor.data );
  log("  Architecture: %s\n", info.architecture.data );
  log("  Device: %s\n", info.device.data );
  log("  Backend type: %s\n", info.backendType );
  log("  Adapter type: %s\n", info.adapterType );
  log("  VendorID: %s\n", info.vendorID );
  log("  DeviceID: %s\n", info.deviceID );
  gpu.wgpuAdapterInfoFreeMembers(info);
}

fn printAdapterFormats() void {
  var caps: gpu.WGPUSurfaceCapabilities = undefined;
  _ = gpu.wgpuSurfaceGetCapabilities(app.surface, app.adapter, &caps);  
  log("WebGPU Surface configured: %dx%d format=%d", app.width, app.height, caps.formats[0] );
  log("WebGPU Surface Formats: %d", caps.formatCount);
  for (caps.formats[0..caps.formatCount]) |f| {
    log("  Surface Format: %d", f);
  }
  log("WebGPU Surface Present modes: %d", caps.presentModeCount);
  log("WebGPU Surface Alpha modes: %d", caps.alphaModeCount);
  gpu.wgpuSurfaceCapabilitiesFreeMembers(caps);
}

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
extern "kernel32" fn GetModuleHandleA(
  lpModuleName: ?[*:0]const u8
) callconv(.winapi) std.os.windows.HINSTANCE;

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================