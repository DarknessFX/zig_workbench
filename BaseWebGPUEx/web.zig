//!zig-autodoc-section: BaseWebGPU\\web.zig
//! web.zig :
//!	  HTML5 WASM WebGPU source code (portable and offline).
// Build using Zig 0.13.0
const std = @import("std");
const wsm = @import("shared.zig");
const log = wsm.log;
pub const gpu = @cImport({
  @cInclude("emscripten.h");
  @cInclude("emscripten/html5.h");
  @cInclude("emscripten/html5_webgpu.h");
  @cDefine("IMGUI_ENABLE_FREETYPE", "1");
  @cInclude("dcimgui.h");
  @cInclude("dcimgui_impl_sdl2.h");
  @cInclude("dcimgui_impl_wgpu.h");
  @cInclude("SDL.h");
  @cInclude("webgpu.h");
});

const roboto_ttf = @embedFile("lib/imgui/Roboto-Medium.ttf");

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

  var ui: gpu.ImGuiIO = undefined;
  var ui_initinfo: gpu.ImGui_ImplWGPU_InitInfo = undefined;
  var ui_font: *gpu.ImFont = undefined;
  var ui_fontatlas: gpu.ImFontAtlas = undefined;
};

// ============================================================================
// WORK IN PROGRESS
//
fn startImGui() void {

  // var customRects: gpu.ImFontAtlasCustomRect = gpu.ImFontAtlasCustomRect{};
  //   .Width = 1280,
  //   .Height = 720,
  //   .X = 0xFFFF,
  //   .Y = 0xFFFF,
  //   .GlyphID = 0,
  //   .GlyphColored = 0,
  //   .GlyphAdvanceX = 0.0,
  //   .GlyphOffset = gpu.ImVec2{ .x = 0, .y = 0 },
  //   .Font = null,
  // };

  // web.ui_fontatlas = gpu.ImFontAtlas{
  //   .Size = @sizeOf(customRects),
  //   .Capacity = 1,
  //   .Data = &customRects,
  // };

  web.ui_fontatlas = gpu.ImFontAtlas{};
  web.ui_font =  gpu.ImFontAtlas_AddFontFromMemoryTTF(
    &web.ui_fontatlas, 
    @as(?*anyopaque, @ptrCast(@constCast(roboto_ttf))),
    roboto_ttf.len,
    16.0, null, null);

  // log("FontAtlas_Build() {}", .{ 
  //   gpu.ImFontAtlas_Build( &web.ui_fontatlas )
  // });

  // const fontatlas_rect = gpu.ImFontAtlasCustomRect_t;
  // fontatlas_rect.Width = 1280;
  // fontatlas_rect.Height = 720;
  // fontatlas_rect.X = 0;
  // fontatlas_rect.Y = 0;
  // fontatlas_rect.GlyphID = 31;
  // fontatlas_rect.GlyphColored = 1;
  // fontatlas_rect.GlyphAdvanceX = 0.0;
  // fontatlas_rect.GlyphOffset = gpu.ImVec2{ .x = 0.0 , .y = 0.0 };
  // fontatlas_rect.Font = web.ui_font;

  // log("IsPacked() {}", .{ 
  //   gpu.ImFontAtlasCustomRect_IsPacked(
  //     fontatlas_rect
  //   )
  // });

  // &gpu.ImFontConfig{.FontDataOwnedByAtlas = false, }    
  //web.ui_font =  gpu.ImFontAtlas_AddFontFromMemoryTTF(&web.ui_fontatlas, null);
  //web.ui_font = gpu.ImFontAtlas_AddFontDefault(&web.ui_fontatlas, null);

  // Setup Dear ImGui context
  const ui_context = gpu.ImGui_CreateContext(&web.ui_fontatlas).?;
  _ = ui_context;

  web.ui = gpu.ImGui_GetIO().*;
  web.ui.ConfigFlags |= gpu.ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
  web.ui.ConfigFlags |= gpu.ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
  web.ui.ConfigFlags |= gpu.ImGuiConfigFlags_DockingEnable;         // Enable Docking

  // Setup Dear ImGui style
  gpu.ImGui_StyleColorsDark(null);

  web.ui.DisplaySize.x = 1280;
  web.ui.DisplaySize.y = 720;
  web.ui.Fonts = &web.ui_fontatlas;
  web.ui.FontDefault = web.ui_font;

  // Setup Platform/Renderer backends
  log("SDL_InitOther {}", .{ gpu.cImGui_ImplSDL2_InitForOther(web.window) });

  web.ui_initinfo = gpu.ImGui_ImplWGPU_InitInfo{};
  web.ui_initinfo.Device = web.device;
  web.ui_initinfo.NumFramesInFlight = 3;
  web.ui_initinfo.RenderTargetFormat = gpu.WGPUTextureFormat_RGBA8Unorm;
  web.ui_initinfo.DepthStencilFormat = gpu.WGPUTextureFormat_Undefined;
  web.ui_initinfo.Surface = web.surface;
  log("WGPU_Init {}", .{ gpu.cImGui_ImplWGPU_Init(&web.ui_initinfo) });
}

