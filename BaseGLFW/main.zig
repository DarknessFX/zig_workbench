//!zig-autodoc-section: BaseGLFW.Main
//! BaseGLFW//main.zig :
//!   Template using GLFW3.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const win = std.os.windows;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseGLFW/lib/glad/include/glfw3.h");
const glfw = @cImport({
  @cInclude("lib/glad/include/glad.h");
  @cInclude("lib/glfw/include/glfw3.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
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

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
pub extern "kernel32" fn GetConsoleTitleA(
    lpConsoleTitle: win.LPSTR,
    nSize: win.DWORD,
) callconv(.winapi) win.DWORD;

pub extern "kernel32" fn FindWindowA(
    lpClassName: ?win.LPSTR,
    lpWindowName: ?win.LPSTR,
) callconv(.winapi) win.HWND;

const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(hWnd: win.HWND, nCmdShow: i32) callconv(.winapi) win.BOOL;

//
// Tests section
//
test " " {
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================