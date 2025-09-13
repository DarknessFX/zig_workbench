const std = @import("std");
const builtin = @import("builtin");

const projectname: []const u8 = "BaseRayLib";
var current_path: []u8 = undefined;
var build_context: *std.Build = undefined;
var emscripten_sdk_path: []const u8 = "";  //"C:/emscripten/emsdk/upstream/emscripten/";
var emscripten_include_path: []const u8 = ""; //emscripten_sdk_path ++ "cache/sysroot/include/";

const web_exports = &.{ }; // Functions that are called by HTML JS

const targets: []const std.Target.Query = &.{
  .{ .cpu_arch = .x86_64, .os_tag = .windows },
  .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
};

pub fn build(b: *std.Build) !void {
  const optimize = b.standardOptimizeOption(.{});
  current_path = std.fs.realpathAlloc(std.heap.page_allocator, ".") catch unreachable;
  build_context = b;

  for (targets) |t| {
    const target = b.resolveTargetQuery(t);
    switch (t.os_tag.?) {
      .windows => { buildWindows(b, target, optimize); },
      .freestanding => { 
        if (getEmsdkPath(b)) {
          buildHTML(b, target, optimize);
        } else {
          std.debug.print("\nWeb build skipped: Unable to find emscripten folder in your Enviroment PATH (EMSDK).\n", .{});
        }
      },
      else => |os| std.debug.print(projectname ++ "ERROR: Build to platform {any} not supported", .{ os }),
    }
  }
}

pub fn buildWindows(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
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
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });
  exe.linkLibC();

  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib/raylib/include") );
  exe.addLibraryPath( b.path("lib/raylib") );
  exe.linkSystemLibrary("raylib");
  exe.linkSystemLibrary("winmm");
  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("opengl32");
  //b.installBinFile("lib/raylib/raylib.dll", "raylib.dll");

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug/Windows",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe/Windows",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast/Windows",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall/Windows"
    //else  =>  b.exe_dir = "bin/Else",
  }
  b.installArtifact(exe);
}

pub fn buildHTML(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
  const rootfile = "main.zig";

  const lib = b.addLibrary(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
    }),
  });

  lib.root_module.addCMacro("PLATFORM_WEB", "");
  lib.root_module.addCMacro("GRAPHICS_API_OPENGL_ES3", "");

  switch (optimize) {
    .Debug =>  b.lib_dir = "bin/Debug/web",
    .ReleaseSafe =>  b.lib_dir = "bin/ReleaseSafe/web",
    .ReleaseFast =>  b.lib_dir = "bin/ReleaseFast/web",
    .ReleaseSmall =>  b.lib_dir = "bin/ReleaseSmall/web"
  }

  lib.linkLibC();
  lib.addIncludePath( b.path(".") );
  lib.addIncludePath( b.path("lib/raylib/include") );
  lib.addIncludePath( .{ .cwd_relative = emscripten_include_path } );
  lib.addLibraryPath( b.path("lib/raylib") );
  //lib.linkSystemLibrary("raylib");

  b.installArtifact(lib);

  // Emscripten - Build HTML, JS, WASM
  const wasm_cmd = b.addSystemCommand(&[_][]const u8{ fmt("{s}/{s}", .{ emscripten_sdk_path, "emcc.bat" }) });
  wasm_cmd.addFileArg(lib.getEmittedBin());
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rcore.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/utils.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/raudio.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rmodels.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rshapes.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rtext.o") );
  wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rtextures.o") );
  wasm_cmd.addArgs(&[_][]const u8{
    "-o",
    b.fmt("{s}/{s}.html", .{ b.lib_dir, projectname }),
    "-Os", "-Wall",
    "-I.", "-I lib/raylib/include",
    "-L.", "-L lib/raylib",
    "-sWASM=1",
    "-sSINGLE_FILE=1",
    "-sFULL_ES3=1",
    "-sUSE_WEBGL2=1",
    "-sUSE_GLFW=3",
    "-sFILESYSTEM=0",
    //"-sUSE_OFFSET_CONVERTER=1",
  });

  b.getInstallStep().dependOn(&lib.step);
  wasm_cmd.step.dependOn(&lib.step);
  b.getInstallStep().dependOn(&wasm_cmd.step);
}

fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}

fn getEmsdkPath(b: *std.Build) bool {
  const envmap = std.process.getEnvMap(std.heap.page_allocator) catch unreachable;
  if (envmap.get("EMSDK")) |path| {
    emscripten_sdk_path = std.Build.pathJoin(b, &.{ path, "upstream/emscripten" });
    emscripten_include_path = std.Build.pathJoin(b, &.{ emscripten_sdk_path, "cache/sysroot/include" });
    return true;
  }
  return false;
}