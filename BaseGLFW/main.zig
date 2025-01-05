//!zig-autodoc-section: BaseGLFW.Main
//! BaseGLFW//main.zig :
//!   Template using GLFW3.
// Build using Zig 0.13.0

const std = @import("std");

const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};

// Remember to copy lib/GLFW/glfw3.dll to Zig.exe Folder PATH
// Change @cInclude to full path
const glfw = @cImport({
  @cInclude("lib/glad/include/glad.h");
  @cInclude("lib/glfw/include/glfw3.h");
});


pub fn main() void {
  // Hide console window
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);
  // ===
  

  _ = glfw.glfwInit();
  const window = glfw.glfwCreateWindow(800, 640, "GLFW3 Window", null, null);
  while (glfw.glfwWindowShouldClose(window) == 0) {
    //render(window);

    glfw.glfwSwapBuffers(window);
    glfw.glfwPollEvents();
  }

  glfw.glfwDestroyWindow(window);
  glfw.glfwTerminate();
}

pub extern "kernel32" fn GetConsoleTitleA(
    lpConsoleTitle: win.LPSTR,
    nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

pub extern "kernel32" fn FindWindowA(
    lpClassName: ?win.LPSTR,
    lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;

const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(hWnd: win.HWND, nCmdShow: i32) callconv(win.WINAPI) win.BOOL;

//
// Tests section
//
test " " {
}
