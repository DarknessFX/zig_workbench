//!zig-autodoc-section: BaseWasm.Main
//! BaseWasm//main.zig :
//!  Template of HTML+Wasm program.
// Build using Zig 0.15.1

// Credits : Marco Selvatici
// https://marcoselvatici.github.io/WASM_tutorial/#your_first_WASM_WebApp

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !void {
  log("Hello World!\n", .{});
  const res: u8 = fib(5);
  log("fib(5) = {d}\n", .{ res });
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn fib(n: u8) u8 {
  if ((n == 0) or (n == 1)) return 1;
  return fib(n - 1) + fib(n - 2);
}

// Link to javascript console.log
pub extern fn Print(ptr: [*]const u8, len: usize) callconv(.c) void;
pub extern fn printFlush() void;

fn write(_: void, bytes: []const u8) error{}!usize {
  Print(bytes.ptr, bytes.len);
  return bytes.len;
}
pub inline fn log(comptime format: []const u8, args: anytype) void {
  //const consolelog = std.io.Writer(void, error{}, write){ .context = {} };
  //consolelog.print(format, args) catch return;
  var buf: [1024]u8 = undefined;
  const len = std.fmt.bufPrint(&buf, format, args) catch return;
  Print(@as([*]const u8, @ptrCast(&buf[0])), len.len);
  printFlush();
}
// Global events
const Title: []const u8 = "BaseWasm";
pub export fn Init() callconv(.c) void { log("{s}: Initialized", .{ Title }); }
pub export fn Update() callconv(.c) void { log("{s}: Updated", .{ Title }); }

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================