//!zig-autodoc-section: BaseFLTK\\main.zig
//!  main.zig :
//!    Build Template for a program using FLTK (via cFLTK).
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

  const projectname = "BaseFLTK";
  const mainfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libcpp = true,
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
    //else  =>  b.exe_dir = "bin/Else",
  }

  exe.root_module.addIncludePath( b.path(".") );
  exe.root_module.addIncludePath( b.path("lib") );
  exe.root_module.addIncludePath( b.path("lib/GL") );
  exe.root_module.addIncludePath( b.path("lib/CFLTK/include") );

  exe.root_module.addLibraryPath( b.path("lib/CFLTK") );
  exe.root_module.addLibraryPath( b.path("lib/FLTK") );

  exe.root_module.linkSystemLibrary("ws2_32", .{});
  exe.root_module.linkSystemLibrary("comctl32", .{});
  exe.root_module.linkSystemLibrary("gdi32", .{});
  exe.root_module.linkSystemLibrary("gdiplus", .{});
  exe.root_module.linkSystemLibrary("oleaut32", .{});
  exe.root_module.linkSystemLibrary("ole32", .{});
  exe.root_module.linkSystemLibrary("uuid", .{});
  exe.root_module.linkSystemLibrary("shell32", .{});
  exe.root_module.linkSystemLibrary("advapi32", .{});
  exe.root_module.linkSystemLibrary("comdlg32", .{});
  exe.root_module.linkSystemLibrary("winspool", .{});
  exe.root_module.linkSystemLibrary("user32", .{});
  exe.root_module.linkSystemLibrary("kernel32", .{});
  exe.root_module.linkSystemLibrary("odbc32", .{});
  exe.root_module.linkSystemLibrary("cfltk2", .{});
  exe.root_module.linkSystemLibrary("fltk", .{});
  exe.root_module.linkSystemLibrary("fltk_images", .{});
  exe.root_module.linkSystemLibrary("fltk_jpeg", .{});
  exe.root_module.linkSystemLibrary("fltk_png", .{});
  exe.root_module.linkSystemLibrary("fltk_z", .{});

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
      .link_libcpp = true,
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
//#endregion ==================================================================
//=============================================================================