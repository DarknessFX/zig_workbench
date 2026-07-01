//!zig-autodoc-section: Basebox3D.Build
//! Basebox3D\\build.zig :
//!   Build Template using box3D.
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

  const projectname = "Basebox3D";
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
  exe.root_module.addIncludePath( b.path("lib") );

  const c_srcs = .{
      "lib/box3d/src/aabb.c",
      "lib/box3d/src/arena_allocator.c",
      "lib/box3d/src/bitset.c",
      "lib/box3d/src/block_allocator.c",
      "lib/box3d/src/body.c",
      "lib/box3d/src/broad_phase.c",
      "lib/box3d/src/capsule.c",
      "lib/box3d/src/compound.c",
      "lib/box3d/src/constraint_graph.c",
      "lib/box3d/src/contact.c",
      "lib/box3d/src/contact_solver.c",
      "lib/box3d/src/convex_manifold.c",
      "lib/box3d/src/core.c",
      "lib/box3d/src/distance.c",
      "lib/box3d/src/distance_joint.c",
      "lib/box3d/src/dynamic_tree.c",
      "lib/box3d/src/height_field.c",
      "lib/box3d/src/hull.c",
      "lib/box3d/src/id_pool.c",
      "lib/box3d/src/island.c",
      "lib/box3d/src/joint.c",
      "lib/box3d/src/manifold.c",
      "lib/box3d/src/math_functions.c",
      "lib/box3d/src/mesh.c",
      "lib/box3d/src/mesh_contact.c",
      "lib/box3d/src/motor_joint.c",
      "lib/box3d/src/mover.c",
      "lib/box3d/src/parallel_for.c",
      "lib/box3d/src/parallel_joint.c",
      "lib/box3d/src/physics_world.c",
      "lib/box3d/src/prismatic_joint.c",
      "lib/box3d/src/recording.c",
      "lib/box3d/src/recording_replay.c",
      "lib/box3d/src/revolute_joint.c",
      "lib/box3d/src/scheduler.c",
      "lib/box3d/src/sensor.c",
      "lib/box3d/src/shape.c",
      "lib/box3d/src/simd.c",
      "lib/box3d/src/solver.c",
      "lib/box3d/src/solver_set.c",
      "lib/box3d/src/sphere.c",
      "lib/box3d/src/spherical_joint.c",
      "lib/box3d/src/table.c",
      "lib/box3d/src/timer.c",
      "lib/box3d/src/triangle_manifold.c",
      "lib/box3d/src/types.c",
      "lib/box3d/src/weld_joint.c",
      "lib/box3d/src/wheel_joint.c",
      "lib/box3d/src/world_snapshot.c",
  };
  inline for (c_srcs) |c_cpp| {
    exe.root_module.addCSourceFile(.{
      .file  = b.path(c_cpp),
      .flags = &.{ },
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
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
//#endregion ==================================================================
//=============================================================================
