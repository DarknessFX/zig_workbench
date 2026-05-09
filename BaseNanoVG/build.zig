//!zig-autodoc-section: BaseNanoVG.Build
//! BaseNanoVG//build.zig :
//!  Build Template using NanoVG and GLFW3.
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

  const projectname = "BaseNanoVG";
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
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.root_module.addIncludePath( b.path(".") );
  exe.root_module.addIncludePath( b.path("lib/glfw/include") );
  exe.root_module.addIncludePath( b.path("lib/glad") );
  exe.root_module.addIncludePath( b.path("lib/nanovg") );

  const use_shared = b.option(bool, "shared", "Use shared library linking") orelse false;
  if (use_shared) {
    exe.root_module.addLibraryPath( b.path("lib/glfw/shared") );
    exe.root_module.linkSystemLibrary("glfw3dll", .{});
    b.installBinFile("lib/glfw/shared/glfw3.dll", "glfw3.dll");
  } else {
    exe.root_module.addLibraryPath( b.path("lib/glfw/static") );
    exe.root_module.linkSystemLibrary("glfw3", .{});
    exe.root_module.linkSystemLibrary("gdi32", .{});
  }
  exe.root_module.linkSystemLibrary("opengl32", .{});

  const c_srcs = .{
    "lib/glad/src/glad.c",
    "lib/nanovg/nanovg.c",
    "lib/nanovg/nanovg_gl.c",
  };
  inline for (c_srcs) |c_cpp| {
    exe.root_module.addCSourceFile(.{
      .file = b.path(c_cpp), 
      .flags = &.{ }
    });
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