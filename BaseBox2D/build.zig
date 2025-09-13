const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseBox2D";
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
  
  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib") );

  const c_srcs = .{
    "lib/box2d/src/aabb.c", 
    "lib/box2d/src/array.c", 
    "lib/box2d/src/bitset.c", 
    "lib/box2d/src/body.c", 
    "lib/box2d/src/broad_phase.c", 
    "lib/box2d/src/constraint_graph.c", 
    "lib/box2d/src/contact.c", 
    "lib/box2d/src/contact_solver.c", 
    "lib/box2d/src/core.c", 
    "lib/box2d/src/distance.c", 
    "lib/box2d/src/distance_joint.c", 
    "lib/box2d/src/dynamic_tree.c", 
    "lib/box2d/src/geometry.c", 
    "lib/box2d/src/hull.c", 
    "lib/box2d/src/id_pool.c", 
    "lib/box2d/src/island.c", 
    "lib/box2d/src/joint.c", 
    "lib/box2d/src/manifold.c", 
    "lib/box2d/src/math_functions.c", 
    "lib/box2d/src/motor_joint.c", 
    "lib/box2d/src/mouse_joint.c", 
    "lib/box2d/src/prismatic_joint.c", 
    "lib/box2d/src/revolute_joint.c", 
    "lib/box2d/src/shape.c", 
    "lib/box2d/src/solver.c", 
    "lib/box2d/src/solver_set.c", 
    "lib/box2d/src/stack_allocator.c", 
    "lib/box2d/src/table.c", 
    "lib/box2d/src/timer.c", 
    "lib/box2d/src/types.c", 
    "lib/box2d/src/weld_joint.c", 
    "lib/box2d/src/wheel_joint.c", 
    "lib/box2d/src/world.c", 
  };
  inline for (c_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file  = b.path(c_cpp), 
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