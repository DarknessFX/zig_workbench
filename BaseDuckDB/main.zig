//!zig-autodoc-section: BaseDuckDB\\main.zig
//! main.zig :
//!	  Template for a DuckDB database program.
// Build using Zig 0.13.0

const std = @import("std");
const duk = @cImport({
  @cInclude("lib/DuckDB/duckdb.h");
});

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


pub fn main1() !u8 {
  //  HideConsoleWindow();
  // Initialize database
  var db: duk.duckdb_database = std.mem.zeroes(duk.duckdb_database);
  if (duk.duckdb_open(null, &db) != duk.DuckDBSuccess) return error.DuckDBOpenFailed;
  defer duk.duckdb_close(&db);

  // Create a connection
  var conn: duk.duckdb_connection = std.mem.zeroes(duk.duckdb_connection);
  if (duk.duckdb_connect(db, &conn) != duk.DuckDBSuccess) return error.DuckDBConnectFailed;
  defer duk.duckdb_disconnect(&conn);

  // Execute a query
  var result: duk.duckdb_result = std.mem.zeroes(duk.duckdb_result);
  const query = "SELECT 'Hello, DuckDB!' as greeting";
  if (duk.duckdb_query(conn, query, &result) != duk.DuckDBSuccess) return error.DuckDBQueryFailed;
  defer duk.duckdb_destroy_result(&result);

  // Print results
  var row_count: u64 = 0;
  //if (duk.duckdb_row_count(&result) != duk.DuckDBSuccess) return error.DuckDBRowCountFailed;
  row_count = duk.duckdb_row_count(&result);

  if (row_count > 0) {
    var column_count: u64 = 0;
    //if (duk.duckdb_column_count(&result) != duk.DuckDBSuccess) return error.DuckDBColumnCountFailed;
    column_count = duk.duckdb_column_count(&result);

    var values = std.ArrayList([*c]const u8).init(std.heap.page_allocator);
    defer values.deinit();

    for (0..column_count) |col| {
      const value: u64 = std.mem.zeroes(u64);
      _ = duk.duckdb_column_data(&result, value);
      if (duk.duckdb_value_varchar(&result, col, row_count) != duk.DuckDBSuccess) {
        return error.DuckDBValueFailed;
      }
      try values.append(value);
    }

    for (values.items) |value| {
      std.debug.print("{any}\t{any}\t{any}\t", .{result, result.internal_data, value});
    }
    std.debug.print("\n", .{});
  } else {
    std.debug.print("No results\n", .{});
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

// ============================================================================
// Tests
//
test " " {
}