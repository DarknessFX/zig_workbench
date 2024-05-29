const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_microui/lib/SDL2/include/SDL.h"); 
const im = @cImport({
  @cInclude("lib/imgui/cimgui.h");
  @cInclude("lib/imgui/cimgui_impl_sdl3.h");
  @cInclude("lib/imgui/cimgui_impl_sdlrenderer3.h");
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

pub fn main() void {
  HideConsole();

  _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_TIMER | sdl.SDL_INIT_GAMEPAD);
  _ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_SHOW_UI, "1");

  const window_flags: sdl.SDL_WindowFlags = sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIGH_PIXEL_DENSITY | sdl.SDL_WINDOW_HIDDEN;
  const window: *sdl.SDL_Window = sdl.SDL_CreateWindow("Dear ImGui SDL3+SDL_Renderer example", 1280, 720, window_flags).?;
  const renderer: *sdl.SDL_Renderer = sdl.SDL_CreateRenderer(window, null, sdl.SDL_RENDERER_PRESENTVSYNC | sdl.SDL_RENDERER_ACCELERATED).?;
  _ = sdl.SDL_SetWindowPosition(window, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED);
  _ = sdl.SDL_ShowWindow(window);

  _ = im.ImGui_CreateContext(null);
  var io: *im.struct_ImGuiIO_t = im.ImGui_GetIO();
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
  io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable;       // Enable Docking

  im.ImGui_StyleColorsDark(null);

  const cwindow = @as(?*im.SDL_Window , @ptrCast(window));
  const crenderer = @as(?*im.SDL_Renderer , @ptrCast(renderer));
  _ = im.cImGui_ImplSDL3_InitForSDLRenderer(cwindow, crenderer);
  _ = im.cImGui_ImplSDLRenderer3_Init(crenderer);

  var show_demo_window: bool = true;
  var show_another_window: bool = false;
  var clear_color: ImVec4 = ImVec4{.x=0.45, .y=0.55, .z=0.60, .w=1.00};
  var f: f32 = 0.0;
  var counter: u16 = 0;

  var event: sdl.SDL_Event = undefined;
  const cevent = @as([*c]const im.SDL_Event , @ptrCast(&event));
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

    im.cImGui_ImplSDLRenderer3_NewFrame();
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
    _ = sdl.SDL_SetRenderDrawColor(renderer, 
      toU8(clear_color.x * 255), toU8(clear_color.y * 255),
      toU8(clear_color.z * 255), toU8(clear_color.w * 255));
    _ = sdl.SDL_RenderClear(renderer);
    im.cImGui_ImplSDLRenderer3_RenderDrawData(im.ImGui_GetDrawData());
    _ = sdl.SDL_RenderPresent(renderer);
  }

  im.cImGui_ImplSDLRenderer3_Shutdown();
  im.cImGui_ImplSDL3_Shutdown();
  im.ImGui_DestroyContext(null);

  sdl.SDL_DestroyRenderer(renderer);
  sdl.SDL_DestroyWindow(window);
  sdl.SDL_Quit();

  return;
}

fn toU8(value: f32) u8 {
  return @as(u8, @intFromFloat(value));
}

fn HideConsole() void {
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);
}

extern "kernel32" fn GetConsoleTitleA(
    lpConsoleTitle: win.LPSTR,
    nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

extern "kernel32" fn FindWindowA(
    lpClassName: ?win.LPSTR,
    lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;

const SW_HIDE = 0;
extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: win.INT
) callconv(WINAPI) void;