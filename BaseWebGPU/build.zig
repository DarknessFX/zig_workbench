//!zig-autodoc-section: BaseWebGPU\\main.zig
//! main.zig :
//!  Template using WebGPU.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const builtin = @import("builtin");

const projectname = "BaseWebGPU";
var current_path: []u8 = undefined;
var build_context: *std.Build = undefined;
var emscripten_sdk_path: []const u8 = undefined;
var emscripten_include_path: []const u8 = undefined;
var emscripten_emcc: []const u8 = undefined;
var emscripten_webgpu: []const u8 = undefined;

const targets: []const std.Target.Query = &.{
  .{ .cpu_arch = .x86_64, .os_tag = .windows },
  .{ .cpu_arch = .wasm32, .os_tag = .emscripten },
};

//=============================================================================
//#region MARK: Build
//=============================================================================
pub fn build(b: *std.Build) !void {
  const optimize = b.standardOptimizeOption(.{});

  current_path = @constCast(b.build_root.path orelse ".");
  build_context = b;

  _ = getEmsdkPath(b);
  
  for (targets) |t| {
    const target = b.resolveTargetQuery(t);
    switch (t.os_tag.?) {
      .windows => { try buildDesktop(b, target, optimize); },
      .emscripten => { try buildWeb(b, target, optimize); },
      else => |os| std.debug.print(projectname ++ "ERROR: Build to platform {any} not supported", .{ os }),
    }
  }
}

//#endregion ==================================================================
//#region MARK: Windows
//=============================================================================
pub fn buildDesktop(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
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

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug/Windows",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe/Windows",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast/Windows",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall/Windows"
  }

  exe.root_module.addIncludePath( b.path("lib/SDL3") );
  exe.root_module.addIncludePath( b.path("lib/SDL3/include") );
  exe.root_module.addLibraryPath(b.path("lib/SDL3/lib"));
  exe.root_module.linkSystemLibrary("libSDL3", .{});
  b.installBinFile("lib/SDL3/lib/libSDL3.dll", "libSDL3.dll");

  exe.root_module.addIncludePath(b.path("lib/dawn"));
  exe.root_module.addLibraryPath(b.path("lib/dawn"));
  exe.root_module.linkSystemLibrary("webgpu_dawn", .{});
  b.installBinFile("lib/dawn/webgpu_dawn.dll", "webgpu_dawn.dll");
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
//#region MARK: Web
//=============================================================================
pub fn buildWeb(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
  const mainfile = "web.zig";

  const lib = b.addLibrary(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
    }),
  });
  b.lib_dir = b.cache_root.path.?;
  lib.root_module.addCMacro("deprecated", "");
  lib.root_module.addCMacro("__attribute__(x)", "");

  lib.root_module.addIncludePath( b.path("lib/SDL3/include"));
  lib.root_module.addLibraryPath( b.path("lib/SDL3/lib") );

  lib.root_module.addIncludePath( .{ .cwd_relative = emscripten_include_path });
  lib.root_module.addIncludePath( .{ .cwd_relative = emscripten_webgpu });

  // const shared_exports = &.{ "jsPrint", "jsPrintFlush" };
  // lib.root_module.export_symbol_names = shared_exports;
  // lib.entry = .disabled;
  // lib.rdynamic = true;

  var lib_dir: []const u8 = undefined;
  switch (optimize) {
    .Debug => { 
      b.lib_dir = "bin/Debug/web"; 
      try ensureDirPath(&.{ "bin", "Debug", "web" });
      std.debug.print("NOTE: emscripten Debug Build is broken in 0.16, only Release builds are working", .{});
    },
    .ReleaseSafe => {
      b.lib_dir = "bin/ReleaseSafe/web";
      try ensureDirPath(&.{ "bin", "ReleaseSafe", "web" });
    },
    .ReleaseFast => {
      b.lib_dir = "bin/ReleaseFast/web";
      try ensureDirPath(&.{ "bin", "ReleaseFast", "web" });
    },
    .ReleaseSmall =>{
      b.lib_dir = "bin/ReleaseSmall/web";
      try ensureDirPath(&.{ "bin", "ReleaseSmall", "web" });
    },
  }

  const wasm_lib_path = b.fmt("{s}/libBaseWebGPU.a", .{ b.lib_dir });
  const build_wasm_step = b.addInstallArtifact(lib, .{});
  // Emscripten - Build HTML, JS, WASM
  const bat_content = try std.fmt.allocPrint(b.allocator,
    \\@echo off
    \\SET EMSDK_QUIET=1
    \\call "{s}\\..\\..\\emsdk_env.bat"
    \\"{s}" "{s}" ^
    \\ -o "{s}\\{s}.html" ^
    \\ -Oz ^
    \\ --shell-file web.html ^
    \\ -I"{s}" ^
    \\ --pre-js "{s}" ^
    \\ --use-port=emdawnwebgpu ^
    \\ -flto=full ^
    \\ -sENVIRONMENT=web ^
    \\ -sWASM=1 ^
    \\ -sSINGLE_FILE=1 ^
    // \\ -sMAIN_MODULE=1 ^
    \\ -sASYNCIFY=1 ^
    \\ -sEXPORTED_FUNCTIONS=_main ^
    \\ -sERROR_ON_UNDEFINED_SYMBOLS=0 ^
    \\ -sINITIAL_MEMORY=4MB ^ 
    // \\ -sFILESYSTEM=0 ^
    // \\ -sALLOW_MEMORY_GROWTH=1 ^
    // \\ -sFILESYSTEM=0 ^
    // \\ -sINVOKE_RUN=1 ^
    // \\ -sSTACK_SIZE=64KB ^
    // \\ -sNO_EXIT_RUNTIME=1 ^
    // \\ -sERROR_ON_UNDEFINED_SYMBOLS=0 ^
    // \\ -sEXPORTED_FUNCTIONS=_main ^
    // \\ -sEXPORTED_RUNTIME_METHODS=ccall,cwrap ^
    // \\ --closure=1
  , .{
    emscripten_sdk_path,
    emscripten_emcc,
    wasm_lib_path,
    lib_dir,
    projectname,
    emscripten_include_path,
    fmt("{s}\\{s}", .{ current_path, "web.js"}),
  });
  defer b.allocator.free(bat_content);

  const bat_file = try b.cache_root.join(b.allocator, &.{ "build_web_temp.bat" });
  var dir = std.Io.Dir.cwd();
  var threaded: std.Io.Threaded = .init_single_threaded;
  const io = threaded.io();
  var file = dir.createFile(io, bat_file, .{}) catch unreachable;

  var buffer: [4096]u8 = undefined;
  var buffered = file.writer(io, &buffer);
  const writer = &buffered.interface;
  try writer.writeAll(bat_content);
  writer.flush() catch unreachable;
  file.close(io);

  const run_bat = b.addSystemCommand(&.{ "cmd", "/c", bat_file });
  run_bat.step.dependOn(&build_wasm_step.step);
  b.getInstallStep().dependOn(&run_bat.step);
}

fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn getEmsdkPath(b: *std.Build) bool {
  const run = b.addSystemCommand(&.{"echo"});   // dummy command just to get env map
  const env_map = run.getEnvMap();

  if (env_map.get("EMSDK")) |path| {
    emscripten_sdk_path = b.pathJoin(&.{ path, "upstream/emscripten" });
    emscripten_emcc = b.pathJoin(&.{ emscripten_sdk_path, "emcc.bat" });
    emscripten_include_path = b.pathJoin(&.{ emscripten_sdk_path, "cache/sysroot/include" });
    emscripten_webgpu = b.pathJoin(&.{ emscripten_sdk_path, "cache/ports/emdawnwebgpu/emdawnwebgpu_pkg/webgpu/include/webgpu" });
    // std.debug.print("EMSDK found: {s}\n", .{emscripten_sdk_path});
    return true;
  }
  std.debug.print("EMSDK environment variable not found\n", .{});
  return false;
}

fn ensureDirPath(parts: []const []const u8) !void {
  var path_buf: [1024]u8 = undefined;
  var path_len: usize = 0;

  for (parts) |part| {
    if (path_len > 0) {
      path_buf[path_len] = std.fs.path.sep;
      path_len += 1;
    }
    @memcpy(path_buf[path_len..][0..part.len], part);
    path_len += part.len;

    const dir_path = path_buf[0..path_len];

    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    std.Io.Dir.createDir(std.Io.Dir.cwd(), io, dir_path, .default_file) catch {};
    // std.fs.cwd().makeDir(dir_path) catch |err| switch (err) {
    //   error.PathAlreadyExists => {}, 
    //   else => |e| return e,
    // };
  }
}
//#endregion ==================================================================
//=============================================================================