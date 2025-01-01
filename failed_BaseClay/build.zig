const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseClay";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize
  });
  exe.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"} // UTF-8 codepage
  });

  // Clay + RayLib
  exe.addIncludePath( b.path("lib/clay") );
  exe.addIncludePath( b.path("lib/raylib") );
  exe.addLibraryPath( b.path("lib/raylib/") );
  exe.linkSystemLibrary("raylib");

  exe.addCSourceFile(.{
    .file = b.path("lib/clay/clay.c"), 
    .flags = &.{ }
  });

  // Assets
  b.installBinFile("asset/texture.png", "asset/texture.png");
  b.installBinFile("asset/Roboto-Regular.ttf", "asset/Roboto-Regular.ttf");

  b.installBinFile("lib/raylib/raylib.dll", "raylib.dll");

  exe.linkLibC();


  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);

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
    .root_source_file = b.path(rootfile),
    .target = target,
   .optimize = optimize,
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}