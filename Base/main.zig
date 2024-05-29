//!zig-autodoc-section: Base.Main
//! Base\\main.zig :
//!   Template for a console program.

const std = @import("std");

/// Main function
pub fn main() void {
  print("All your {s} are belong to us.\n", .{"codebase"});
}

// ============================================================================
// Helpers
//

/// Print to standard out.
fn print(comptime fmt: []const u8, args: anytype) void {
  // debug.print output to StdErr ( is a shortcut to
  // std.io.getStdErr() ), changed to a custom warper
  // to StdOut ignoring any error.
  std.io.getStdOut().writer().print(fmt, args) catch unreachable;
}

/// Print line directly when text don't need formating.
fn printLine(line: []const u8) void {
  print("{s}\n", .{ line });
}


// ============================================================================
// Tests
//
test " Print" {
  print("\nTest print(): Hello {s}!", .{" world"});
  try std.testing.expect(true);
  print("\nNo error is good.\n", .{});
}
