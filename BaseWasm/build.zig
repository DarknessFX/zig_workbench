//!zig-autodoc-section: BaseWasm.Build
//! BaseWasm//build.zig :
//!  Build Template of HTML+Wasm program.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

var build_context: *std.Build = undefined;
var emscripten_sdk_path: []const u8 = "";     // You can put your emsdk path manually here, ex: "D:/Program Files/emscripten/emsdk/upstream/emscripten/"
var emscripten_include_path: []const u8 = ""; // same here: emscripten_sdk_path ++ "cache/sysroot/include/";

//#endregion ==================================================================
//#region MARK: INSTALL
//=============================================================================
pub fn build(b: *std.Build) void {
  if (!getEmsdkPath(b)) {
    @panic("Unable to find emscripten folder in your Enviroment Path (EMSDK).\n");
  }
  build_context = b;

  const wasm_target = std.Target.Query{
    .cpu_arch = .wasm32,
    .os_tag = .emscripten,
  };
  const target = b.standardTargetOptions(.{ .default_target = wasm_target });
  const optimize = b.standardOptimizeOption(.{});

  const current_path = @constCast(b.build_root.path orelse ".");
  const projectname: []const u8 = "BaseWasm";
  const mainfile: []const u8 = "main.zig";

  const lib = b.addLibrary(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
    }),
  });

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

  const shared_exports = &.{ "Print", "printFlush" };
  lib.root_module.export_symbol_names = shared_exports;
  lib.entry = .disabled;
  lib.rdynamic = true;
  const build_wasm_step = b.addInstallArtifact(lib, .{});

  // Emscripten - Build HTML, JS, WASM
  const wasm_cmd = b.addSystemCommand(&[_][]const u8{ fmt("{s}/{s}", .{ emscripten_sdk_path, "emcc.bat" }) });
  wasm_cmd.addFileArg(lib.getEmittedBin());
  wasm_cmd.addArgs(&[_][]const u8{
 
  });

  const wasm_lib_path = b.fmt("{s}/lib{s}.a", .{ b.lib_dir, projectname });
  const bat_content = std.fmt.allocPrint(b.allocator,
    \\@echo off
    \\SET EMSDK_QUIET=1
    \\call "{s}\\..\\..\\emsdk_env.bat"
    \\"{s}" "{s}" ^
    \\ -o "{s}\\{s}.html" ^
    \\ -Oz ^
    \\ --shell-file web.html ^
    \\ --pre-js "{s}" ^
    \\ -sWASM=1 ^
    \\ -sSINGLE_FILE=1 ^
    \\ -sEXIT_RUNTIME=1 ^
    \\ -sEXPORTED_FUNCTIONS=_Init,_Update ^
    \\ -sEXPORTED_RUNTIME_METHODS=ccall,cwrap,wasmExports ^
    \\ -Wno-js-compiler ^
    \\ -sWARN_ON_UNDEFINED_SYMBOLS=0 ^
    \\ -sERROR_ON_UNDEFINED_SYMBOLS=0
    \\
  , .{
    emscripten_sdk_path,
    fmt("{s}/{s}", .{ emscripten_sdk_path, "emcc.bat" }),
    wasm_lib_path,
    b.lib_dir,
    projectname,
    fmt("{s}\\{s}", .{ current_path, "web.js"}),
  }) catch unreachable;
  defer b.allocator.free(bat_content);

  const bat_file = b.cache_root.join(b.allocator, &.{ "build_web_temp.bat" }) catch unreachable;
  var dir = std.Io.Dir.cwd();
  var threaded: std.Io.Threaded = .init_single_threaded;
  const io = threaded.io();
  var file = dir.createFile(io, bat_file, .{}) catch unreachable;

  var buffer: [4096]u8 = undefined;
  var buffered = file.writer(io, &buffer);
  const writer = &buffered.interface;
  writer.writeAll(bat_content) catch unreachable;
  writer.flush() catch unreachable;
  file.close(io);

  const run_bat = b.addSystemCommand(&.{ "cmd", "/c", bat_file });
  run_bat.step.dependOn(&build_wasm_step.step);
  b.getInstallStep().dependOn(&run_bat.step);
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}

fn getEmsdkPath(b: *std.Build) bool {
  const run = b.addSystemCommand(&.{"echo"});   // dummy command just to get env map
  const env_map = run.getEnvMap();

  if (env_map.get("EMSDK")) |path| {
    emscripten_sdk_path = std.Build.pathJoin(b, &.{ path, "upstream/emscripten" });
    emscripten_include_path = std.Build.pathJoin(b, &.{ emscripten_sdk_path, "cache/sysroot/include" });
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