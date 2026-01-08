//!zig-autodoc-section: BaseWebGPU\\web.zig
//! web.zig :
//!  HTML5 WASM WebGPU source code (portable and offline).
// Build using Zig 0.15.2

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
pub const gpu = @cImport({
  @cInclude("emscripten.h");
  @cInclude("emscripten/html5.h");
  @cInclude("webgpu.h");
});

// Externals
extern fn jsPrint(ptr: [*]const u8, len: usize) void;
extern fn jsPrintFlush() void;

// Internals
var web = struct {
  title: [*c]const u8 = "BaseWebGPU",
  isReady: bool = false,

  width: c_int = 1280,
  height: c_int = 720,

  instance: gpu.WGPUInstance = null,
  adapter: gpu.WGPUAdapter = null,
  device: gpu.WGPUDevice = null,
  queue: gpu.WGPUQueue = null,
  surface: gpu.WGPUSurface = null,
  pipeline: gpu.WGPURenderPipeline = null,

  vbuffer: gpu.WGPUBuffer = null,
  ibuffer: gpu.WGPUBuffer = null,
  ubuffer: gpu.WGPUBuffer = null,
  bindgroup: gpu.WGPUBindGroup = null,
  vars_rot: f32 = 0.0,

}{};

pub fn main() void {
  log(.info, "Retrieving preinitialized WebGPU device...", .{});
  const instance_desc = gpu.WGPUInstanceDescriptor{ .nextInChain = null };
  web.instance = gpu.wgpuCreateInstance(&instance_desc).?;
  log(.info, "WebGPU Instance created.", .{});

  gpuRequestAdapter();
}

fn main_continue() void {
  gpuSurface();
  gpuRenderPipeline();
  gpuShaderData();    

  web.isReady = true;
  gpu.emscripten_set_main_loop(gpuRenderFrame, 0, true);
}

