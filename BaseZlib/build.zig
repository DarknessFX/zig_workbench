const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseZlib";
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

  const c_srcs = .{
    "lib/zlib/adler32.c",
    "lib/zlib/compress.c",
    "lib/zlib/crc32.c",
    "lib/zlib/deflate.c",
    "lib/zlib/gzclose.c",
    "lib/zlib/gzlib.c",
    "lib/zlib/gzread.c",
    "lib/zlib/gzwrite.c",
    "lib/zlib/inflate.c",
    "lib/zlib/infback.c",
    "lib/zlib/inftrees.c",
    "lib/zlib/inffast.c",
    "lib/zlib/trees.c",
    "lib/zlib/uncompr.c",
    "lib/zlib/zutil.c",
  };
  inline for (c_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file = b.path(c_cpp), 
      .flags = &.{ "-std=c89" }
    });
  }

  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib/zlib") );
  exe.linkLibC();  
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