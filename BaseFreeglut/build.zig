const std = @import("std");

pub fn build(b: *std.Build) void {
  //Build
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const projectname = "BaseFreeglut";
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
    //else  =>  b.exe_dir = "bin/Else",
  }

  const c_srcs = .{
    "lib/freeglut/src/fg_callbacks.c",
    "lib/freeglut/src/fg_cursor.c",
    "lib/freeglut/src/fg_display.c",
    "lib/freeglut/src/fg_ext.c",
    "lib/freeglut/src/fg_font.c",
    "lib/freeglut/src/fg_font_data.c",
    "lib/freeglut/src/fg_gamemode.c",
    "lib/freeglut/src/fg_geometry.c",
    "lib/freeglut/src/fg_gl2.c",
    "lib/freeglut/src/fg_init.c",
    "lib/freeglut/src/fg_input_devices.c",
    "lib/freeglut/src/fg_joystick.c",
    "lib/freeglut/src/fg_main.c",
    "lib/freeglut/src/fg_menu.c",
    "lib/freeglut/src/fg_misc.c",
    "lib/freeglut/src/fg_overlay.c",
    "lib/freeglut/src/fg_spaceball.c",
    "lib/freeglut/src/fg_state.c",
    "lib/freeglut/src/fg_stroke_mono_roman.c",
    "lib/freeglut/src/fg_stroke_roman.c",
    "lib/freeglut/src/fg_structure.c",
    "lib/freeglut/src/fg_teapot.c",
    "lib/freeglut/src/fg_videoresize.c",
    "lib/freeglut/src/fg_window.c",
    //"lib/freeglut/src/gles_stubs.c",
    "lib/freeglut/src/mswin/fg_cmap_mswin.c",
    "lib/freeglut/src/mswin/fg_cursor_mswin.c",
    "lib/freeglut/src/mswin/fg_display_mswin.c",
    "lib/freeglut/src/mswin/fg_ext_mswin.c",
    "lib/freeglut/src/mswin/fg_gamemode_mswin.c",
    "lib/freeglut/src/mswin/fg_init_mswin.c",
    "lib/freeglut/src/mswin/fg_input_devices_mswin.c",
    "lib/freeglut/src/mswin/fg_joystick_mswin.c",
    "lib/freeglut/src/mswin/fg_main_mswin.c",
    "lib/freeglut/src/mswin/fg_menu_mswin.c",
    "lib/freeglut/src/mswin/fg_spaceball_mswin.c",
    "lib/freeglut/src/mswin/fg_state_mswin.c",
    "lib/freeglut/src/mswin/fg_structure_mswin.c",
    "lib/freeglut/src/mswin/fg_window_mswin.c",
    "lib/freeglut/src/util/xparsegeometry_repl.c", 
  };
  inline for (c_srcs) |c_cpp| {
    exe.addCSourceFile(.{
      .file = b.path(c_cpp), 
      .flags = &.{ 
        "-DFREEGLUT_STATIC", 
        "-DTARGET_HOST_MS_WINDOWS",
        "-DHAVE_SYS_TYPES_H", 
        "-DHAVE_STDBOOL_H", 
        "-DHAVE_STDINT_H",        
      }
    });
  }

  exe.addIncludePath( b.path(".") );
  exe.addIncludePath( b.path("lib/freeglut") );
  exe.addIncludePath( b.path("lib/freeglut/include") );

  exe.linkSystemLibrary("opengl32");
  exe.linkSystemLibrary("gdi32");
  exe.linkSystemLibrary("winmm");

  // Link libc
  exe.linkLibC();


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