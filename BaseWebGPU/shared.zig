//!zig-autodoc-section: BaseWebGPU\\shared.zig
//! shared.zig :
//!  Library of functions that are accessible and 
//!  shared by Web + Wasm and Platforms binaries.
// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const Title: []const u8 = "Shared";

// BREAKING WINDOWS BUILD? 
// Link to javascript console.log
pub extern fn Print(ptr: [*]const u8, len: usize) callconv(.C) void;
pub extern fn printFlush() void;
fn write(_: void, bytes: []const u8) error{}!usize {
  Print(bytes.ptr, bytes.len);
  return bytes.len;
}
pub inline fn log(comptime format: []const u8, args: anytype) void {
  const consolelog = std.io.Writer(void, error{}, write){ .context = {} };
  consolelog.print(format, args) catch return;
  printFlush();
}
pub inline fn log_(text: []const u8) void { log("{s}\n", .{ text }); }
pub inline fn lobj(object: anytype) void { log("{any}\n", .{ object }); }
pub inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }

// Global events
pub export fn Init() callconv(.C) void { log("{s}: Initialized", .{ Title }); }
pub export fn Update() callconv(.C) void { log("{s}: Updated", .{ Title }); }

// Sample export functions
pub export fn add(a: i32, b: i32) i32 {
  log("{s}: Add result {d} .", .{ Title, a + b });
  return a + b;
}

pub export fn sub(a: i32, b: i32) i32 {
  log("{s}: Sub result {d}.", .{ Title, a - b });
  return a - b;
}

//#endregion ==================================================================
//=============================================================================