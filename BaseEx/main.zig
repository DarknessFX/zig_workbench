//!zig-autodoc-section: BaseEx.Main
//! BaseEx\\main.zig :
//!   Template for a console program that hide the console window.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const Io = std.Io;
var appinit: std.process.Init = undefined;
const win = std.os.windows;
const appTitle = "BaseEx";

const print = std.debug.print;
/// Print line directly when text don't need formating.
inline fn printLine(line: []const u8) void { print("{s}\n", .{ line }); }

const log = std.log.info;
/// Log line directly when text don't need formating.
inline fn logLine(line: []const u8) void { log("{s}\n", .{ line }); }

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main(init: std.process.Init) !void {
  appinit = init;

  HideConsoleWindow();
  _ = MessageBoxA(null, "Console window is hide.", appTitle, MB_OK);
}

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
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


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================
test " " {
}

//#endregion ==================================================================
//=============================================================================
