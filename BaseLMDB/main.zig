//!zig-autodoc-section: BaseEx\\main.zig
//! main.zig :
//!	  Template for a console program that hide the console window.
// Build using Zig 0.13.0

const std = @import("std");
const lmdb = @cImport({
    @cInclude("lib/LMDB/lmdb.h");
});

pub fn main() !void {
  //HideConsoleWindow();

  // Create LMDB environment
  var env: ?*lmdb.MDB_env = null;
  var rc = lmdb.mdb_env_create(&env);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to create environment: {}\n", .{rc});
    return error.LMDBEnvCreateError;
  }
  defer lmdb.mdb_env_close(env);

  // Set environment parameters
  rc = lmdb.mdb_env_set_mapsize(env, 10485760); // 10 MiB
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to set mapsize: {}\n", .{rc});
    return error.LMDBSetMapSizeError;
  }

  // Open the environment
  rc = lmdb.mdb_env_open(env, "./", 0, 664);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to open environment: {}\n", .{rc});
    return error.LMDBEnvOpenError;
  }

  // Start a transaction
  var txn: ?*lmdb.MDB_txn = null;
  rc = lmdb.mdb_txn_begin(env, null, 0, &txn);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to start transaction: {}\n", .{rc});
    return error.LMDBTxnBeginError;
  }
  defer lmdb.mdb_txn_abort(txn);

  // Open database
  var dbi: lmdb.MDB_dbi = undefined;
  rc = lmdb.mdb_dbi_open(txn, null, 0, &dbi);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to open database: {}\n", .{rc});
    return error.LMDBDbiOpenError;
  }
  defer lmdb.mdb_dbi_close(env, dbi);

  // Prepare data
  const key = "testkey";
  const value = "testvalue";

  // Store a key-value pair
  var key_val = lmdb.MDB_val{.mv_size = key.len, .mv_data = @constCast(key.ptr)};
  var data_val = lmdb.MDB_val{.mv_size = value.len, .mv_data = @constCast(value.ptr)};

  rc = lmdb.mdb_put(txn, dbi, &key_val, &data_val, 0);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to store data: {}\n", .{rc});
    return error.LMDBPutError;
  }

  // Commit transaction
  rc = lmdb.mdb_txn_commit(txn);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to commit transaction: {}\n", .{rc});
    return error.LMDBTxnCommitError;
  }
  txn = null; // txn is now invalid, set to null

  // Start another transaction to retrieve the data
  rc = lmdb.mdb_txn_begin(env, null, lmdb.MDB_RDONLY, &txn);
  if (rc != lmdb.MDB_SUCCESS) {
    std.debug.print("Failed to start read transaction: {}\n", .{rc});
    return error.LMDBTxnBeginError;
  }
 
  // Retrieve data
  var get_val: lmdb.MDB_val = undefined;
  rc = lmdb.mdb_get(txn, dbi, &key_val, &get_val);
  if (rc == lmdb.MDB_SUCCESS) {
    const retrieved_value = @as([*]u8, @ptrCast(get_val.mv_data))[0..get_val.mv_size];
    std.debug.print("Retrieved value: {s}\n", .{retrieved_value});
  } else {
    std.debug.print("Failed to retrieve data: {}\n", .{rc});
    return error.LMDBGetError;
  }

  std.debug.print("LMDB operations completed.\n", .{});
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