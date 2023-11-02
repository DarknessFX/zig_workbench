// ImGui_impl_SDL3_OpenGL3
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
  @cInclude("lib/imgui/cimgui_impl_sdl3.h");
  @cInclude("lib/imgui/cimgui_impl_opengl3.h");
});

const sdl = @cImport({
  @cInclude("lib/SDL3/include/SDL.h");
  @cInclude("lib/SDL3/include/SDL_opengl.h");
});

const ImVec4 = struct {
  x: f32,
  y: f32,
  z: f32,
  w: f32
};

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hInstance;
  _ = hPrevInstance;
  _ = pCmdLine;
  _ = nCmdShow;

  const glsl_version = "#version 150";
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, sdl.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG); // Always required on Mac
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 2);
  _ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_SHOW_UI, "1");

  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_STENCIL_SIZE, 8);
  var window_flags: sdl.SDL_WindowFlags = sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIDDEN;
  var window: *sdl.SDL_Window = sdl.SDL_CreateWindow("Dear ImGui SDL3+OpenGL3 example", 1280, 720, window_flags).?;
  defer sdl.SDL_DestroyWindow(window);

  _ = sdl.SDL_SetWindowPosition(window, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED);
  var  gl_context: sdl.SDL_GLContext = sdl.SDL_GL_CreateContext(window);
  _ = sdl.SDL_GL_MakeCurrent(window, gl_context);
  _ = sdl.SDL_GL_SetSwapInterval(1); // Enable vsync
  _ = sdl.SDL_ShowWindow(window);

  _ = im.ImGui_CreateContext(null);
  var io: *im.struct_ImGuiIO_t = im.ImGui_GetIO();
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable;       // Enable Docking
  io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable;       // Enable Multi-Viewport / Platform Windows
  //io.ConfigViewportsNoAutoMerge = true;
  //io.ConfigViewportsNoTaskBarIcon = true;

  im.ImGui_StyleColorsDark(null);

  var  style: im.ImGuiStyle = im.ImGui_GetStyle().*;
  if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
      style.WindowRounding = 0.0;
      style.Colors[im.ImGuiCol_WindowBg].w = 1.0;
  }

  var cwindow = @as(?*im.SDL_Window , @ptrCast(window));
  _ = im.cImGui_ImplSDL3_InitForOpenGL(cwindow, gl_context);
  _ = im.cImGui_ImplOpenGL3_InitEx(glsl_version);

  var show_demo_window: bool = true;
  var show_another_window: bool = false;
  var clear_color: ImVec4 = ImVec4{.x=0.45, .y=0.55, .z=0.60, .w=1.00};
  var f: f32 = 0.0;
  var counter: u16 = 0;

  var event: sdl.SDL_Event = undefined;
  var cevent = @as([*c]const im.SDL_Event , @ptrCast(&event));
  var done: bool = false;
  while (!done) {
    while (sdl.SDL_PollEvent(&event) == 1) {
      _ = im.cImGui_ImplSDL3_ProcessEvent(cevent);
      if (event.type == sdl.SDL_EVENT_QUIT) {
        done = true; }
      if (event.type == sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED  and 
        event.window.windowID == sdl.SDL_GetWindowID(window)) {
        done = true; }
    }

    im.cImGui_ImplOpenGL3_NewFrame();
    im.cImGui_ImplSDL3_NewFrame();
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
    sdl.glViewport(0, 0, toCInt(io.DisplaySize.x), toCInt(io.DisplaySize.y));
    sdl.glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
    sdl.glClear(sdl.GL_COLOR_BUFFER_BIT);
    im.cImGui_ImplOpenGL3_RenderDrawData(im.ImGui_GetDrawData());

    if (io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
      var backup_current_window: *sdl.SDL_Window = sdl.SDL_GL_GetCurrentWindow().?;
      var backup_current_context: sdl.SDL_GLContext = sdl.SDL_GL_GetCurrentContext().?;
      im.ImGui_UpdatePlatformWindows();
      im.ImGui_RenderPlatformWindowsDefault();
      _ = sdl.SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
    }

    _ = sdl.SDL_GL_SwapWindow(window);
  }

  im.cImGui_ImplOpenGL3_Shutdown();
  im.cImGui_ImplSDL3_Shutdown();
  im.ImGui_DestroyContext(null);

  _ = sdl.SDL_GL_DeleteContext(gl_context);
  sdl.SDL_DestroyWindow(window);
  sdl.SDL_Quit();

  return 0;
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}

fn toCInt(value: f32) c_int {
  return @as(c_int, @intFromFloat(value));
}
