const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseVulkan";
  const rootfile = "main.zig";
  const vulkan_sdk = "D:/Program Files/VulkanSDK/";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize
  });
  exe.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.addIncludePath( b.path("lib/glfw"));
  exe.addLibraryPath( b.path("lib/glfw") );
  exe.linkSystemLibrary("glfw3");

  exe.addIncludePath( .{ .cwd_relative = vulkan_sdk ++ "Include" } );
  exe.addIncludePath( .{ .cwd_relative = vulkan_sdk ++ "Include/vulkan" });
  exe.addLibraryPath( .{ .cwd_relative = vulkan_sdk ++ "lib" });
  exe.linkSystemLibrary("vulkan-1");

  exe.linkSystemLibrary("gdi32");
  exe.linkLibC();

  b.installBinFile("triangle_frag.spv", "triangle_frag.spv");
  b.installBinFile("triangle_vert.spv", "triangle_vert.spv");

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