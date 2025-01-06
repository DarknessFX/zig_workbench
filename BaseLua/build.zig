const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseLua";
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

  exe.linkLibC();

  // Lua
  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib/lua") );
  b.installBinFile("script.lua", "script.lua");

  const imgui_srcs = .{
    "lib/lua/lapi.c",
    "lib/lua/lauxlib.c",
    "lib/lua/lbaselib.c",
    "lib/lua/lcode.c",
    "lib/lua/lctype.c",
    "lib/lua/ldebug.c",
    "lib/lua/ldblib.c",
    "lib/lua/ldo.c",
    "lib/lua/ldump.c",
    "lib/lua/lfunc.c",
    "lib/lua/lgc.c",
    "lib/lua/linit.c",
    "lib/lua/liolib.c",
    "lib/lua/llex.c",
    "lib/lua/lmathlib.c",
    "lib/lua/lmem.c",
    "lib/lua/loadlib.c",
    "lib/lua/lobject.c",
    "lib/lua/lopcodes.c",
    "lib/lua/loslib.c",
    "lib/lua/lparser.c",
    "lib/lua/lstate.c",
    "lib/lua/lstring.c",
    "lib/lua/lstrlib.c",
    "lib/lua/ltable.c",
    "lib/lua/ltablib.c",
    "lib/lua/lutf8lib.c",
    "lib/lua/ltm.c",
    "lib/lua/lundump.c",
    "lib/lua/lvm.c",
    "lib/lua/lzio.c",
    "lib/lua/lcorolib.c"
  };
  inline for (imgui_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file = b.path(c_cpp),
      .flags = &.{ }
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