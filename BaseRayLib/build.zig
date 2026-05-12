//!zig-autodoc-section: Base.Build
//! Base\\build.zig :
//!   Build Template for a console program.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const builtin = @import("builtin");

const projectname: []const u8 = "BaseRayLib";
var current_path: []u8 = undefined;
var build_context: *std.Build = undefined;
var emscripten_sdk_path: []const u8 = "";  //"C:/emscripten/emsdk/upstream/emscripten/";
var emscripten_include_path: []const u8 = ""; //emscripten_sdk_path ++ "cache/sysroot/include/";

// const web_exports = &.{ }; // Functions that are called by HTML JS

const targets: []const std.Target.Query = &.{
  .{ .cpu_arch = .x86_64, .os_tag = .windows },
  .{ .cpu_arch = .wasm32, .os_tag = .emscripten },
};

fn fmt(comptime format: []const u8, args: anytype) []u8 {
  return build_context.fmt(format, args);
}

//#endregion ==================================================================
//#region MARK: build
//=============================================================================
pub fn build(b: *std.Build) !void {
  const optimize = b.standardOptimizeOption(.{});
  // current_path = std.process.currentPathAlloc(std.heap.page_allocator, ".") catch unreachable;
  // defer std.heap.page_allocator.free(current_path);
  current_path = @constCast(b.build_root.path orelse ".");
  build_context = b;

  for (targets) |t| {
    const target = b.resolveTargetQuery(t);
    switch (t.os_tag.?) {
      .windows => { buildWindows(b, target, optimize); },
      .emscripten => { 
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

//#endregion ==================================================================
//#region MARK: buildWindows
//=============================================================================
pub fn buildWindows(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
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

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug/Windows",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe/Windows",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast/Windows",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall/Windows"
    //else  =>  b.exe_dir = "bin/Else",
  }

  exe.root_module.addWin32ResourceFile(.{
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.root_module.addIncludePath( b.path(".") );
  exe.root_module.addIncludePath( b.path("lib/raylib/include") );
  exe.root_module.addIncludePath( b.path("lib/raylib") );
  exe.root_module.addLibraryPath( b.path("lib/raylib") );
  exe.root_module.linkSystemLibrary("raylib", .{ .preferred_link_mode = .static, });  // .dynamic to use with a .dll 
  exe.root_module.linkSystemLibrary("winmm", .{});
  exe.root_module.linkSystemLibrary("gdi32", .{});
  exe.root_module.linkSystemLibrary("opengl32", .{});
  //b.installBinFile("lib/raylib/raylib.dll", "raylib.dll");

  // RayGUI
  const c_srcs = .{
    "lib/raylib/include/raygui.c",
  };
  inline for (c_srcs) |c_cpp| {
    exe.root_module.addCSourceFile(.{
      .file  = b.path(c_cpp), 
      .flags = &.{ }
    });
  }

  b.installArtifact(exe);
}

//#endregion ==================================================================
//#region MARK: buildHTML
//=============================================================================
pub fn buildHTML(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
  const mainfile = "main.zig";

  const lib = b.addLibrary(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target = target,
      .optimize = optimize,
      .link_libc = true,
    }),
  });

  const std_options = b.addOptions();
  std_options.addOption(std.log.Level, "log_level", .info);
  lib.root_module.addOptions("std_options", std_options);

  lib.root_module.addCMacro("PLATFORM_WEB", "");
  lib.root_module.addCMacro("GRAPHICS_API_OPENGL_ES3", "");
  lib.root_module.addCMacro("deprecated", "");
  lib.root_module.addCMacro("__attribute__(x)", "");

  switch (optimize) {
    .Debug => { 
      b.lib_dir = "bin/Debug/web"; 
      std.debug.print("NOTE: emscripten Debug Build is broken in 0.16, only Release builds are working", .{});
    },
    .ReleaseSafe =>  b.lib_dir = "bin/ReleaseSafe/web",
    .ReleaseFast =>  b.lib_dir = "bin/ReleaseFast/web",
    .ReleaseSmall =>  b.lib_dir = "bin/ReleaseSmall/web"
  }

  // lib.linkLibC();
  lib.root_module.addIncludePath( b.path(".") );
  lib.root_module.addIncludePath( b.path("lib/raylib/include") );
  lib.root_module.addIncludePath( .{ .cwd_relative = emscripten_include_path } );
  lib.root_module.addLibraryPath( b.path("lib/raylib"));
  lib.root_module.addLibraryPath( b.path("lib/raylib/emscripten"));
  //lib.linkSystemLibrary("raylib");

  b.installArtifact(lib);

  // Emscripten - Build HTML, JS, WASM
  const emsdk_env = b.fmt("{s}/../../emsdk_env.bat", .{emscripten_sdk_path});
  const emcc_path  = b.fmt("{s}/emcc.bat", .{emscripten_sdk_path});

  const wasm_cmd = b.addSystemCommand(&.{ "cmd.exe", "/c" });
  wasm_cmd.addArg("set");
  wasm_cmd.addArg("EMSDK_QUIET=1");
  wasm_cmd.addArg("&&");
  wasm_cmd.addArg("call");
  wasm_cmd.addArg(emsdk_env);
  wasm_cmd.addArg("&&");
  wasm_cmd.addArg("call");
  wasm_cmd.addArg(emcc_path);

  wasm_cmd.addFileArg(lib.getEmittedBin());
  // if (optimize == .Debug) {  
  //   wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/libraylib.debug.a"));
  // } else { 
    wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/libraylib.a"));
  // }
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rcore.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/utils.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/raudio.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rmodels.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rshapes.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rtext.o") );
  // wasm_cmd.addFileArg(b.path("lib/raylib/emscripten/rtextures.o") );

  wasm_cmd.addArg("-o");
  wasm_cmd.addArg(b.fmt("{s}/{s}.html", .{ b.lib_dir, projectname }));
  wasm_cmd.addArg("-Os");
  wasm_cmd.addArg("-Wall");
  wasm_cmd.addArg("-I.");
  wasm_cmd.addArg("-Ilib/raylib/include");
  wasm_cmd.addArg("-L.");
  wasm_cmd.addArg("-Llib/raylib");
  wasm_cmd.addArgs(&.{
    "-sWASM=1",
    "-sSINGLE_FILE=1",
    "-sUSE_WEBGL2=1",
    "-sUSE_GLFW=3",
    "-sALLOW_MEMORY_GROWTH=1",
  });

  wasm_cmd.step.dependOn(&lib.step);
  b.getInstallStep().dependOn(&wasm_cmd.step);  
}

//#endregion ==================================================================
//#region MARK: getEmsdkPath
//=============================================================================
fn getEmsdkPath(b: *std.Build) bool {
  const run = b.addSystemCommand(&.{"echo"});   // dummy command just to get env map
  const env_map = run.getEnvMap();

  if (env_map.get("EMSDK")) |path| {
    emscripten_sdk_path = b.pathJoin(&.{ path, "upstream/emscripten" });
    emscripten_include_path = b.pathJoin(&.{ emscripten_sdk_path, "cache/sysroot/include" });
    // std.debug.print("EMSDK found: {s}\n", .{emscripten_sdk_path});
    return true;
  }
  std.debug.print("EMSDK environment variable not found\n", .{});
  return false;
}
//#endregion ==================================================================
//=============================================================================