fn RenderImGUI() void {
  var show_demo_window = true;
  var show_another_window = false;
  var clear_color: gpu.ImVec4 = .{ .x = 0.45, .y = 0.55, .w = 0.60, .z = 1.00 };
  var f: f32 = 0.0;
  var counter: u16 = 0;

  //_ = gpu.cImGui_ImplWGPU_CreateDeviceObjects();
  log("ImplSDL2_NewFrame", .{});
  gpu.cImGui_ImplSDL2_NewFrame();
  log("ImplWGPU_NewFrame", .{});
  gpu.cImGui_ImplWGPU_NewFrame();
  log("ImGui_NewFrame", .{});
  gpu.ImGui_NewFrame();

  //_ = gpu.ImGui_DockSpaceOverViewport();

  if (show_demo_window)
      gpu.ImGui_ShowDemoWindow(&show_demo_window);

  {
      _ = gpu.ImGui_Begin("Hello, world!", null, gpu.ImGuiWindowFlags_NoSavedSettings);
      gpu.ImGui_Text("This is some useful text.");
      _ = gpu.ImGui_Checkbox("Demo Window", &show_demo_window);
      _ = gpu.ImGui_Checkbox("Another Window", &show_another_window);

      _ = gpu.ImGui_SliderFloat("float", &f, 0.0, 1.0);
      _ = gpu.ImGui_ColorEdit3("clear color", @as([*c]f32, &clear_color.x), 0);

      if (gpu.ImGui_Button("Button"))
          counter += 1;
      gpu.ImGui_SameLine();
      gpu.ImGui_Text("counter = %d", counter);

      gpu.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / web.ui.Framerate, web.ui.Framerate);
      gpu.ImGui_End();
  }

  if (show_another_window) {
      _ = gpu.ImGui_Begin("Hello, world!", &show_another_window, gpu.ImGuiWindowFlags_NoSavedSettings);
      gpu.ImGui_Text("Hello from another window");
      if (gpu.ImGui_Button("Close Me"))
          show_another_window = false;
      gpu.ImGui_End();
  }

  // if (show_memedit_window) {
  //   gpu.MemoryEditor_DrawWindow(&mem_edit, "Memory Editor", &mem_data, mem_data.len);
  // }
  //gpu.ImGui_Render();

  log("RenderImGui", .{});
  //const clear_color: gpu.ImVec4  = ImVec4(0.0f, 0.0f, 0.0f, 1.0f);
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
    .depthStencilAttachment = null,
  });

  gpu.cImGui_ImplWGPU_RenderDrawData(gpu.ImGui_GetDrawData(), render_pass);
  gpu.wgpuRenderPassEncoderEnd(render_pass);

  const cmd_buffer = gpu.wgpuCommandEncoderFinish(cmd_encoder, null);
  gpu.wgpuQueueSubmit(web.queue, 1, &cmd_buffer);

  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuTextureViewRelease(back_buffer);

}

fn RenderFrame() callconv(.C) void {
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

  //RenderSDL();
  //RenderImGUI();

  gpu.wgpuRenderPassEncoderRelease(render_pass);
  gpu.wgpuCommandEncoderRelease(cmd_encoder);
  gpu.wgpuCommandBufferRelease(cmd_buffer);
  gpu.wgpuTextureViewRelease(back_buffer);
}

fn RenderSDL() void {
  // var squareRect: gpu.SDL_Rect = gpu.SDL_Rect{ .w = 1280, .h = 720, .x = 0, .y = 0, };

  // gpu.SDL_SetRenderDrawColor(web.renderer, 0xFF, 0x00, 0x00, 0xFF);
  // gpu.SDL_RenderFillRect(web.renderer, &squareRect);
}

//
// WORK IN PROGRESS
// ============================================================================



// ============================================================================
// Main
//
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
) callconv(.C) void {
  _ = instance; _ = message; _ = userData;
  web.adapter = adapter;

  gpu.wgpuAdapterRequestDevice(adapter, &gpu.WGPUDeviceDescriptor{}, obtainedWebGpuDevice, null);
}

fn obtainedWebGpuDevice(
  instance: c_uint, 
  device: gpu.WGPUDevice, 
  message: [*c]const u8, 
  userData: ?*anyopaque
) callconv(.C) void {
  _ = instance; _ = message; _ = userData;
  web.device = device;

  main_continue();
}

fn main_continue() void {
  startSDL();
  startImGui();

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


//--------------------------------------------------
// Callbacks
//--------------------------------------------------
export fn onWindowResize(callback: ?*anyopaque) void {
  _ = callback;

  var w: f64 = 0; var h: f64 = 0;
  _ = gpu.emscripten_get_element_css_size(web.canvas.name.ptr, &w, &h);
  web.canvas.width = @intFromFloat(w);
  web.canvas.height = @intFromFloat(h);
  web.ui.DisplaySize.x = @as(f32, @floatCast(w));
  web.ui.DisplaySize.y = @as(f32, @floatCast(h));
  if (web.swapchain != null) {
    gpu.wgpuSwapChainRelease(web.swapchain);
    web.swapchain = null;
  }
  web.swapchain = createSwapchain();  
}


// ============================================================================
// Functions
//
fn startSDL() void {
  _ = gpu.SDL_Init(gpu.SDL_INIT_EVERYTHING);
  web.window = gpu.SDL_CreateWindow(
    "BaseWebGPUEx", gpu.SDL_WINDOWPOS_CENTERED, gpu.SDL_WINDOWPOS_CENTERED, 1280, 720, 0)
    orelse undefined;
  // _ = gpu.SDL_SetRelativeMouseMode(gpu.SDL_TRUE); // Capture Mouse?
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

// ============================================================================
// Tools
//
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


//--------------------------------------------------
// vertex and fragment shaders
//--------------------------------------------------
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
