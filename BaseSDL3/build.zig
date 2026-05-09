//!zig-autodoc-section: BaseSDL3\\Build
//! build.zig :
//!  Template using SDL3 framework.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseSDL3";
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
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.root_module.addIncludePath( b.path("lib") );
  exe.root_module.addIncludePath( b.path("lib/SDL3") );

  const use_shared = b.option(bool, "shared", "Use shared library linking") orelse true;
  if (use_shared) {
    exe.root_module.addLibraryPath( b.path("lib/SDL3/shared") );
    b.installBinFile("lib/SDL3/shared/SDL3.dll", "SDL3.dll");
    exe.root_module.linkSystemLibrary("SDL3", .{});
  } else {
    exe.root_module.addLibraryPath( b.path("lib/SDL3/static") );
    exe.root_module.linkSystemLibrary("SDL3", .{});
    exe.root_module.linkSystemLibrary("user32", .{});
    exe.root_module.linkSystemLibrary("ole32", .{});
    exe.root_module.linkSystemLibrary("gdi32", .{});
    exe.root_module.linkSystemLibrary("imm32", .{});
    exe.root_module.linkSystemLibrary("winmm", .{});
    exe.root_module.linkSystemLibrary("setupapi", .{});
    exe.root_module.linkSystemLibrary("version", .{});
    exe.root_module.linkSystemLibrary("oleaut32", .{});
  }

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