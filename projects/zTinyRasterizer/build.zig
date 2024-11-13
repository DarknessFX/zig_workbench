//
// DFX porting to zig
//
// Credits:
//   Nikita Lisitsa - @lisyarus
//   https://lisyarus.github.io/blog/posts/implementing-a-tiny-cpu-rasterizer-part-1.html
//
//

const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "zRasterizer";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = .{ .path = rootfile },
    .target = target,
    .optimize = optimize
  });

  exe.addIncludePath( .{ .path = "lib/SDL2/include" }  );
  exe.addLibraryPath( .{ .path = "lib/SDL2/" } );
  exe.linkSystemLibrary("SDL2");
  exe.linkSystemLibrary("SDL2_TTF");
  //exe.linkSystemLibrary("OpenGL32");
  b.installBinFile("lib/SDL2/SDL2.dll", "SDL2.dll");
  b.installBinFile("lib/SDL2/SDL2_ttf.dll", "SDL2_ttf.dll");

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
    .root_source_file = .{ .path = rootfile },
    .target = target,
   .optimize = optimize,
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
