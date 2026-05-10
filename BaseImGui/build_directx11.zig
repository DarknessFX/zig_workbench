//!zig-autodoc-section: BaseImGui.Build
//! BaseImGui//build.zig :
//!   Build Template using Dear ImGui with DirectX11 renderer.
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

  const projectname = "BaseImGui";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
      .link_libcpp = true,
    }),
  });
  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall",
    //else  =>  b.exe_dir = "bin/Else",
  }

  exe.root_module.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.root_module.linkSystemLibrary("gdi32", .{});
  exe.root_module.linkSystemLibrary("dwmapi", .{});
  exe.root_module.linkSystemLibrary("d3d11", .{});
  exe.root_module.linkSystemLibrary("d3dcompiler_47", .{});

  exe.root_module.addIncludePath( b.path("lib/imgui") );
  exe.root_module.addIncludePath( b.path("lib/DX11") );

  const c_srcs = .{
    "lib/imgui/dcimgui.cpp",
    "lib/imgui/dcimgui_impl_dx11.cpp",
    "lib/imgui/dcimgui_impl_win32.cpp",
    "lib/imgui/dcimgui_memory_editor.cpp",
    "lib/imgui/imgui.cpp",
    "lib/imgui/imgui_widgets.cpp",
    "lib/imgui/imgui_draw.cpp",
    "lib/imgui/imgui_tables.cpp",
    "lib/imgui/imgui_demo.cpp",
    "lib/imgui/imgui_impl_dx11.cpp",
    "lib/imgui/imgui_impl_win32.cpp"
  };
  inline for (c_srcs) |c_cpp| {
    exe.root_module.addCSourceFile(.{
      .file = b.path(c_cpp), 
      .flags = &.{ }
    });
  }

  b.installArtifact(exe);

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
      .root_source_file = b.path(rootfile),
      .target = target,
      .optimize = optimize,
      .link_libcpp = true,
    }),
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
//#endregion ==================================================================
//=============================================================================