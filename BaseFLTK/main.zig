//!zig-autodoc-section: BaseFLTK\\main.zig
//!  main.zig :
//!    Template for a program using FLTK (via cFLTK).
// Build using Zig 0.15.1

const std = @import("std");
const fl = @cImport({
  @cInclude("lib/CFLTK/include/cFl.h");
  @cInclude("lib/CFLTK/include/cFL_button.h");
  @cInclude("lib/CFLTK/include/cFL_image.h");
  @cInclude("lib/CFLTK/include/cFL_widget.h");
  @cInclude("lib/CFLTK/include/cFl_Window.h");
});

// Define the callback function in Zig, which will be callable from C
export fn cb(w: ?*fl.Fl_Widget, data: ?*anyopaque) callconv(.c) void {
  _ = data;
  fl.Fl_Widget_set_label(w, "Works!");
}

pub fn main() !void {
  //HideConsoleWindow();

  // Initialize FLTK
  _ = fl.Fl_init_all();
  _ = fl.Fl_register_images();
  _ = fl.Fl_lock();

  const w = fl.Fl_Window_new(100, 100, 1280, 720, "Zig+FLTK");
  const b = fl.Fl_Button_new(160, 210, 80, 40, "Click me");

  // End window composition
  fl.Fl_Window_end(w);
  fl.Fl_Window_show(w);
  fl.Fl_Button_set_callback(b, cb, null);

  _ = fl.Fl_run();
}

// ============================================================================
// Helpers
//
const win = std.os.windows;

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
) callconv(.winapi) win.DWORD;

pub extern "kernel32" fn FindWindowA(
  lpClassName: ?win.LPSTR,
  lpWindowName: ?win.LPSTR,
) callconv(.winapi) win.HWND;

pub const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: i32
) callconv(.winapi) win.BOOL;

pub const MB_OK = 0x00000000;
pub extern "user32" fn MessageBoxA(
  hWnd: ?win.HWND,
  lpText: [*:0]const u8,
  lpCaption: [*:0]const u8,
  uType: win.UINT
) callconv(.winapi) win.INT;

// ============================================================================
// Tests
//
test " " {
}