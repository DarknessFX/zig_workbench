const std = @import("std");
const builtin = @import("builtin");

const projectname: []const u8 = "BaseWebGPU";
var current_path: []u8 = undefined;
var build_context: *std.Build = undefined;
const emscripten_sdk_path: []const u8 = "D:/Program Files/emscripten/emsdk/upstream/emscripten/";
const emscripten_include_path: []const u8 = emscripten_sdk_path ++ "cache/sysroot/include/";

const shared_exports = &.{ "Print", "printFlush", "Init", "Update", "add", "sub"  };
const web_exports = &.{ "main", "onWindowResize", };

const targets: []const std.Target.Query = &.{
  .{ .cpu_arch = .x86_64, .os_tag = .windows },
  .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
  .{ .cpu_arch = .wasm32, .os_tag = .emscripten },
};

pub fn build(b: *std.Build) !void {
  const optimize = b.standardOptimizeOption(.{});

  current_path = std.fs.realpathAlloc(std.heap.page_allocator, ".") catch unreachable;
  build_context = b;

  for (targets) |t| {
    const target = b.resolveTargetQuery(t);
    switch (t.os_tag.?) {
      .windows => { try buildWindows(b, target, optimize); },
      .emscripten => { try buildWebGPU(b, target, optimize); },
      .freestanding => { try buildWasm(b, target, optimize); },
      else => |os| std.debug.print(projectname ++ "ERROR: Build to platform {any} not supported", .{ os }),
    }
  }
  runExtras();
  try copyToBuildFolder(b, optimize);
}

pub fn buildWindows(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize
  });
  exe.addWin32ResourceFile(.{
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"},
  });

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Windows/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/Windows/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/Windows/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/Windows/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  exe.linkLibC();

  // WebGPU
  exe.addIncludePath( b.path("lib/webgpu") );

  // SDL2
  exe.addIncludePath( b.path("lib/SDL2/include") );
  exe.addLibraryPath( b.path("lib/SDL2") );
  exe.linkSystemLibrary("SDL2");
  b.installBinFile("lib/SDL2/SDL2.dll", "SDL2.dll");

  // Dawn WebGPU
  exe.addLibraryPath( b.path("lib/dawn") );
  exe.linkSystemLibrary("webgpu_dawn");
  b.installBinFile("lib/dawn/webgpu_dawn.dll", "webgpu_dawn.dll");

  // const c_srcs = .{
  // };
  // inline for (c_srcs) |c_src| {
  //   exe.addCSourceFile(.{
  //     .file = b.path(c_src),
  //     .flags = &.{ }
  //   });
  // }

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

  b.getInstallStep().dependOn(&exe.step);
}

