//!zig-autodoc-section: BaseNanoVG.Main
//! BaseNanoVG//main.zig :
//!   Template using NanoVG and GLFW3.
// Build using Zig 0.13.0

const std = @import("std");

// Remember to copy lib/GLFW/glfw3.dll to Zig.exe Folder PATH
// Change @cInclude to full path
const nvg = @cImport({
  @cDefine("GLFW_INCLUDE_NONE", "1");  // Must have, without it the template crashes. 
  @cInclude("lib/glad/include/glad.h");
  @cInclude("lib/glfw/include/glfw3.h");
  @cDefine("NANOVG_GL3_IMPLEMENTATION", "1");
  @cInclude("lib/nanovg/nanovg.h");
  @cInclude("lib/nanovg/nanovg_gl.h");
});

pub fn main() u8 {
  HideConsoleWindow();

  // Initialize GLFW
  if (nvg.glfwInit() == 0) {
    std.debug.print("Failed to initialize GLFW\n", .{});
    return;
  }
  defer nvg.glfwTerminate();

  nvg.glfwWindowHint(nvg.GLFW_CONTEXT_VERSION_MAJOR, 3);
  nvg.glfwWindowHint(nvg.GLFW_CONTEXT_VERSION_MINOR, 3);
  nvg.glfwWindowHint(nvg.GLFW_OPENGL_PROFILE, nvg.GLFW_OPENGL_CORE_PROFILE);
  nvg.glfwWindowHint(nvg.GLFW_OPENGL_DEBUG_CONTEXT, nvg.GLFW_TRUE);
  //nvg.glfwWindowHint(nvg.GLFW_SAMPLES, 4);

  // Create a windowed mode window and its OpenGL context
  const window = nvg.glfwCreateWindow(800, 600, "NanoVG with GLFW3", null, null) orelse {
    std.debug.print("Failed to create GLFW window\n", .{});
    return;
  };
  defer nvg.glfwDestroyWindow(window);

  nvg.glfwMakeContextCurrent(window);

  // Checking Glad context to help debug a crash.
  if (nvg.gladLoadGL(@ptrCast(&nvg.glfwGetProcAddress)) == 0) {
    std.debug.print("Failed to initialize GLAD\n", .{});
    return;
  }

  // Initialize NanoVG
  const vg = nvg.nvgCreateGL3(nvg.NVG_ANTIALIAS | nvg.NVG_STENCIL_STROKES) orelse {
    std.debug.print("Could not init nanovg\n", .{});
    return;
  };
  defer nvg.nvgDeleteGL3(vg);

  // Main loop
  var time: f32 = 0.0;
  while (nvg.glfwWindowShouldClose(window) == 0) {
    time += 0.01; // Increment time for animation

    nvg.glfwPollEvents();

    nvg.glClearColor(0.0, 0.0, 0.0, 1.0); // Black background
    nvg.glClear(nvg.GL_COLOR_BUFFER_BIT);

    nvg.nvgBeginFrame(vg, 800, 600, 1.0);

    nvg.nvgBeginPath(vg);
    // Animate rectangle position with sine function
    const x = 100.0 + 100 * @sin(time);
    const y = 100.0 + 100 * @cos(time);
    nvg.nvgRect(vg, x, y, 300, 200);
    nvg.nvgFillColor(vg, nvg.nvgRGBA(255, 0, 0, 255));
    nvg.nvgFill(vg);

    nvg.nvgEndFrame(vg);

    nvg.glfwSwapBuffers(window);
  }

  return 0;
}


// ============================================================================
// Helpers
//
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};

fn HideConsoleWindow() void {
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);
}

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
