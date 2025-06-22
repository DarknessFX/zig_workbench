const std = @import("std");

var build_context: *std.Build = undefined;
var emscripten_sdk_path: []const u8 = "";     // You can put your emsdk path manually here, ex: "D:/Program Files/emscripten/emsdk/upstream/emscripten/"
var emscripten_include_path: []const u8 = ""; // same here: emscripten_sdk_path ++ "cache/sysroot/include/";

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

  const lib = b.addStaticLibrary(.{
    .name = "WASM",
    .root_source_file = b.path("main.zig"),
    .target = target,
    .optimize = optimize,
  });

  switch (optimize) {
    .Debug =>  b.lib_dir = "bin/Debug",
    .ReleaseSafe =>  b.lib_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.lib_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.lib_dir = "bin/ReleaseSmall"
  }

  lib.linkLibC();
  b.installArtifact(lib);

  // Emscripten - Build HTML, JS, WASM
  const wasm_cmd = b.addSystemCommand(&[_][]const u8{ fmt("{s}/{s}", .{ emscripten_sdk_path, "emcc.bat" }) });
  wasm_cmd.addFileArg(lib.getEmittedBin());
  wasm_cmd.addArgs(&[_][]const u8{
    "-o",
    b.fmt("{s}/BaseWasm.html", .{ b.lib_dir }),
    "-Oz",
    "-sWASM=1",
    "-sSINGLE_FILE=1",
    "-sEXIT_RUNTIME=1",
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