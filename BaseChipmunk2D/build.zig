const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseChipmunk2D";
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
  exe.addIncludePath( b.path("lib") );
  exe.addIncludePath( b.path("lib/chipmunk") );
  exe.addIncludePath( b.path("lib/chipmunk/include") );

  const c_srcs = .{
    "lib/chipmunk/src/chipmunk.c",
    "lib/chipmunk/src/cpArbiter.c",
    "lib/chipmunk/src/cpArray.c",
    "lib/chipmunk/src/cpBBTree.c",
    "lib/chipmunk/src/cpBody.c",
    "lib/chipmunk/src/cpCollision.c",
    "lib/chipmunk/src/cpConstraint.c",
    "lib/chipmunk/src/cpDampedRotarySpring.c",
    "lib/chipmunk/src/cpDampedSpring.c",
    "lib/chipmunk/src/cpGearJoint.c",
    "lib/chipmunk/src/cpGrooveJoint.c",
    "lib/chipmunk/src/cpHashSet.c",
    "lib/chipmunk/src/cpHastySpace.c",
    "lib/chipmunk/src/cpMarch.c",
    "lib/chipmunk/src/cpPinJoint.c",
    "lib/chipmunk/src/cpPivotJoint.c",
    "lib/chipmunk/src/cpPolyline.c",
    "lib/chipmunk/src/cpPolyShape.c",
    "lib/chipmunk/src/cpRatchetJoint.c",
    "lib/chipmunk/src/cpRobust.c",
    "lib/chipmunk/src/cpRotaryLimitJoint.c",
    "lib/chipmunk/src/cpShape.c",
    "lib/chipmunk/src/cpSimpleMotor.c",
    "lib/chipmunk/src/cpSlideJoint.c",
    "lib/chipmunk/src/cpSpace.c",
    "lib/chipmunk/src/cpSpaceComponent.c",
    "lib/chipmunk/src/cpSpaceDebug.c",
    "lib/chipmunk/src/cpSpaceHash.c",
    "lib/chipmunk/src/cpSpaceQuery.c",
    "lib/chipmunk/src/cpSpaceStep.c",
    "lib/chipmunk/src/cpSpatialIndex.c",
    "lib/chipmunk/src/cpSweep1D.c",
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