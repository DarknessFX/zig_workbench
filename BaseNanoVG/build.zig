const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseNanoVG";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize
  });
  exe.addWin32ResourceFile(.{
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib/glfw/include") );
  exe.addIncludePath( b.path("lib/glad") );
  exe.addIncludePath( b.path("lib/nanovg") );

  const use_shared = b.option(bool, "shared", "Use shared library linking") orelse false;
  if (use_shared) {
    exe.addLibraryPath( b.path("lib/glfw/shared") );
    exe.linkSystemLibrary("glfw3dll");
    b.installBinFile("lib/glfw/shared/glfw3.dll", "glfw3.dll");
  } else {
    exe.addLibraryPath( b.path("lib/glfw/static") );
    exe.linkSystemLibrary("glfw3");
    exe.linkSystemLibrary("gdi32");
  }
  exe.linkSystemLibrary("opengl32");

  const c_srcs = .{
    "lib/glad/src/glad.c",
    "lib/nanovg/nanovg.c",
    "lib/nanovg/nanovg_gl.c",
  };
  inline for (c_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file = b.path(c_cpp), 
      .flags = &.{ }
    });
  }

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
