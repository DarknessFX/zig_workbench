//!zig-autodoc-section: BaseWebview\\main.zig
//! main.zig :
//!	  Template for Webview program.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseWebview/lib/webview/include/webview.h");
const web = @cImport({
  @cInclude("lib/webview/include/webview.h");
});
const c = @cImport({
  @cInclude("stdlib.h"); // just strtol used by the original example
});

const context_t = struct{
  window: web.webview_t,
  count: i32,
};
pub fn main() u8 {
  HideConsoleWindow();
  const window: web.webview_t = web.webview_create(0, null);
  var context: context_t = .{ .window = window, .count = 0 };
  _ = web.webview_set_title(window, "BaseWebview");
  _ = web.webview_set_size(window, 480, 320, web.WEBVIEW_HINT_NONE);

  // A binding that counts up or down and immediately returns the new value.
  _ = web.webview_bind(window, "count", count, &context);

  _ = web.webview_set_html(window, html);
  _ = web.webview_run(window);

  _ = web.webview_destroy(window);
  return 0;
}

pub fn count(id: [*c]const u8, req: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
  if (arg == null) return;
  const context: *context_t = @ptrCast(@alignCast(arg.?));
  // Imagine that params->req is properly parsed or use your own JSON parser.
  const direction = c.strtol(req + 1, null, 10);
  var result: [10]u8 = std.mem.zeroes([10]u8);
  result[0] = 0; // Null terminate
  _ = std.fmt.bufPrint(&result, "{d}", .{context.count + direction}) catch unreachable;
  context.count += direction; // Update count after formatting
  _ = web.webview_return(context.window, id, 0, &result[0]);
}

const html: [*c]const u8 = 
\\<div>
\\  <button id="increment">+</button>
\\  <button id="decrement">−</button>
\\  <span>Counter: <span id="counterResult">0</span></span>
\\</div>
\\<hr />
\\<script type="module">
\\  const getElements = ids => Object.assign({}, ...ids.map(
\\    id => ({ [id]: document.getElementById(id) })));
\\  const ui = getElements([
\\    "increment", "decrement", "counterResult"
\\  ]);
\\  ui.increment.addEventListener("click", async () => {
\\    ui.counterResult.textContent = await window.count(1);
\\  });
\\  ui.decrement.addEventListener("click", async () => {
\\    ui.counterResult.textContent = await window.count(-1);
\\  });
\\</script>
;

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

// ============================================================================
// Tests
//
test " " {
}