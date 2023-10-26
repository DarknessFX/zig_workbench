const std = @import("std");

fn print(comptime fmt: []const u8, args: anytype) void {
  // debug.print output to StdErr ( is a shortcut to 
  // std.io.getStdErr() ), changed to a custom warper
  // to StdOut ignoring any error.
  std.io.getStdOut().writer().print(fmt, args) catch unreachable;
}

pub fn main() void {
  print("All your {s} are belong to us.\n", .{"codebase"});
}


//
// Tests section
//
test " Print" {
  print("\nTest print(): Hello {s}!", .{" world"});
  try std.testing.expect(true);
  print("\nNo error is good.\n", .{});
}