//#endregion ==================================================================
//#region MARK: ADAPTER
//=============================================================================
fn gpuRequestAdapter() void {
  const adapter_options = [_]gpu.WGPURequestAdapterOptions{
    gpu.WGPURequestAdapterOptions{
      .nextInChain = null,
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

  log(.info, "WebGPU Adapter requesting...", .{});
  _ = gpu.wgpuInstanceRequestAdapter(web.instance, &adapter_options, adapter_callback_info);
}

export fn gpuAdapterCallback(status: gpu.WGPURequestAdapterStatus, adapter: gpu.WGPUAdapter,
  message: gpu.WGPUStringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque,) callconv(.c) void {
  _ = message; _ = userdata1; _ = userdata2;

  log(.info, "WebGPU Adapter callback called!", .{});
  if (status == gpu.WGPURequestAdapterStatus_Success) {
    web.adapter = adapter;
    log(.info, "WebGPU Adapter received!", .{});
    gpuRequestDevice();
  } else {
    log(.err, "WebGPU Adapter request failed", .{});
  }
}

//#endregion ==================================================================
//#region MARK: DEVICE
//=============================================================================
export fn gpuDeviceCallback(status: gpu.WGPURequestDeviceStatus, device: gpu.WGPUDevice, message: gpu.WGPUStringView,
  userdata1: ?*anyopaque, userdata2: ?*anyopaque,) callconv(.c) void {
  _ = message; _ = userdata1; _ = userdata2;

  log(.info, "WebGPU Device callback called!", .{});
  if (status == gpu.WGPURequestDeviceStatus_Success) {
    web.device = device;
    log(.info, "WebGPU Device received!", .{});
    web.queue = gpu.wgpuDeviceGetQueue(device);
    log(.info, "WebGPU Queue received!", .{});
    main_continue(); // end of main callbacks
  } else {
    log(.err, "WebGPU Device request failed", .{});
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

  log(.info, "WebGPU Device requesting...", .{});
  _ = gpu.wgpuAdapterRequestDevice(
    web.adapter,
    &[_]gpu.WGPUDeviceDescriptor{
      gpu.WGPUDeviceDescriptor{},
    },
    device_callback_info,
  );
}

//#endregion ==================================================================
//#region MARK: SURFACE
//=============================================================================
fn gpuSurface() void {
  var surface_selector = gpu.WGPUEmscriptenSurfaceSourceCanvasHTMLSelector{
    .chain = gpu.WGPUChainedStruct{
      .next = null,
      .sType = gpu.WGPUSType_EmscriptenSurfaceSourceCanvasHTMLSelector,
    },
   .selector = .{ .data = "canvas", .length = 6},
  };

  const surface_descriptor = gpu.WGPUSurfaceDescriptor{
    .nextInChain = &surface_selector.chain,
    .label = .{ .data = null, .length = 0},
  };

  web.surface = gpu.wgpuInstanceCreateSurface(web.instance, &surface_descriptor);

  if (web.surface == null) {
    log(.err, "Failed to create surface from canvas", .{});
    return;
  }

  log(.info, "Surface created successfully", .{});

  const config = gpu.WGPUSurfaceConfiguration{
    .nextInChain = null,
    .device = web.device,
    .width = @intCast(web.width),
    .height = @intCast(web.height),
    .format = gpu.WGPUTextureFormat_BGRA8Unorm,
    .usage = gpu.WGPUTextureUsage_RenderAttachment,
    .alphaMode = gpu.WGPUCompositeAlphaMode_Auto,
    .presentMode = gpu.WGPUPresentMode_Fifo,
    .viewFormatCount = 0,
    .viewFormats = null,
  };
  gpu.wgpuSurfaceConfigure(web.surface, &config);
  log(.info, "Surface configured (BGRA8Unorm hardcoded)", .{});
}

//=============================================================================
//#region MARK: RENDERER
//=============================================================================
fn gpuRenderFrame() callconv(.c) void {
  if (!web.isReady) { return; }

  web.vars_rot += 0.1;
  web.vars_rot = if (web.vars_rot >= 360) 0.0 else web.vars_rot;
  gpu.wgpuQueueWriteBuffer(web.queue, web.ubuffer, 0, &web.vars_rot, 16);

  var surface_texture: gpu.WGPUSurfaceTexture = undefined;
  gpu.wgpuSurfaceGetCurrentTexture(web.surface, &surface_texture);
  if (surface_texture.status != gpu.WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal) {
    return;
  }

  const back_buffer = gpu.wgpuTextureCreateView(surface_texture.texture, null);
  const cmd_encoder = gpu.wgpuDeviceCreateCommandEncoder(web.device, null);
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

  gpu.wgpuRenderPassEncoderSetPipeline(render_pass, web.pipeline);
  gpu.wgpuRenderPassEncoderSetBindGroup(render_pass, 0, web.bindgroup, 0, null);
  gpu.wgpuRenderPassEncoderSetVertexBuffer(render_pass, 0, web.vbuffer, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderSetIndexBuffer(render_pass, web.ibuffer, gpu.WGPUIndexFormat_Uint16, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderDrawIndexed(render_pass, 6, 1, 0, 0, 0);

  gpu.wgpuRenderPassEncoderEnd(render_pass);
  const cmd_buffer = gpu.wgpuCommandEncoderFinish(cmd_encoder, null);

  gpu.wgpuQueueSubmit(web.queue, 1, &cmd_buffer);
  //_ = gpu.wgpuSurfacePresent(web.surface);

  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuTextureViewRelease(back_buffer);
  gpu.wgpuTextureRelease(surface_texture.texture);
}

//#endregion ==================================================================
//#region MARK: PIPELINE
//=============================================================================
fn gpuRenderPipeline() void {
  log(.info, "Render Pipeline starting...", .{});
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

  const bindgroup_layout = gpu.wgpuDeviceCreateBindGroupLayout(web.device, &gpu.WGPUBindGroupLayoutDescriptor{
    .entryCount = 1,
    .entries = &gpu.WGPUBindGroupLayoutEntry{
      .binding = 0,
      .visibility = gpu.WGPUShaderStage_Vertex,
      .buffer = .{
        .type = gpu.WGPUBufferBindingType_Uniform,
      }
    }
  });
  const pipeline_layout = gpu.wgpuDeviceCreatePipelineLayout(web.device, &gpu.WGPUPipelineLayoutDescriptor{
    .bindGroupLayoutCount = 1,
    .bindGroupLayouts = &bindgroup_layout,
  });

  web.pipeline = gpu.wgpuDeviceCreateRenderPipeline(web.device, &gpu.WGPURenderPipelineDescriptor{
    .layout = pipeline_layout,
    .primitive = .{
      .frontFace = gpu.WGPUFrontFace_CCW,
      .cullMode = gpu.WGPUCullMode_None,
      .topology = gpu.WGPUPrimitiveTopology_TriangleList,
      .stripIndexFormat = gpu.WGPUIndexFormat_Undefined,
    },
    .vertex = .{
      .module = shader_triangle,
      .entryPoint = .{ .data = "vs_main", .length = 7},
      .bufferCount = 1,
      .buffers = &vertex_buffer_layout,
    },
    .fragment = &gpu.WGPUFragmentState{
      .module = shader_triangle,
      .entryPoint = .{ .data = "fs_main", .length = 7},
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
  log(.info, "Render Pipeline completed!", .{});
}

//#endregion ==================================================================
//#region MARK: SHADERDATA
//=============================================================================
fn gpuShaderData() void {
  log(.info, "Render ShaderData starting...", .{});
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
  web.vbuffer = createBuffer(&vertex_data, @sizeOf(@TypeOf(vertex_data)), gpu.WGPUBufferUsage_Vertex);
  web.ibuffer = createBuffer(&index_data, @sizeOf(@TypeOf(index_data)), gpu.WGPUBufferUsage_Index);
  web.ubuffer = createBuffer(&web.vars_rot, 16, gpu.WGPUBufferUsage_Uniform);
  web.bindgroup = gpu.wgpuDeviceCreateBindGroup(web.device, &gpu.WGPUBindGroupDescriptor{
    .layout = gpu.wgpuRenderPipelineGetBindGroupLayout(web.pipeline, 0),
    .entryCount = 1,
    .entries = &gpu.WGPUBindGroupEntry{
      .binding = 0,
      .offset = 0,
      .buffer = web.ubuffer,
      .size = @sizeOf(@TypeOf(web.vars_rot)),
    },
  });
  log(.info, "Render ShaderData completed!", .{});
}

fn stopAll() void {
  gpu.wgpuRenderPipelineRelease(web.pipeline);
  gpu.wgpuQueueRelease(web.queue);
  gpu.wgpuDeviceRelease(web.device);
  gpu.wgpuInstanceRelease(web.instance);
}

//#endregion ==================================================================
//#region MARK: SHADER
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
//#region MARK: UTILS
//=============================================================================
fn createShader(code: [*:0]const u8, label: [*:0]const u8) gpu.WGPUShaderModule {
  var wgsl = gpu.WGPUShaderSourceWGSL{
    .chain = .{ .sType = gpu.WGPUSType_ShaderSourceWGSL },
    .code = .{ .data = code, .length = std.mem.len(code) },
  };

  return gpu.wgpuDeviceCreateShaderModule(web.device, &gpu.WGPUShaderModuleDescriptor{
    .nextInChain = @ptrCast(&wgsl),
    .label = .{
      .data = label,
      .length = std.mem.len(label),
    },
  });
}

fn createBuffer(data: ?*const anyopaque, size: usize, usage: gpu.WGPUBufferUsage) gpu.WGPUBuffer {
  const buffer = gpu.wgpuDeviceCreateBuffer(web.device, &gpu.WGPUBufferDescriptor{
    .usage = gpu.WGPUBufferUsage_CopyDst | usage,
    .size = size,
  });
  gpu.wgpuQueueWriteBuffer(web.queue, buffer, 0, data, size);
  return buffer;
}

//=============================================================================
//#region MARK: LOG
//=============================================================================
pub const LogLevel = enum {
  info,
  warn,
  err,
};

const LogInfo = struct {
  prefix: []const u8,
  func: []const u8,
};

fn log(level: LogLevel, comptime fmt: []const u8, args: anytype) void {
  const info = switch (level) {
    .info => LogInfo{ .prefix = "[INFO]", .func = "console.log" },
    .warn => LogInfo{ .prefix = "[WARN]", .func = "console.warn" },
    .err  => LogInfo{ .prefix = "[ERR] ", .func = "console.error" },
  };

  var msg_buf: [1024:0]u8 = @splat(0);
  var msg_buf_slice: []u8 = undefined;
  msg_buf_slice = std.fmt.bufPrint(&msg_buf, fmt, args) catch unreachable;

  var script_buf: [1024:0]u8 = @splat(0);
  var script_buf_slice: []u8 = undefined;
  script_buf_slice = std.fmt.bufPrint(&script_buf,
    "{s}('[WebGPU] {s} {s}')",
    .{ info.func, info.prefix, msg_buf[0..msg_buf_slice.len] }) catch return;
  script_buf[script_buf_slice.len] = '0';
  jsPrint(&script_buf, script_buf_slice.len);
  jsPrintFlush();
}