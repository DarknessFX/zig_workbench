const std = @import("std");
pub extern fn main() void; // Zig Main, ignored, using SDL3

const im = @cImport({
  @cInclude("dcimgui.h");
  @cInclude("dcimgui_impl_sdl3.h");
  @cInclude("dcimgui_impl_opengl3.h");
  @cInclude("dcimgui_memory_editor.h");
});
const IMGUI_IMPL_OPENGL_CORE: bool = true;
var io: *im.struct_ImGuiIO_t = undefined;

const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
  @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
  @cInclude("SDL.h");
  @cInclude("SDL_main.h");
  @cInclude("SDL_opengl.h");
});

const APP_TITLE = "SDL3+DearImGui";
const APP_WINDOW_WIDTH = 1280;
const APP_WINDOW_HEIGHT = 720;

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;
var context: sdl.SDL_GLContext = undefined;
var cwindow: *im.SDL_Window = undefined;


var show_demo_window: bool = true;
var show_another_window: bool = false;
const show_memedit_window = true;
var mem_edit = im.MemoryEditor {
  // Settings
  .Open = true,
  .ReadOnly = false,
  .Cols = 16,
  .OptShowOptions = true,
  .OptShowDataPreview = false,
  .OptShowHexII = false,
  .OptShowAscii = true,
  .OptGreyOutZeroes = true,
  .OptUpperCaseHex = true,
  .OptMidColsCount = 8,
  .OptAddrDigitsCount = 0,
  .OptFooterExtraHeight = 0.0,
  .HighlightColor = im.IM_COL32(255, 255, 255, 50),
  .ReadFn = null,
  .WriteFn = null,
  .HighlightFn = null,
};
var mem_data: [1000]c_char = std.mem.zeroes([1000]c_char);

var clear_color: im.ImVec4 = im.ImVec4{.x=0.45, .y=0.55, .z=0.60, .w=1.00};
var f: f32 = 0.0;
var counter: u16 = 0;


//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;
  const appTitle = "BaseSDL3";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.base-sdl3");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_GAMEPAD)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  const glsl_version: []const u8 = if (IMGUI_IMPL_OPENGL_CORE)
    "#version 130" else "#version 300 es";
  if (IMGUI_IMPL_OPENGL_CORE) {
    // GL 3.0 + GLSL 130
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, 0);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 6);
  } else {
    // GL ES 3.0 + GLSL 300 es (WebGL 2.0)
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, 0);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_ES);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 2);
  }

  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, sdl.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG); // Always required on Mac
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_STENCIL_SIZE, 8);
  _ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_IMPLEMENTED_UI, "1");

  const window_flags = sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIDDEN;

  if (!sdl.SDL_CreateWindowAndRenderer(APP_TITLE, APP_WINDOW_WIDTH, APP_WINDOW_HEIGHT, window_flags, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }
  _ = sdl.SDL_SetWindowPosition(window, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED);

  context = sdl.SDL_GL_CreateContext(window).?;
  _ = sdl.SDL_GL_MakeCurrent(window, context);
  _ = sdl.SDL_GL_SetSwapInterval(0); // Enable vsync
  _ = sdl.SDL_ShowWindow(window);

  _ = im.ImGui_CreateContext(null);
  io = im.ImGui_GetIO();
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable;         // Enable Docking
  io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable;       // Enable Multi-Viewport / Platform Windows
  //io.ConfigViewportsNoAutoMerge = true;
  //io.ConfigViewportsNoTaskBarIcon = true;

  im.ImGui_StyleColorsDark(null);

  var  style: im.ImGuiStyle = im.ImGui_GetStyle().*;
  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
      style.WindowRounding = 0.2;
      style.Colors[im.ImGuiCol_WindowBg].w = 0.15;
  }

  cwindow = @as(*im.SDL_Window , @ptrCast(window));
  _ = im.cImGui_ImplSDL3_InitForOpenGL(cwindow, context);
  _ = im.cImGui_ImplOpenGL3_InitEx(glsl_version.ptr);

  return sdl.SDL_APP_CONTINUE; // carry on with the program!
}

//* This function runs when a new event (mouse input, keypresses, etc) occurs. */
pub export fn SDL_AppEvent(appstate: ?*anyopaque, event: *sdl.SDL_Event) sdl.SDL_AppResult {
  _ = appstate;

  // SHIFT + ESC to quit
  if (event.key.key == sdl.SDLK_ESCAPE 
  and event.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
    return sdl.SDL_EVENT_QUIT;
  }

  if (event.*.type == sdl.SDL_EVENT_QUIT) {
    return sdl.SDL_APP_SUCCESS; // end the program, reporting success to the OS
  }

  _ = im.cImGui_ImplSDL3_ProcessEvent(@ptrCast(event));
  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once per frame, and is the heart of the program. */
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;

  const now: f64 = @as(f64, @floatFromInt(sdl.SDL_GetTicks())) / 1000.0;
  const red: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now)));
  const green: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 2 / 3)));
  const blue: f32 = 0.5 + 0.5 * @as(f32, @floatCast(sdl.SDL_sin(now + sdl.SDL_PI_D * 4 / 3)));
  // _ = sdl.SDL_SetRenderDrawColorFloat(renderer, red, green, blue, sdl.SDL_ALPHA_OPAQUE_FLOAT);
  // _ = sdl.SDL_RenderClear(renderer);

  im.cImGui_ImplOpenGL3_NewFrame();
  im.cImGui_ImplSDL3_NewFrame();
  im.ImGui_NewFrame();

  //_ = im.ImGui_DockSpaceOverViewport();
  
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

  if (show_memedit_window) {
    im.MemoryEditor_DrawWindow(&mem_edit, "Memory Editor", &mem_data, mem_data.len);
  }

  im.ImGui_Render();
  sdl.glViewport(0, 0, toCInt(io.DisplaySize.x), toCInt(io.DisplaySize.y));
  sdl.glClearColor(red, green, blue, sdl.SDL_ALPHA_OPAQUE_FLOAT);
  sdl.glClear(sdl.GL_COLOR_BUFFER_BIT);
  im.cImGui_ImplOpenGL3_RenderDrawData(im.ImGui_GetDrawData());

  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
    const backup_current_window: *sdl.SDL_Window = sdl.SDL_GL_GetCurrentWindow().?;
    const backup_current_context: sdl.SDL_GLContext = sdl.SDL_GL_GetCurrentContext().?;
    im.ImGui_UpdatePlatformWindows();
    im.ImGui_RenderPlatformWindowsDefault();
    _ = sdl.SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
  }

  _ = sdl.SDL_GL_SwapWindow(window);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  im.cImGui_ImplOpenGL3_Shutdown();
  im.cImGui_ImplSDL3_Shutdown();
  im.ImGui_DestroyContext(null);

  _ = sdl.SDL_GL_DestroyContext(context);
  sdl.SDL_DestroyWindow(window);

  //* SDL will clean up the window/renderer for us. */
}

fn toCInt(value: f32) c_int {
  return @as(c_int, @intFromFloat(value));
}