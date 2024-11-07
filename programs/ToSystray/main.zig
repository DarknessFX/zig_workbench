//!zig-autodoc-section: ToSystray
//! ToSystray.exe :
//!   Utility tool that run other application and hide app window into systray.
//!   Helpful to keep applications in the Windows System Tray instead of 
//!   occupying space in the Taskbar.

// Build using Zig 0.12.0-dev.3160+aa7d16aba
// ============================================================================
// Globals.
//
const std = @import("std");
const win = @import("winapi.zig");
const assert = std.debug.assert;

const ToolName: []const u8 = "ToSystray";
const TApp = struct {
  Path: []const u8 = "",
  Title: []const u8 = "",
  Process: win.HANDLE = undefined,
  Thread: win.HANDLE = undefined,
  Window: win.HANDLE = undefined,
  isMinimized: bool = false,
  isClosed: bool = false,
  dwProcess: win.DWORD = undefined,
  dwThread: win.DWORD = undefined,
  SelfPath: []const u8 = "",
};
var App: TApp = .{};
const wnd = win.wnd;

// ============================================================================
// Main core and app flow.
//

pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
  _ = &hInstance; _ = &hPrevInstance; _ = &pCmdLine; _ = &nCmdShow;

  App.Title = ToolName;
  win.HideConsoleWindow();

  LoadArgs()
    orelse return PopupUsage();

  wnd.hInstance = hInstance;

  LaunchApp()
    orelse return LaunchAppFailed();
  defer CloseAppHandles();

  win.Create()
    orelse return 1;
  defer win.Destroy();

  while (!wnd.exit) {
    win.ProcessMsg();
  }

  return 0;
}

fn LaunchApp() ?void {
  wnd.path = toStringA(App.Path);
  wnd.title = toStringA(App.Title);
  if (win.ExtractIconA(wnd.hInstance, toStringA(App.SelfPath), 0)) |icontmp|
    wnd.icon = icontmp;

  const result = win.CreateProcess(App.Path)
    orelse return null;

  App.Process = result.hProcess;
  App.Thread = result.hThread;
  App.dwProcess = result.dwProcessId;
  App.dwThread = result.dwThreadId;
}

fn LaunchAppFailed() win.INT {
  return 1;
}

fn CloseAppHandles() void {
  win.CloseAppHandles(App.Process, App.Thread);
}

fn LoadArgs() ?void {
  const buf_alloc = std.heap.page_allocator;
  const buffer = buf_alloc.create([4096]u16) catch unreachable;
  defer std.heap.page_allocator.destroy(buffer);
  var args = std.process.ArgIterator.initWithAllocator(buf_alloc) catch unreachable;
  defer args.deinit();

  if (args.next()) |arg0| 
    App.SelfPath = toRetCopy(arg0);
//  if (!args.skip()) return null;
  if (args.next()) |arg1| 
    App.Path = toRetCopy(arg1);
  if (args.next()) |arg2| 
    App.Title = toRetCopy(arg2);

  if (std.mem.eql(u8, App.Path, "")) return null;
}

// ============================================================================
// Helpers
//
inline fn isNull(any: anytype) bool { return any == null; }
inline fn toRetCopy(any: anytype) @TypeOf(any) { 
  const any_cpy = std.heap.page_allocator.dupe(
    @typeInfo(@TypeOf(any)).Pointer.child,
    any) catch unreachable;
  return @as(@TypeOf(any), @ptrCast(any_cpy));
}
inline fn toPtr(handle: win.HANDLE) usize { return @as(usize, @intFromPtr(handle)); }
inline fn toStringA(string: []const u8) [*:0]const u8 { return @as([*:0]const u8, @ptrCast(string)); }
fn PopupUsage() win.INT {
  return win.MessageBoxA(null,
    "Usage:\n" ++
    "  ToSystray.exe \"path_to_exe\" (optional)\"WindowTitle\" \n" ++
    "Sample:\n" ++
    "  ToSystray.exe \"C:\\Windows\\System32\\Notepad.exe\" \"Notepad\" ",
    "Error: No arguments",
    win.MB_OK | win.MB_ICONERROR
  );
}

// ============================================================================
// Tests 
//
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "LoadArgs" {
  try expect(LoadArgs() == null);
  std.debug.print("\nEmpty args => display PopupUsage().\n", .{  });
}

test "LaunchApp" {
  App.Path = "Notepad.exe";
  App.Title = "Notepad";
  std.debug.print(
    "\nLoadArgs() filled with:\nApp.Title: {s}\nApp.Path: {s}\nTest LaunchApp();\n", 
    .{ App.Title, App.Path });

  try expect(LaunchApp() != null);

  std.debug.print("App\nProcess: {d}\nThread: {d}\ndwProcess: {d}\ndwThread: {d}\n", .{ 
    toPtr(App.Process), toPtr(App.Thread), App.dwProcess, App.dwThread });
}