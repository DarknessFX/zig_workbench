const std = @import("std");
const builtin = @import("builtin");

inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }

// Custom build script
pub fn build(b: *std.Build) !void {
  // Common options
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  // Get current folder
  const cwd: []u8 = try std.process.getCwd(try b.allocator.alloc(u8, 256));

  // List of folders to build
  const example_folders = .{
    "audio",
    "core",
    "text",
  };

  // Loop each folder to build
  inline for (example_folders) |folder| {
    // Prepare to read all files on example folder 
    const cwd_example = try std.fs.path.join(b.allocator, &.{ cwd, folder });
    var dir = try std.fs.cwd().openDir(cwd_example, .{ .iterate = true });
    defer if (comptime builtin.zig_version.minor >= 13) dir.close();
    var iter = dir.iterate();

    // Loop each file and pass it to buildExample
    while (try iter.next()) |entry| {
      // Filter to only .Zig files
      if (std.mem.endsWith(u8, entry.name, ".zig")) {
        // Create relative_folder_path/file_name
        const source_path = try std.fs.path.join(b.allocator, &.{ folder, entry.name });
        // Call buildExample to build each .Zig to .Exe at ./bin/optimize/example_folder/file_name.exe
        buildExample(b, target, optimize, source_path, entry.name);
      }
    }

    // Copy resource files    
    var build_dir: []const u8 = undefined;
    switch (optimize) {
      .Debug =>  build_dir = "Debug",
      .ReleaseSafe =>  build_dir = "ReleaseSafe",
      .ReleaseFast =>  build_dir = "ReleaseFast",
      .ReleaseSmall =>  build_dir = "ReleaseSmall"
      //else  =>  b.exe_dir = "bin/Else",
    }

    // // Make bin/build/resources folders
    const destFolder = fmt("{s}\\{s}\\{s}\\{s}", .{  cwd, "bin", build_dir, "resources\\" } );
    std.fs.makeDirAbsolute( fmt("{s}\\{s}", .{ cwd, "bin" } )) catch { };
    std.fs.makeDirAbsolute( fmt("{s}\\{s}\\{s}", .{ cwd, "bin", build_dir } )) catch { };
    std.fs.makeDirAbsolute( destFolder ) catch { };
    
    const copyStep = b.addSystemCommand(&.{ "CMD", "/C", 
      b.fmt("COPY /Y {s} {s}>nul", .{
        fmt("{s}\\{s}\\resources\\*.*", .{ cwd, folder } ),
        destFolder,
      }),
    });
    b.getInstallStep().dependOn(&copyStep.step);
  }
}

fn buildExample(b: *std.Build, 
  target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, 
  sourcepath: []const u8, sourcename: []const u8) void {
  const projectname = "zig_raylib_examples";

  const exe = b.addExecutable(.{
    .name = sourcename,
    .root_source_file = b.path(sourcepath),
    .target = target,
    .optimize = optimize
  });

  // Add icon to .exe
  exe.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  // Configs necessary to includes and link library
  exe.addIncludePath( b.path("lib/raylib/include") );
  exe.addLibraryPath( b.path("lib/raylib") );
  exe.linkSystemLibrary("raylib");
  exe.linkSystemLibrary("winmm");
  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("opengl32");

  // Link libc
  exe.linkLibC();

  // Optimize options
  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);
}