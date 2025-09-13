//!zig-autodoc-section: Base.Main
//! Base\\main.zig :
//!   Template for a console program.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

pub fn main() void {
  printLine("Base Template :");
  print("All your {s} are belong to us.\n", .{"codebase"});
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

/// Print to standard out.
fn print(comptime fmt: []const u8, args: anytype) void {
  // debug.print output to StdErr ( is a shortcut to
  // std.io.getStdErr() ), changed to a custom warper
  // to StdOut ignoring any error.

  var stdout_buffer: [1024]u8 = undefined;
  var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
  const stdout = &stdout_writer.interface;
  stdout.print(fmt, args) catch unreachable;
  stdout.flush() catch unreachable;
}

/// Print line directly when text don't need formating.
inline fn printLine(line: []const u8) void { print("{s}\n", .{ line }); }

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " print" {
  print("\nTest print(): Hello {s}!", .{" world"});
  try std.testing.expect(true);
}

test " printLine" {
  printLine("\nTest printLine(): No error is good.");
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================