//!zig-autodoc-section: BaseWebGPU\\web.zig
//! web.zig :
//!  HTML5 WASM WebGPU source code (portable and offline).
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const wsm = @import("shared.zig");
const log = wsm.log;
pub const gpu = @cImport({
  @cInclude("emscripten.h");
  @cInclude("emscripten/html5.h");
  @cInclude("emscripten/html5_webgpu.h");
  @cInclude("webgpu.h");
});

const web = struct {
  var isRunning: bool = false;
  var window: *(gpu.SDL_Window) = undefined;

  var instance: gpu.WGPUInstance = null;
  var adapter: gpu.WGPUAdapter = null;
  var device: gpu.WGPUDevice = null;
  var surface: gpu.WGPUSurface = null;
  var pipeline: gpu.WGPURenderPipeline = null;
  var queue: gpu.WGPUQueue = null;
  var swapchain: gpu.WGPUSwapChain = null;

  var vbuffer: gpu.WGPUBuffer = null;
  var ibuffer: gpu.WGPUBuffer = null;
  var ubuffer: gpu.WGPUBuffer = null;
  var bindgroup: gpu.WGPUBindGroup = null;
  var vars_rot: f32 = 0.0;

  const canvas = struct {
    var name: []const u8 = "";
    var width: i32 = 0;
    var height: i32 = 0;
  };
};


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !void {
  web.canvas.name = "canvas";
  web.instance = gpu.wgpuCreateInstance(null);
  gpu.wgpuInstanceRequestAdapter(web.instance, 
    &[_]gpu.WGPURequestAdapterOptions{
      gpu.WGPURequestAdapterOptions{
        .powerPreference = gpu.WGPUPowerPreference_LowPower,
      },
    }, 
    obtainedWebGpuAdapter,
    null
  );
}

fn obtainedWebGpuAdapter(
  instance: c_uint, 
  adapter: gpu.WGPUAdapter, 
  message: [*c]const u8, 
  userData: ?*anyopaque
) callconv(.c) void {
  _ = instance; _ = message; _ = userData;
  web.adapter = adapter;

  gpu.wgpuAdapterRequestDevice(adapter, &gpu.WGPUDeviceDescriptor{}, obtainedWebGpuDevice, null);
}

fn obtainedWebGpuDevice(
  instance: c_uint, 
  device: gpu.WGPUDevice, 
  message: [*c]const u8, 
  userData: ?*anyopaque
) callconv(.c) void {
  _ = instance; _ = message; _ = userData;
  web.device = device;

  main_continue();
}

fn main_continue() void {
  // Start WebGPU
  {
    startQueueSwapchain();
    startRenderPipeline();
    startShaderData();    
  }

  web.isRunning = true;
  gpu.emscripten_set_main_loop(RenderFrame, 0, true);

  // Stop WebGPU
  {
    stopAll();
  }
}


//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn RenderFrame() callconv(.c) void {
  web.vars_rot += 0.1;
  web.vars_rot = if (web.vars_rot >= 360) 0.0 else web.vars_rot;
  gpu.wgpuQueueWriteBuffer(web.queue, web.ubuffer, 0, &web.vars_rot, @sizeOf(@TypeOf(web.vars_rot)));

  const back_buffer = gpu.wgpuSwapChainGetCurrentTextureView(web.swapchain);
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
  gpu.wgpuRenderPassEncoderSetBindGroup(render_pass, 0, web.bindgroup, 0, 0);
  gpu.wgpuRenderPassEncoderSetVertexBuffer(render_pass, 0, web.vbuffer, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderSetIndexBuffer(render_pass, web.ibuffer, gpu.WGPUIndexFormat_Uint16, 0, gpu.WGPU_WHOLE_SIZE);
  gpu.wgpuRenderPassEncoderDrawIndexed(render_pass, 6, 1, 0, 0, 0);

  gpu.wgpuRenderPassEncoderEnd(render_pass);
  const cmd_buffer = gpu.wgpuCommandEncoderFinish(cmd_encoder, null);
  gpu.wgpuQueueSubmit(web.queue, 1, &cmd_buffer);

  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuTextureViewRelease(back_buffer);
}

