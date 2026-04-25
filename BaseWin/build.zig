//!zig-autodoc-section: BaseWin.Build
//! BaseWin\\build.zig :
//!   Build Template for a Windows program.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

pub fn build(b: *std.Build) void {
//#endregion ==================================================================
//#region MARK: INSTALL
//=============================================================================
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseWin";
  const mainfile = "main.zig";

  // const rootfile = "root.zig";
  // const mod = b.addModule(projectname, .{
  //   .root_source_file = b.path(rootfile),
  //   .target = target,
  // });

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
      // .imports = &.{
      //   .{ .name = "_Zig_16", .module = mod },
      // },
    }),
  });
  exe.root_module.addWin32ResourceFile(.{
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
  }
  b.installArtifact(exe);

//#endregion ==================================================================
//#region MARK: RUN
//=============================================================================
  const run_step = b.step("run", "Run the app");
  const run_cmd = b.addRunArtifact(exe);
  run_step.dependOn(&run_cmd.step);
  run_cmd.step.dependOn(b.getInstallStep());
  if (b.args) |args| {
    run_cmd.addArgs(args);
  }

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================
  // const mod_tests = b.addTest(.{
  //   .root_module = mod,
  // });
  // const run_mod_tests = b.addRunArtifact(mod_tests);
  const exe_tests = b.addTest(.{
    .root_module = exe.root_module,
  });
  const run_exe_tests = b.addRunArtifact(exe_tests);
  const test_step = b.step("test", "Run tests");
  // test_step.dependOn(&run_mod_tests.step);
  test_step.dependOn(&run_exe_tests.step);

}
//#endregion ==================================================================
//=============================================================================
