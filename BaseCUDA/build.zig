//!zig-autodoc-section: BaseCUDA.Main
//!   BaseCUDA, template for Nvidia CUDA program.
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

  const projectname = "BaseCUDA";
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
  
// ===========
  std.log.info("1) Compiling lib\\cuda.dll.", .{});
  const cwd: []u8 = @constCast(b.build_root.path orelse ".");
  var io_impl: std.Io.Threaded = .init_single_threaded;
  const io = io_impl.io();
  std.Io.Dir.createDirAbsolute(io, fmt("{s}\\{s}", .{cwd, "lib"}), .default_dir) catch  { };

  const lib_path = fmt("{s}\\lib", .{ cwd });
  const compileCUDAstep = b.addSystemCommand(&.{ "CMD", "/S", "/C", "CALL",
    "D:\\Program Files\\VisualStudio\\VC\\Auxiliary\\Build\\vcvars64.bat",
    "&",
    "nvcc",
    "--shared", "-allow-unsupported-compiler", 
    "-odir", lib_path,
    "-o", "lib\\cuda.dll",
    "main.cu"
  });
  exe.step.dependOn(&compileCUDAstep.step);
  b.getInstallStep().dependOn(&compileCUDAstep.step);
// ===========

  exe.root_module.addLibraryPath( b.path("lib") );
  exe.root_module.linkSystemLibrary("cuda", .{});

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  std.log.info("2) Building {s}.", .{ projectname });
  b.installArtifact(exe);
  
  //b.installBinFile("lib/cuda.dll", "cuda.dll");
// ===========
  std.log.info("3) Copying lib\\cuda.dll to {s}.", .{ b.exe_dir });
  const copyDLL = b.addSystemCommand(&.{ "CMD", "/C", 
    "COPY", "/Y", 
    fmt("\"{s}\\lib\\cuda.dll\"", .{ cwd }), 
    fmt("\"{s}\\{s}\"", .{ cwd, b.exe_dir }), 
  });
  copyDLL.step.dependOn(&compileCUDAstep.step);
// ===========

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
//#region MARK: UTIL
//=============================================================================
inline fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; 
}


//#endregion ==================================================================
//=============================================================================