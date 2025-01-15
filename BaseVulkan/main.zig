//!zig-autodoc-section: BaseVulkan
//!  Template for a Vulkan program using GLFW3.
// Build using Zig 0.13.0

// NOTE: Edit tasks.json and build.zig replacing hard coded paths to Vulkan SDK folder.

// ============================================================================
// Globals.
//
const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
const vk = @import("vulkan.zig");

// ============================================================================
// Main.
//
pub fn main() !void {

  vk.initWindow();
  try vk.initVulkan();
  try vk.loop();
  vk.deinit();
  
}

// Functions to switch to /Subsystem Windows instead of console.
// 
// pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
//   pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
//   _ = hInstance; _ = &hPrevInstance; _ = &pCmdLine; _ = nCmdShow;
// return 0;
// }

// // Fix for libc linking error.
// pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
//   pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
//   return wWinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
// }