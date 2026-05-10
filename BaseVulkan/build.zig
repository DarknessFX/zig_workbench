//!zig-autodoc-section: BaseVulkan.Build
//!  BaseVulkan\\build.zig
//!    Template for a Vulkan program using GLFW3.
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

  const projectname = "BaseVulkan";
  const mainfile = "main.zig";
  const vulkan_sdk = "D:/Program Files/VulkanSDK/";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
    }),
  });

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }

  exe.root_module.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.root_module.addIncludePath( b.path("lib/glfw"));
  exe.root_module.addLibraryPath( b.path("lib/glfw") );
  exe.root_module.linkSystemLibrary("glfw3", .{});

  exe.root_module.addIncludePath( .{ .cwd_relative = vulkan_sdk ++ "Include" } );
  exe.root_module.addIncludePath( .{ .cwd_relative = vulkan_sdk ++ "Include/vulkan" });
  exe.root_module.addLibraryPath( .{ .cwd_relative = vulkan_sdk ++ "lib" });
  exe.root_module.linkSystemLibrary("vulkan-1", .{});

  exe.root_module.linkSystemLibrary("gdi32", .{});

  b.installBinFile("triangle_frag.spv", "triangle_frag.spv");
  b.installBinFile("triangle_vert.spv", "triangle_vert.spv");

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