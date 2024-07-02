const std = @import("std");
const mem = std.mem;
const time = std.time;
const math = std.math;
const win = std.os.windows;
const W = std.unicode.utf8ToUtf16LeWithNull;
var startup: win.STARTUPINFOW = undefined;
var prcinfo: win.PROCESS_INFORMATION = undefined;

const dos_color = @import("lib/dos_color.zig");
const printColor = dos_color.printColor;
const printColorCmd = dos_color.printColorCmd;
const printColorReset = dos_color.printColorReset;

const ztime1 = "zTime";
const ztime2 = "ztime";
const ztime3 = "ZTIME";

fn print(comptime fmt: []const u8, args: anytype) void {
  std.io.getStdOut().writer().print(fmt, args) catch return;
}

const Perf = struct {
  instant: time.Instant,
  tick: struct { start: u64, since: u64 },
  nano: struct { start: u64, since: u64 },
  secs: struct { start: f64, since: f64 },

  const Self = @This();
  fn init() Perf {
    return Perf{
      .tick = .{ 
        .start = std.os.windows.QueryPerformanceCounter(), 
        .since = 0 },
      .instant = time.Instant.now() catch unreachable,
      .nano = .{ .start = 0, .since = 0 },
      .secs = .{ .start = 0.0, .since = 0.0 },
    };
  }

  fn since(self: *Perf) void {
    self.tick.since = std.os.windows.QueryPerformanceCounter() -% self.tick.start;
    self.nano.since = time.Instant.since(time.Instant.now() catch return, self.instant);
    self.secs.since = @as(f64, @floatFromInt(self.nano.since)) / time.ns_per_s;
  }
};

pub fn main() !void {
  var perf = Perf.init();
  
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const allocator = gpa.allocator();
  const args = try std.process.argsAlloc(allocator);
  defer std.process.argsFree(allocator, args);

  if (args.len > 1) {
    var i:u8 = 0;
    const cmd_line = std.os.windows.kernel32.GetCommandLineA();
    var cmd_linelen:u8 = 0;
    while (cmd_line[i] != 0) : (i += 1) { cmd_linelen = i; }
    cmd_linelen += 1;

    i = 0;
    var argsz: []u8 = cmd_line[6..cmd_linelen];
    if ((cmd_line[0..5] != ztime1) and 
        (cmd_line[0..5] != ztime2) and 
        (cmd_line[0..5] != ztime3)) {
      while (cmd_line[i] != 0) : (i += 1) {
        if (cmd_line[i] == 46) { //== "."
          if (cmd_line[i+1] != 101) continue;
          if (cmd_line[i+2] != 120) continue;
          if (cmd_line[i+3] != 101) continue;

          argsz = cmd_line[i+4..cmd_linelen];
          break;
        }
      }
    }

    var alloc = std.heap.page_allocator;
    const appname = "C:\\WINDOWS\\SYSTEM32\\CMD.EXE";
    const cmdbase = "/C ";
    const command: []const u8 = try std.fmt.allocPrint(alloc, "{s} {s}", .{ cmdbase, argsz});
    const dwflags: win.DWORD = 0;
    const appNameUnicode = W(alloc, appname) catch undefined;
    const commandUnicode = W(alloc, command) catch undefined;
    defer {
      alloc.free(command);
      alloc.free(appNameUnicode);
      alloc.free(commandUnicode);
    }

    try win.CreateProcessW(appNameUnicode, commandUnicode, null, null, 0, dwflags, null, null, &startup, &prcinfo);
    defer {
        win.CloseHandle(prcinfo.hProcess);
        win.CloseHandle(prcinfo.hThread);
    }
    try win.WaitForSingleObject(prcinfo.hProcess, win.INFINITE);

  } else {
    printColor(.{ .foreground = .RED, .text = .BOLD } );
    print("Warning : ", .{});
    printColorReset();
    print("No arguments.\n", .{});
    printColor(.{ .foreground = .GREEN } );
    print("Usage   : ", .{});
    printColorReset();
    print("zTime another.exe -arg1 -arg2\n", .{});
  }

  perf.since();
  print("\n", .{});
  printColor(.{ .foreground = .WHITE, .background = .BLACK_LIGHT } );
  print("Seconds :", .{});
  printColor(.{ .foreground = .WHITE, .text = .BOLD } );
  print("  {d:.5}", .{ perf.secs.since });
  printColorReset(); print("\n", .{});
  printColor(.{ .foreground = .WHITE, .background = .BLACK_LIGHT } );
  print("Nano    :", .{});
  printColor(.{ .foreground = .WHITE, .text = .BOLD } );
  print("  {d}", .{ perf.nano.since });
  printColorReset(); print("\n", .{});
  printColor(.{ .foreground = .WHITE, .background = .BLACK_LIGHT } );
  print("Ticks   :", .{});
  printColor(.{ .foreground = .WHITE, .text = .BOLD } );
  print("  {d}", .{ perf.tick.since });
  printColorReset();
  print("\n", .{});
}
