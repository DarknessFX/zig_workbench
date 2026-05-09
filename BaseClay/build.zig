//!zig-autodoc-section: BaseClay
//!  Build Template using Clay UI and RayLib.
//!  Credits:
//!    Clay from nicbarker - https://github.com/nicbarker/clay
//!    Clay-zig binding from johan0A - https://github.com/johan0A/clay-zig-bindings
// Build using Zig 0.16.0
const std = @import("std");

pub fn build(b: *std.Build) void {
//#endregion ==================================================================
//#region MARK: INSTALL
//=============================================================================
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseClay";
  const mainfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
    }),
  });
  exe.root_module.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"} // UTF-8 codepage
  });

  // Clay + RayLib
  exe.root_module.addIncludePath( b.path("lib/zClay") );
  exe.root_module.addIncludePath( b.path("lib/raylib") );
  exe.root_module.addLibraryPath( b.path("lib/raylib/") );
  exe.root_module.linkSystemLibrary("raylib", .{});

  exe.root_module.addCSourceFile(.{
    .file = b.path("lib/zClay/clay.c"), 
    .flags = &.{ }
  });

  // Assets
  b.installBinFile("asset/profile-picture.png", "asset/profile-picture.png");
  b.installBinFile("asset/Roboto-Regular.ttf", "asset/Roboto-Regular.ttf");

  b.installBinFile("lib/raylib/raylib.dll", "raylib.dll");

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);

//#endregion ==================================================================
//#region MARK: RUN
//=============================================================================
  const run_cmd = b.addRunArtifact(exe);
  run_cmd.step.dependOn(b.getInstallStep());
  if (b.args) |args| {
    run_cmd.addArgs(args);
  }
  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================
  const unit_tests = b.addTest(.{
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,      
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
//#endregion ==================================================================
//=============================================================================