fn startQueueSwapchain() void {
  web.queue = gpu.wgpuDeviceGetQueue(web.device);
  var w: f64 = 0; var h: f64 = 0;
  _ = gpu.emscripten_get_element_css_size(web.canvas.name.ptr, &w, &h);
  web.canvas.width = @intFromFloat(w);
  web.canvas.height = @intFromFloat(h);
  web.swapchain = createSwapchain();
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
      .entryPoint = "vs_main",
      .bufferCount = 1,
      .buffers = &vertex_buffer_layout,
    },
    .fragment = &gpu.WGPUFragmentState{
      .module = shader_triangle,
      .entryPoint = "fs_main",
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
  web.vbuffer = createBuffer(&vertex_data, @sizeOf(@TypeOf(vertex_data)), gpu.WGPUBufferUsage_Vertex);
  web.ibuffer = createBuffer(&index_data, @sizeOf(@TypeOf(index_data)), gpu.WGPUBufferUsage_Index);
  web.ubuffer = createBuffer(&web.vars_rot, @sizeOf(@TypeOf(web.vars_rot)), gpu.WGPUBufferUsage_Uniform);
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
}

fn stopAll() void {
  gpu.wgpuRenderPipelineRelease(web.pipeline);
  gpu.wgpuSwapChainRelease(web.swapchain);
  gpu.wgpuQueueRelease(web.queue);
  gpu.wgpuDeviceRelease(web.device);
  gpu.wgpuInstanceRelease(web.instance);
}

//#endregion ==================================================================
//#region MARK: CALLBACKS
//=============================================================================
export fn onWindowResize(callback: ?*anyopaque) void {
  _ = callback;

  var w: f64 = 0; var h: f64 = 0;
  _ = gpu.emscripten_get_element_css_size(web.canvas.name.ptr, &w, &h);
  web.canvas.width = @intFromFloat(w);
  web.canvas.height = @intFromFloat(h);
  if (web.swapchain != null) {
    gpu.wgpuSwapChainRelease(web.swapchain);
    web.swapchain = null;
  }
  web.swapchain = createSwapchain();  
}


//#endregion ==================================================================
//#region MARK: TOOLS
//=============================================================================
fn createSwapchain() gpu.WGPUSwapChain {
  const surface = gpu.wgpuInstanceCreateSurface(web.instance, &gpu.WGPUSurfaceDescriptor{
    .nextInChain = @ptrCast(&gpu.WGPUSurfaceDescriptorFromCanvasHTMLSelector{
      .chain = .{ .sType = gpu.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector },
      .selector = web.canvas.name.ptr,
    }),
  });

  return gpu.wgpuDeviceCreateSwapChain(web.device, surface, &gpu.WGPUSwapChainDescriptor{
    .usage = gpu.WGPUTextureUsage_RenderAttachment,
    .format = gpu.WGPUTextureFormat_BGRA8Unorm,
    .width = @intCast(web.canvas.width),
    .height = @intCast(web.canvas.height),
    .presentMode = gpu.WGPUPresentMode_Fifo,
  });
}

fn createShader(code: [*:0]const u8, label: [*:0]const u8) gpu.WGPUShaderModule {
  const wgsl = gpu.WGPUShaderModuleWGSLDescriptor{
    .chain = .{ .sType = gpu.WGPUSType_ShaderModuleWGSLDescriptor },
    .code = code,
  };

  return gpu.wgpuDeviceCreateShaderModule(web.device, &gpu.WGPUShaderModuleDescriptor{
    .nextInChain = @ptrCast(&wgsl),
    .label = label
  });
}

fn createBuffer(data: ?*const anyopaque, size: usize, usage: gpu.WGPUBufferUsage) gpu.WGPUBuffer {
  const buffer = gpu.wgpuDeviceCreateBuffer(web.device, &gpu.WGPUBufferDescriptor{
    .usage = @as(gpu.enum_WGPUBufferUsage, gpu.WGPUBufferUsage_CopyDst) | usage,
    .size = size,
  });
  gpu.wgpuQueueWriteBuffer(web.queue, buffer, 0, data, size);
  return buffer;
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
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================