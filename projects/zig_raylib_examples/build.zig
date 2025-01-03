const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const cwd_buf: []u8 = try std.heap.page_allocator.alloc(u8, 256);
  const cwd: []u8 = try std.process.getCwd(cwd_buf);
  const example_folders = .{
    "core",
  };
  inline for (example_folders) |folder| {
    const cwd_example = try std.fs.path.join(b.allocator, &.{ cwd, folder });
    var dir = try std.fs.cwd().openDir(cwd_example, .{ .iterate = true });
    defer if (comptime builtin.zig_version.minor >= 13) dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
      if (std.mem.endsWith(u8, entry.name, ".zig")) {
        const source_path = try std.fs.path.join(b.allocator, &.{ folder, entry.name });
        buildExample(b, target, optimize, source_path, entry.name);
      }
    }
  }
}

pub fn buildExample(b: *std.Build, 
  target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, 
  sourcepath: []const u8, sourcename: []const u8) void {
  const projectname = "zig_raylib_examples";
  //const sourcefile = "main.zig";

  const exe = b.addExecutable(.{
    .name = sourcename,
    .root_source_file = b.path(sourcepath),
    .target = target,
    .optimize = optimize
  });
  exe.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });
  exe.linkLibC();

  exe.addIncludePath( b.path("lib/raylib/include") );
  exe.addLibraryPath( b.path("lib/raylib") );
  exe.linkSystemLibrary("raylib");
  exe.linkSystemLibrary("winmm");
  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("opengl32");

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);
}
