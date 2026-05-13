//!zig-autodoc-section: BaseRaylibImGui.Main
//! BaseRaylibImGui//main.zig :
//!   Template using RayLib and RayGUI and Dear ImGui.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib/include/raylib.h"); 
pub const ray = @cImport({ 
  @cInclude("lib/raylib/include/raylib.h");
  // @cDefine("RAYGUI_IMPLEMENTATION", "");
  @cInclude("lib/raylib/include/raygui.h");
  @cDefine("NO_FONT_AWESOME", "");
  @cInclude("lib/raylib/include/rlImGui.h");  
});

pub const im = @cImport({
  @cInclude("lib/imgui/dcimgui.h");
});

//Raylib
var isAppRunning: bool = false;

// ImGui
var im_io: *im.struct_ImGuiIO_t = undefined;
var im_style: im.ImGuiStyle = undefined;
const ImVec4 = struct { x: f32, y: f32, w: f32, z: f32 };
var show_demo_window = true;
var show_another_window = false;
var clear_color: ImVec4 = .{ .x = 0.45, .y = 0.55, .w = 0.60, .z = 1.00 };
var f: f32 = 0.0;
var counter: u16 = 0;


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !void {
  ray.InitWindow(1280, 720, "Raylib");

  switch (@import("builtin").target.cpu.arch) {
    .wasm32 => { 
      const web = @cImport({ @cInclude("emscripten/emscripten.h"); });
      web.emscripten_set_main_loop(webLoop, 60, true); 
    },
    else => { loop(); },
  }

  ray.CloseWindow();
}

//#endregion ==================================================================
//#region MARK: LOOP
//=============================================================================
fn loop() callconv(.c) void {
  ray.rlImGuiSetup(true); 
  _ = im.ImGui_CreateContext(null);
  im_io = im.ImGui_GetIO();
  im_io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
  im_io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls
  im_io.ConfigFlags |= im.ImGuiConfigFlags_DockingEnable; // Enable Docking
  im_io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable; // Enable Multi-Viewport / Platform Windows
  im.ImGui_StyleColorsDark(null);

  im_style = im.ImGui_GetStyle().*;
  if (im_io.ConfigFlags & im.ImGuiConfigFlags_ViewportsEnable != 0) {
    im_style.WindowRounding = 0.0;
    im_style.Colors[im.ImGuiCol_WindowBg].w = 1.0;
  }
  
  isAppRunning = true;
  while (isAppRunning and !ray.WindowShouldClose()) {
    ray.BeginDrawing();
    ray.rlImGuiBegin();	    
    ray.ClearBackground(ray.BLACK);
    ray.DrawText("Hello Raylib Windows+Web", 10, 10, 32, ray.GREEN);
    imDraw();
    ray.rlImGuiEnd();
    ray.EndDrawing();
  }
  ray.rlImGuiShutdown();
}

fn webLoop() callconv(.c) void {
  ray.BeginDrawing();
  ray.ClearBackground(ray.BLACK);
  ray.DrawText("Hello Raylib Windows+Web", 10, 10, 32, ray.GREEN);
  ray.DrawText(ray.TextFormat("Frame rate: %02.02f ms", ray.GetFrameTime() * 1000), ray.GetScreenWidth() - 360, 0, 20, ray.GREEN);
  ray.DrawText(ray.TextFormat("FPS: %d ms", ray.GetFPS()), ray.GetScreenWidth() - 160, 0, 20, ray.GREEN);
  ray.EndDrawing();
}

fn rayInput() void {
  if (ray.IsKeyDown(ray.KEY_LEFT_SHIFT) and ray.IsKeyPressed(ray.KEY_ESCAPE)) {
    isAppRunning = false; 
  }
}

fn imDraw() void {
  _ = im.ImGui_DockSpaceOverViewportEx(0, null, im.ImGuiDockNodeFlags_PassthruCentralNode, null);
  if (show_demo_window)
    im.ImGui_ShowDemoWindow(&show_demo_window);

  {
    _ = im.ImGui_Begin("Hello, world!", null, im.ImGuiWindowFlags_NoSavedSettings);
    im.ImGui_Text("This is some useful text.");
    _ = im.ImGui_Checkbox("Demo Window", &show_demo_window);
    _ = im.ImGui_Checkbox("Another Window", &show_another_window);

    _ = im.ImGui_SliderFloat("float", &f, 0.0, 1.0);
    _ = im.ImGui_ColorEdit3("clear color", @as([*c]f32, &clear_color.x), 0);

    if (im.ImGui_Button("Button"))
      counter += 1;
    im.ImGui_SameLine();
    im.ImGui_Text("counter = %d", counter);

    im.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / im_io.Framerate, im_io.Framerate);
    im.ImGui_End();
  }

  if (show_another_window) {
    _ = im.ImGui_Begin("Hello, world!", &show_another_window, im.ImGuiWindowFlags_NoSavedSettings);
    im.ImGui_Text("Hello from another window");
    if (im.ImGui_Button("Close Me"))
      show_another_window = false;
    im.ImGui_End();
  }
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================



//#endregion ==================================================================
//=============================================================================