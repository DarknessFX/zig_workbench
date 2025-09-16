const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseFLTK";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
    }),
  });
  exe.addWin32ResourceFile(.{
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

  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib") );
  exe.addIncludePath( b.path("lib/GL") );
  exe.addIncludePath( b.path("lib/CFLTK/include") );

  exe.addLibraryPath( b.path("lib/CFLTK") );
  exe.addLibraryPath( b.path("lib/FLTK") );

  exe.linkSystemLibrary("ws2_32");
  exe.linkSystemLibrary("comctl32");
  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("gdiplus");
  exe.linkSystemLibrary("oleaut32");
  exe.linkSystemLibrary("ole32");
  exe.linkSystemLibrary("uuid");
  exe.linkSystemLibrary("shell32");
  exe.linkSystemLibrary("advapi32");
  exe.linkSystemLibrary("comdlg32");
  exe.linkSystemLibrary("winspool");
  exe.linkSystemLibrary("user32");
  exe.linkSystemLibrary("kernel32");
  exe.linkSystemLibrary("odbc32");
  exe.linkSystemLibrary("cfltk2");
  exe.linkSystemLibrary("fltk");
  exe.linkSystemLibrary("fltk_images");
  exe.linkSystemLibrary("fltk_jpeg");
  exe.linkSystemLibrary("fltk_png");
  exe.linkSystemLibrary("fltk_z");

  exe.linkLibCpp();
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
    .root_module = b.createModule(.{
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}