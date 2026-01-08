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

pub fn build(b: *std.Build) !void {
  const optimize = b.standardOptimizeOption(.{});

  current_path = std.fs.realpathAlloc(std.heap.page_allocator, ".") catch unreachable;
  build_context = b;

  try getEmscriptenPaths(b.allocator);
  
  for (targets) |t| {
    const target = b.resolveTargetQuery(t);
    switch (t.os_tag.?) {
      .windows => { try buildDesktop(b, target, optimize); },
      .emscripten => { try buildWeb(b, target, optimize); },
      else => |os| std.debug.print(projectname ++ "ERROR: Build to platform {any} not supported", .{ os }),
    }
  }
}

pub fn buildDesktop(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
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
  }

  exe.linkLibC();

  exe.addIncludePath( b.path("lib/SDL3") );
  exe.addIncludePath( b.path("lib/SDL3/include") );
  exe.addLibraryPath(b.path("lib/SDL3/lib"));
  exe.linkSystemLibrary("libSDL3");
  b.installBinFile("lib/SDL3/lib/libSDL3.dll", "libSDL3.dll");

  exe.addIncludePath(b.path("lib/dawn"));
  exe.addLibraryPath(b.path("lib/dawn"));
  exe.linkSystemLibrary("webgpu_dawn");
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
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}

pub fn buildWeb(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
  const rootfile = "web.zig";

  const lib = b.addLibrary(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
    }),
  });
  b.lib_dir = b.cache_root.path.?;
  lib.linkLibC();

  lib.addIncludePath( b.path("lib/SDL3/include"));
  lib.addLibraryPath( b.path("lib/SDL3/lib") );

  lib.addIncludePath( .{ .cwd_relative = emscripten_include_path });
  lib.addIncludePath( .{ .cwd_relative = emscripten_webgpu });

  // const shared_exports = &.{ "jsPrint", "jsPrintFlush" };
  // lib.root_module.export_symbol_names = shared_exports;
  // lib.entry = .disabled;
  // lib.rdynamic = true;

  const wasm_lib_path = b.fmt("{s}/libBaseWebGPU.a", .{ b.lib_dir });
  const build_wasm_step = b.addInstallArtifact(lib, .{});

  var lib_dir: []const u8 = undefined;
  switch (optimize) {
    .Debug => lib_dir = "bin/web/Debug",
    .ReleaseSafe => lib_dir = "bin/web/ReleaseSafe",
    .ReleaseFast => lib_dir = "bin/web/ReleaseFast",
    .ReleaseSmall => lib_dir = "bin/web/ReleaseSmall"
  }
  try ensureDirPath(&.{ "bin", "web", "Debug" });

  // Emscripten - Build HTML, JS, WASM
  const bat_content = try std.fmt.allocPrint(b.allocator,
    \\@echo off
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
  try std.fs.cwd().writeFile(.{
    .sub_path = bat_file,
    .data = bat_content,
  });

  const run_bat = b.addSystemCommand(&.{ "cmd", "/c", bat_file });
  run_bat.step.dependOn(&build_wasm_step.step);
  b.getInstallStep().dependOn(&run_bat.step);
}

fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}

fn getEmscriptenPaths(allocator: std.mem.Allocator) !void {
  const emsdk = try std.process.getEnvVarOwned(allocator, "EMSDK");
  defer allocator.free(emsdk);

  const emscripten_path = try std.fs.path.join(allocator, &.{ emsdk, "upstream", "emscripten" });
  defer allocator.free(emscripten_path);

  emscripten_sdk_path = try std.fs.realpathAlloc(allocator, emscripten_path);

  const include_path = try std.fs.path.join(allocator, &.{ emscripten_path, "cache", "sysroot", "include" });
  emscripten_include_path = try std.fs.realpathAlloc(allocator, include_path);

  const webgpu_path = try std.fs.path.join(allocator, &.{ emscripten_path, "cache", "ports", "emdawnwebgpu", "emdawnwebgpu_pkg", "webgpu", "include", "webgpu" });
  emscripten_webgpu = try std.fs.realpathAlloc(allocator, webgpu_path);

  const emcc_path = try std.fs.path.join(allocator, &.{ emscripten_path, "emcc.bat" });
  emscripten_emcc = try std.fs.realpathAlloc(allocator, emcc_path);

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

    std.fs.cwd().makeDir(dir_path) catch |err| switch (err) {
      error.PathAlreadyExists => {}, 
      else => |e| return e,
    };
  }
}