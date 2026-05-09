//!zig-autodoc-section: BaseDuckDB\\main.zig
//! main.zig :
//!  Template for a DuckDB database program.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseDuckDB/lib/DuckDB/duckdb.h");
const duk = @cImport({
  @cInclude("lib/DuckDB/duckdb.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !u8 {
  var db: duk.duckdb_database = undefined;
  var con: duk.duckdb_connection = undefined;
  var result: duk.duckdb_result = undefined;

  if (duk.duckdb_open(null, &db) != duk.DuckDBSuccess) {
    std.debug.print("Failed to open database\n", .{});
    return error.DuckDBOpenFailed;
  }
  defer duk.duckdb_close(&db);

  if (duk.duckdb_connect(db, &con) != duk.DuckDBSuccess) {
    std.debug.print("Failed to open connection\n", .{});
    return error.DuckDBConnectFailed;
  }
  defer duk.duckdb_disconnect(&con);

  if (duk.duckdb_query(con, "CREATE TABLE integers(i INTEGER, j INTEGER);", null) != duk.DuckDBSuccess) {
    std.debug.print("Failed to query database\n", .{});
    return error.DuckDBQueryFailed;
  }

  if (duk.duckdb_query(con, "INSERT INTO integers VALUES (3, 4), (5, 6), (7, NULL);", null) != duk.DuckDBSuccess) {
    std.debug.print("Failed to query database\n", .{});
    return error.DuckDBQueryFailed;
  }

  if (duk.duckdb_query(con, "SELECT * FROM integers", &result) != duk.DuckDBSuccess) {
    std.debug.print("Failed to query database\n", .{});
    return error.DuckDBQueryFailed;
  }
  defer duk.duckdb_destroy_result(&result);

  // print the names of the result
  const row_count: duk.idx_t = duk.duckdb_row_count(&result);
  const column_count: duk.idx_t = duk.duckdb_column_count(&result);
  for (0..column_count) |i| {
    const name = duk.duckdb_column_name(&result, i);
    std.debug.print("{s} \t ", .{name});
  }
  std.debug.print("\n", .{});

  // print the data of the result
  for (0..row_count) |row_idx| {
    for (0..column_count) |col_idx| {
      const val: ?[*:0]u8 = duk.duckdb_value_varchar(&result, col_idx, row_idx);
      if (val == null) {
        std.debug.print("null ", .{});
      } else {
        std.debug.print("{s} \t ", .{val.?});
      }
      duk.duckdb_free(val);
    }
    std.debug.print("\n", .{});
  }

  return 0;
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
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


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================