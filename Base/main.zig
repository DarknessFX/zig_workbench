//!zig-autodoc-section: Base.Main
//! Base\\main.zig :
//!   Template for a console program.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const Io = std.Io;
var appinit: std.process.Init = undefined;

const print = std.debug.print;
/// Print line directly when text don't need formating.
inline fn printLine(line: []const u8) void { print("{s}\n", .{ line }); }

const log = std.log.info;
/// Log line directly when text don't need formating.
inline fn logLine(line: []const u8) void { log("{s}\n", .{ line }); }

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main(init: std.process.Init) !void {
  appinit = init;

  // JuicyMain
  try checkMemory();
  try checkStdOut();
  try printArgs();
  try iterateArgs();
  try iterateArgs2();
  printEnvArgs();
  searchEnvArgs();
  printEnvArgsCount();

}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn checkMemory() !void {
  const ptr = try appinit.gpa.create(i32);
  defer appinit.gpa.destroy(ptr);

  const ptr2 = try appinit.arena.allocator().create(i32);
  defer appinit.arena.allocator().destroy(ptr2);
}

fn checkStdOut() !void {
  try Io.File.stdout().writeStreamingAll(appinit.io, "Base Template: - Hello, world!\n");
  printLine("(print) Testing the features of Zig's new JuicyMain.");
  logLine("(log) Testing the features of Zig's new JuicyMain.");
}

fn printArgs() !void {
  const args = try appinit.minimal.args.toSlice(appinit.arena.allocator());
  for (args, 0..) |arg, i| {
    log("arg[{d}] = {s}", .{ i, arg });
  }
}

fn iterateArgs() !void {
  var argsIt = try appinit.minimal.args.iterateAllocator(appinit.gpa);
  defer argsIt.deinit();
  while (argsIt.next()) |arg| {
    log("arg: {s}", .{arg});
  }
}

fn iterateArgs2() !void {
  var argsIt = try appinit.minimal.args.iterateAllocator(appinit.arena.allocator());
  defer argsIt.deinit();
  while (argsIt.next()) |arg| {
    log("arg: {s}", .{arg});
  }
}

fn printEnvArgs() void {
  for (appinit.environ_map.keys(), appinit.environ_map.values()) |key, value| {
    log("env: {s}={s}", .{ key, value });
  }
}

fn printEnvArgsCount() void {
  log("{d} env vars", .{appinit.environ_map.count()});
}

fn searchEnvArgs() void {
  log("contains HOME: {any}", .{appinit.minimal.environ.contains(appinit.gpa, "HOME")});
  log("contains HOME (unempty): {any}", .{appinit.minimal.environ.containsUnempty(appinit.gpa, "HOME")});
  if (appinit.minimal.environ.containsConstant("APPDATA")) {
    log("contains APPDATA: {any}", .{ true });
    log("contains APPDATA (value): {?s}", .{ appinit.environ_map.get("APPDATA") });
  }
}

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

test " log" {
  log("\nTest log(): Hello {s}!", .{" world"});
  print("\nTest log(): Hello {s}!", .{" world"});
  try std.testing.expect(true);
}

test " logLine" {
  logLine("\nTest logLine(): No error is good.");
  printLine("\nTest logLine(): No error is good.");
  try std.testing.expect(true);
}

test " checkMemory" {
  var _arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
  defer _arena.deinit();

  appinit.gpa = std.testing.allocator;
  appinit.arena = &_arena;
  try checkMemory();
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================
