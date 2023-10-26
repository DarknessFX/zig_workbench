const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const exe = b.addExecutable(.{
    .name = "BaseWin",
    .root_source_file = .{ .path = "main.zig" },
    .target = target,
    .optimize = optimize,
  });
  exe.addWin32ResourceFile(.{
    .file = .{ .path = "BaseWin.rc" },
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });
  exe.linkLibC();

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall",
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);

  exe.addIncludePath( .{ .path = "lib/SDL2/include" }  );
  exe.addLibraryPath( .{ .path = "lib/SDL2/" } );
  exe.linkSystemLibrary("SDL2");
  b.installBinFile("lib/SDL2/SDL2.dll", "SDL2.dll");
  exe.linkLibC();

  //Run
  const run_cmd = b.addRunArtifact(exe);
  run_cmd.step.dependOn(b.getInstallStep());
  if (b.args) |args| {
    run_cmd.addArgs(args);
  }
  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  //Tests
  const unit_tests = b.addTest(.{
    .root_source_file = .{ .path = "main.zig" },
    .target = target,
   .optimize = optimize,
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
