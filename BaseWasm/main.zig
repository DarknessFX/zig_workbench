//!zig-autodoc-section: BaseWasm.Main
//! BaseWasm//main.zig :
//!  Template of HTML+Wasm program.
// Build using Zig 0.14.1

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
  print("Hello World!\n", .{});
  const res: u8 = fib(5);
  print("fib(5) = {d}\n", .{ res });
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn fib(n: u8) u8 {
  if ((n == 0) or (n == 1)) return 1;
  return fib(n - 1) + fib(n - 2);
}

fn print(comptime format: []const u8, args: anytype) void {
  std.io.getStdOut().writer().print(format, args) catch unreachable;
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================