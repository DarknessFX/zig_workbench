const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseImGui";
  const rootfile = "main.zig";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_source_file = b.path(rootfile),
    .target = target,
    .optimize = optimize,
  });
  exe.addWin32ResourceFile(.{
    .file  = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });

  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("dwmapi");
  exe.linkSystemLibrary("opengl32");
  exe.linkSystemLibrary("SDL3");

  exe.addIncludePath( b.path("lib/imgui") );
  exe.addIncludePath( b.path("lib/SDL3/include") );
  exe.addIncludePath( b.path("lib/opengl") );

  exe.addLibraryPath( b.path("lib/SDL3") );

  const c_srcs = .{
    "lib/imgui/cimgui.cpp",
    "lib/imgui/cimgui_impl_sdl3.cpp",
    "lib/imgui/cimgui_impl_opengl3.cpp",
    "lib/imgui/cimgui_memory_editor.cpp",
    "lib/imgui/imgui.cpp",
    "lib/imgui/imgui_widgets.cpp",
    "lib/imgui/imgui_draw.cpp",
    "lib/imgui/imgui_tables.cpp",
    "lib/imgui/imgui_demo.cpp",
    "lib/imgui/imgui_impl_sdl3.cpp",
    "lib/imgui/imgui_impl_opengl3.cpp"
  };
  inline for (c_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file  = b.path(c_cpp), 
      .flags = &.{ }
    });
  }
  
  b.installBinFile("lib/SDL3/SDL3.dll", "SDL3.dll");
  exe.linkLibCpp();

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall",
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