pub fn buildWasm(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
  const rootfile = "shared.zig";

  // Build WebGPU as stand-alone wasm.
  const wasm = b.addStaticLibrary(.{
    .name = "shared",
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize,
  });
  wasm.linkLibC();

  wasm.addIncludePath( b.path("lib/wasm_webgpu"));
  const cpp_srcs = .{
    "lib/wasm_webgpu/lib_webgpu.cpp",
  };
  inline for (cpp_srcs) |c_cpp| {
    wasm.addCSourceFile(.{
      .file = b.path(c_cpp),
      .flags = &.{ }
    });
  }

  wasm.addIncludePath( b.path("lib/wasm_webgpu") );
  wasm.addIncludePath( .{ .cwd_relative = emscripten_include_path });

  // Repeated here, allows to switch compile order
  switch (optimize) {
    .Debug =>  b.lib_dir = "bin\\web\\Debug",
    .ReleaseSafe =>  b.lib_dir = "bin\\web\\ReleaseSafe",
    .ReleaseFast =>  b.lib_dir = "bin\\web\\ReleaseFast",
    .ReleaseSmall =>  b.lib_dir = "bin\\web\\ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }

  var path: []const u8 = undefined;
  switch (optimize) {
    .Debug =>  path = "bin\\shared\\Debug",
    .ReleaseSafe =>  path = "bin\\shared\\ReleaseSafe",
    .ReleaseFast =>  path = "bin\\shared\\ReleaseFast",
    .ReleaseSmall =>  path = "bin\\shared\\ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }
  try std.fs.cwd().makePath(path);

  wasm.root_module.export_symbol_names = shared_exports;
  wasm.entry = .disabled;
  wasm.rdynamic = true;
  b.installArtifact(wasm);

  // WASM compile
  // Emscripten - Build HTML, JS, WASM
  const wasm_cmd = b.addSystemCommand(&[_][]const u8{ emscripten_sdk_path ++ "emcc.bat" });
  wasm_cmd.addFileArg(wasm.getEmittedBin());
  wasm_cmd.addFileArg( b.path("lib/wasm_webgpu/lib_webgpu.cpp") );
  wasm_cmd.addArgs(&[_][]const u8{
    "-o",
    b.fmt("{s}/BaseWebGPU_Shared.html", .{ path }),
    "-Oz",
    "--shell-file=shared.html",
    "--js-library",
    b.fmt("{s}\\{s}", .{ current_path, "lib\\wasm_webgpu\\lib_webgpu.js"}),
    "--pre-js",
    b.fmt("{s}\\{s}", .{ current_path, "web.js"}),
    "-sWASM=1",
    "-sSINGLE_FILE=1",
    "-sUSE_WEBGPU=1",
    // "-sUSE_SDL=0",
    "-sFILESYSTEM=0",
    "-sEXPORTED_FUNCTIONS=_Init,_Update,_add,_sub",
    "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap,wasmExports",
    "-flto=full",
    "-sINVOKE_RUN=0",
    "-sNO_EXIT_RUNTIME=1",

    // Fix error of missing print
    "-Wno-js-compiler",
    "-sWARN_ON_UNDEFINED_SYMBOLS=0",
    "-sERROR_ON_UNDEFINED_SYMBOLS=0", 

    "-Wno-experimental",
    "-lhtml5.js",
    fmt("--closure-args=--externs={s}/lib/wasm_webgpu/webgpu-closure-externs.js", .{ current_path }),
  });
  if (optimize == .Debug or optimize == .ReleaseSafe) {
    wasm_cmd.addArgs(&[_][]const u8{
      "-Wall",
      "-jsDWEBGPU_DEBUG=1",
      "-sUSE_OFFSET_CONVERTER",
      "-sASSERTIONS=2",
      "-sSTACK_OVERFLOW_CHECK=2",
      "-sRUNTIME_DEBUG",
      "--cpuprofiler",
      "--memoryprofiler",
      "--threadprofiler",
      "--profiling",
      "--profiling-funcs",
      "--tracing",

      "-sEXPORT_ALL=1",
      "-sEXPORT_BINDINGS=1",
      "-sAUTO_JS_LIBRARIES=0",

      // Extras, Unstable?
      "-sSTB_IMAGE=1",
      // "-sLZ4",
      //"-sMINIMAL_RUNTIME=2",
      "-sABORTING_MALLOC=0",
      "-sTOTAL_STACK=16KB",
      "-sINITIAL_MEMORY=128KB",
      "-sALLOW_MEMORY_GROWTH=1",
      "-Wno-pthreads-mem-growth",

      //"-sDISABLE_EXCEPTION_THROWING=1"
      //"-sTEXTDECODER=2",
      //"--closure", "2",
      //"-sMEMORY64=1",
      //"-sSHARED_MEMORY",
      //"-sRELOCATABLE=1",
      //"-sASYNCIFY", Can build and run async, but break Module.onRuntimeInitialized.

      //"-sVERBOSE=1",
      // "--check", ? output nothing

      // auto-run webserver
      //"--emrun"
    });
  }

  // To avoid mess with .EXE build, I'm manually moving .wasm from /windows to /wasm folder
  if (fileExist(b.fmt("{s}\\{s}\\lib{s}.a", .{ current_path, b.lib_dir, "shared"}),)) {
    const wasm_move = b.addSystemCommand(&.{ "cmd" });
    wasm_move.addArgs(&[_][]const u8{
      "/C",
      "COPY",
      "/Y",
      b.fmt("{s}\\{s}\\lib{s}.a", .{ current_path, b.lib_dir, "shared"}),
      b.fmt("{s}\\{s}\\libshared.a", .{ current_path, path}),
      ">nul"
    });
    defer {
      wasm_move.step.dependOn(&wasm.step);
      b.getInstallStep().dependOn(&wasm_move.step);
    }
  }

  // Lineup steps queue
  b.getInstallStep().dependOn(&wasm.step);
  wasm_cmd.step.dependOn(&wasm.step);
  b.getInstallStep().dependOn(&wasm_cmd.step);
}

pub fn buildWebGPU(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
  const rootfile = "web.zig";

  // Build as WebGPU as static library .a
  const lib = b.addStaticLibrary(.{
      .name = projectname,
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
  });
  lib.linkLibC();

  lib.addIncludePath( b.path("lib/wasm_webgpu"));
  const cpp_srcs = .{
    "lib/wasm_webgpu/lib_webgpu.cpp",
  };
  inline for (cpp_srcs) |c_cpp| {
    lib.addCSourceFile(.{
      .file = b.path(c_cpp),
      .flags = &.{ }
    });
  }

  lib.addIncludePath( b.path("lib/wasm_webgpu") );
  lib.addIncludePath( .{ .cwd_relative = emscripten_include_path });

  switch (optimize) {
    .Debug =>  b.lib_dir = "bin/web/Debug",
    .ReleaseSafe =>  b.lib_dir = "bin/web/ReleaseSafe",
    .ReleaseFast =>  b.lib_dir = "bin/web/ReleaseFast",
    .ReleaseSmall =>  b.lib_dir = "bin/web/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }

  lib.root_module.export_symbol_names = web_exports;

  // <https://github.com/ziglang/zig/issues/8633>
  // const number_of_pages = 2;
  // lib.global_base = 6560;
  lib.entry = .disabled;
  lib.rdynamic = true;
  // lib.import_memory = true;
  // lib.export_memory = true;
  // lib.stack_size = std.wasm.page_size;

  // lib.initial_memory = std.wasm.page_size * number_of_pages;
  // lib.max_memory = std.wasm.page_size * number_of_pages;
  b.installArtifact(lib);

  // libweb.a compile
  // Emscripten - Build HTML, JS, WASM
  const emcc_cmd = b.addSystemCommand(&[_][]const u8{ emscripten_sdk_path ++ "emcc.bat" });
  emcc_cmd.addFileArg(lib.getEmittedBin());
  emcc_cmd.addFileArg( b.path(b.fmt("{s}\\{s}", .{ b.lib_dir, "libshared.a"})) );
  emcc_cmd.addFileArg( b.path("lib/wasm_webgpu/lib_webgpu.cpp") );
  emcc_cmd.addArgs(&[_][]const u8{ 
    "-o",
    fmt("{s}/{s}.html", .{ build_context.lib_dir, projectname }),
    "-Oz",
    "--shell-file=web.html",
    "--js-library",
    fmt("{s}\\{s}", .{ current_path, "lib\\wasm_webgpu\\lib_webgpu.js"}),
    "--pre-js",
    fmt("{s}\\{s}", .{ current_path, "web.js"}),    
    "-sWASM=1",
    "-sSINGLE_FILE=1",
    "-sUSE_WEBGPU=1",
    // "-sUSE_SDL=0",
    "-sFILESYSTEM=0",
    "-sEXPORTED_FUNCTIONS=_Init,_Update,_main,_onWindowResize,_add,_sub",
    "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap,wasmExports",
    "-flto=full",
    "-sINVOKE_RUN=0",
    "-sNO_EXIT_RUNTIME=1",

    // // Fix error of missing "print" extern
    "-Wno-js-compiler",
    "-sWARN_ON_UNDEFINED_SYMBOLS=0",
    "-sERROR_ON_UNDEFINED_SYMBOLS=0", 

    "-Wno-experimental",
    "-lhtml5.js",
    fmt("--closure-args=--externs={s}/lib/wasm_webgpu/webgpu-closure-externs.js", .{ current_path }),
  });
  if (optimize == .Debug or optimize == .ReleaseSafe) {
    emcc_cmd.addArgs(&[_][]const u8{
      "-Wall",
      "-jsDWEBGPU_DEBUG=1",
      "-sUSE_OFFSET_CONVERTER",
      "-sASSERTIONS=2",
      "-sSTACK_OVERFLOW_CHECK=2",
      "-sRUNTIME_DEBUG",
      "--cpuprofiler",
      "--memoryprofiler",
      "--threadprofiler",
      "--profiling",
      "--profiling-funcs",
      "--tracing",

      "-sEXPORT_ALL=1",
      "-sEXPORT_BINDINGS=1",
      "-sAUTO_JS_LIBRARIES=0",

      // // Extras, Unstable
      //"-sSTB_IMAGE=1",
      // "-sLZ4",
      //"-sMINIMAL_RUNTIME=2",
      "-sABORTING_MALLOC=0",
      "-sTOTAL_STACK=16KB",
      "-sINITIAL_MEMORY=128KB",
      "-sALLOW_MEMORY_GROWTH=1",
      "-Wno-pthreads-mem-growth",

      //"-sDISABLE_EXCEPTION_THROWING=1"
      //"-sTEXTDECODER=2",
      //"--closure", "2",
      //"-sMEMORY64=1",
      //"-sSHARED_MEMORY",
      //"-sRELOCATABLE=1",
      //"-sASYNCIFY", Can build and run async, but break Module.onRuntimeInitialized.

      //"-sVERBOSE=1",
      // "--check", ? output nothing

      // auto-run webserver
      //"--emrun"
    });
  }

  // Lineup steps queue
  b.getInstallStep().dependOn(&lib.step);
  emcc_cmd.step.dependOn(&lib.step);
  b.getInstallStep().dependOn(&emcc_cmd.step);
}

fn generateBase64(lib_dir: []const u8, filename: []const u8, extension: []const u8) !void {
  const allocator = std.heap.page_allocator;

  const openfile = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/{s}.{s}", .{ lib_dir, filename, extension });
  const infile = try std.fs.cwd().openFile(openfile, .{ });
  defer infile.close();
  const infileSize = try infile.getEndPos();
  const inbuffer = try allocator.alloc(u8, infileSize);
  defer allocator.free(inbuffer);
  _ = try infile.readAll(inbuffer);

  const base64 = std.base64;
  const base64_encoder = base64.Base64Encoder.init(base64.standard_alphabet_chars, null);
  
  const outbuffer = try std.heap.page_allocator.alloc(u8, base64_encoder.calcSize(infileSize));
  defer std.heap.page_allocator.free(outbuffer);
  _ = base64_encoder.encode(outbuffer, inbuffer);

  const createfile = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/{s}.base64", .{ lib_dir, filename });  
  const outfile = try std.fs.cwd().createFile(createfile, .{ });
  defer outfile.close();
  try outfile.writeAll(outbuffer);

}

fn fileExist(file_path: []const u8) bool {
  const file = std.fs.cwd().openFile(file_path, .{}) catch |err| switch (err) {
    error.FileNotFound => return false,
    else => return false,
  };
  file.close();
  return true;
}

fn runExtras() void {
  // Generate Base64
  // if (FileExist(b.fmt("{s}/{s}", .{ b.lib_dir, "libWebGPU.a" }))) {
  //   try GenerateBase64(b.lib_dir, "libWebGPU", "a");
  // }
  // if (FileExist(b.fmt("{s}/{s}", .{ b.exe_dir, "WebGPU.wasm" }))) {
  //   try GenerateBase64(b.exe_dir, "WebGPU", "wasm");
  // }

  // Start emrun local webserver
  //const emrun = b.addSystemCommand(&.{ b.fmt("{s}{s}", .{ emsdk_path, "/upstream/emscripten/emrun.bat" }), "WebGPU.html" });
  //emrun.setCwd(.{ .cwd_relative = b.lib_dir });
  //b.getInstallStep().dependOn(&emrun.step);

  // Start webserver    
  // const webserver = b.addSystemCommand(&.{ "python" });
  // webserver.setCwd(.{ .cwd_relative = b.lib_dir });
  // webserver.addArgs(&[_][]const u8{
  //   "-m",
  //   "http.server",
  // });
  // b.getInstallStep().dependOn(&webserver.step);
}

fn copyToBuildFolder(b: *std.Build, optimize: std.builtin.OptimizeMode) !void {
  const path: []u8 = current_path;
  const optimize_string: []const u8 = switch (optimize) {
    .Debug =>  "Debug",
    .ReleaseSafe => "ReleaseSafe",
    .ReleaseFast => "ReleaseFast",
    .ReleaseSmall => "ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  };
  try std.fs.cwd().makePath("build");  
  const build_wasm_cmd = b.addSystemCommand(&.{ "CMD", "/C", 
    b.fmt("COPY /Y {s} {s}>nul", .{
      b.fmt("{s}\\bin\\shared\\{s}\\" ++ projectname ++ "_Shared.html", .{ path, optimize_string}),
      b.fmt("{s}\\build\\" ++ projectname ++ "_Shared.html", .{ path }),
    }),
  });
  const build_webgpu_cmd = b.addSystemCommand(&.{ "CMD", "/C", 
    b.fmt("COPY /Y {s} {s}>nul", .{
      b.fmt("{s}\\bin\\web\\{s}\\" ++ projectname ++ ".html", .{ path, optimize_string}),
      b.fmt("{s}\\build\\" ++ projectname ++ ".html", .{ path }),
    }),
  });
  const build_windows_cmd = b.addSystemCommand(&.{ "CMD", "/C", 
    b.fmt("COPY /Y {s} {s}>nul", .{
      b.fmt("{s}\\bin\\windows\\{s}\\" ++ projectname ++ ".exe", .{ path, optimize_string}),
      b.fmt("{s}\\build\\" ++ projectname ++ ".exe", .{ path }),
    }),
  });
  const build_glfw_cmd = b.addSystemCommand(&.{ "CMD", "/C", 
    b.fmt("COPY /Y {s} {s}>nul", .{
      b.fmt("{s}\\bin\\windows\\{s}\\SDL2.dll", .{ path, optimize_string}),
      b.fmt("{s}\\build\\SDL2.dll", .{ path }),
    }),
  });
  const build_dawn_cmd = b.addSystemCommand(&.{ "CMD", "/C", 
    b.fmt("COPY /Y {s} {s}>nul", .{
      b.fmt("{s}\\bin\\windows\\{s}\\webgpu_dawn.dll", .{ path, optimize_string}),
      b.fmt("{s}\\build\\webgpu_dawn.dll", .{ path }),
    }),
  });

  // TODO: FIX HERE!
  // ERROR: BUILD folder only copy HTML files from previous build.
  // CAUSE: Step.dependOn are not waiting for emmcc.bat background async compiler
  //        and trigger steps below before emcc finishes.
  if (fileExist(b.fmt("{s}\\bin\\shared\\{s}\\" ++ projectname ++ "_Shared.html", .{ path, optimize_string}))) 
    b.getInstallStep().dependOn(&build_wasm_cmd.step);
  if (fileExist(b.fmt("{s}\\bin\\web\\{s}\\" ++ projectname ++ ".html", .{ path, optimize_string}))) 
    b.getInstallStep().dependOn(&build_webgpu_cmd.step);
  if (fileExist(b.fmt("{s}\\bin\\windows\\{s}\\" ++ projectname ++ ".exe", .{ path, optimize_string}))) 
    b.getInstallStep().dependOn(&build_windows_cmd.step);
  if (fileExist(b.fmt("{s}\\bin\\windows\\{s}\\SDL2.dll", .{ path, optimize_string}))) 
    b.getInstallStep().dependOn(&build_glfw_cmd.step);
  if (fileExist(b.fmt("{s}\\bin\\windows\\{s}\\webgpu_dawn.dll", .{ path, optimize_string}))) 
    b.getInstallStep().dependOn(&build_dawn_cmd.step);
}

fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}
