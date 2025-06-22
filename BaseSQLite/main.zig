//!zig-autodoc-section: BaseEx\\main.zig
//! main.zig :
//!  Template for a console program that hide the console window.
// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseSQLite/lib/sqlite/sqlite3.h");
const sqlite = @cImport({
  @cInclude("sqlite3.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() u8 {
  //HideConsoleWindow();
  var db: ?*sqlite.sqlite3 = null;
  var err_msg: [*c]u8 = undefined;

  if (sqlite.sqlite3_open("test.db", &db) != sqlite.SQLITE_OK) {
    std.debug.print("Can't open database: {s}\n", .{sqlite.sqlite3_errmsg(db)});
    return 1; // SQLiteOpenError
  }
  defer _ = sqlite.sqlite3_close(db);

  const sql = "CREATE TABLE IF NOT EXISTS Stuff(ToDo TEXT, Priority INTEGER);";

  if (sqlite.sqlite3_exec(db, sql, null, null, &err_msg) != sqlite.SQLITE_OK) {
    std.debug.print("SQL error: {s}\n", .{err_msg});
    sqlite.sqlite3_free(@ptrCast(err_msg));
  return 2; // SQLiteExecError
  }

  std.debug.print("Table created successfully\n", .{});

  return 0;  
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
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


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================