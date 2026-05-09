//!zig-autodoc-section: BaseGTK\\main.zig
//!  main.zig :
//!  Template for aprogram using GTK4 UI.
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

  const projectname = "BaseGTK";
  const mainfile = "main.zig";

  // Edit here with your MSYS2 path
  const msys2_root = "D:/workbench/Zig/_msys64/mingw64";

  const exe = b.addExecutable(.{
    .name = projectname,
    .root_module = b.createModule(.{
      .root_source_file = b.path(mainfile),
      .target =  target,
      .optimize = optimize,
      .link_libc = true,
    }),    
  });
  exe.root_module.addWin32ResourceFile(.{
    .file = b.path(projectname ++ ".rc"),
    .flags = &.{"/c65001"}, // UTF-8 codepage
  });
  
  exe.root_module.addIncludePath( b.path(".") );
  exe.root_module.addIncludePath( b.path("lib/GTK") );

  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/gtk-4.0"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/gtk-4.0/gtk"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/gtk-4.0/gdk"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/gtk-4.0/gsk"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/gdk-pixbuf-2.0"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/graphene-1.0"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/glib-2.0"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/cairo"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/pango-1.0"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/pango-1.0/pango"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "include/harfbuzz"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "lib/glib-2.0/include"}) });
  exe.root_module.addIncludePath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "lib/graphene-1.0/include"}) });

  exe.root_module.addLibraryPath( b.path("lib/GTK") );
  exe.root_module.addLibraryPath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "lib"}) });
  exe.root_module.addLibraryPath( .{ .cwd_relative = b.pathJoin(&.{ msys2_root, "bin"}) });

  exe.root_module.linkSystemLibrary("libgtk-4-1", .{});
  exe.root_module.linkSystemLibrary("libgobject-2.0-0", .{});
  exe.root_module.linkSystemLibrary("libglib-2.0-0", .{});
  exe.root_module.linkSystemLibrary("libgio-2.0-0", .{});
  exe.root_module.linkSystemLibrary("libpango-1.0-0", .{});
  exe.root_module.linkSystemLibrary("libcairo-2", .{});
  exe.root_module.linkSystemLibrary("libgdk_pixbuf-2.0-0", .{});
  exe.root_module.linkSystemLibrary("libintl-8", .{});

  switch (optimize) {
    .Debug =>  b.exe_dir = "bin/Debug",
    .ReleaseSafe =>  b.exe_dir = "bin/ReleaseSafe",
    .ReleaseFast =>  b.exe_dir = "bin/ReleaseFast",
    .ReleaseSmall =>  b.exe_dir = "bin/ReleaseSmall"
    //else  =>  b.exe_dir = "bin/Else",
  }

  // Create Launch.bat, a shorcut to add MSYS2 to your envriment PATH
  const launch_bat_writer = b.addWriteFiles();
  const launch_bat_file = launch_bat_writer.add(
    "Launch.bat",
    b.fmt(
      \\@echo off
      \\SET PATH={s}\\bin;%PATH%
      \\{s}.exe
      \\
      , .{msys2_root, projectname}
    )
  );
  const launch_bat_installed = b.addInstallFileWithDir(launch_bat_file, .bin, "Launch.bat");
  exe.step.dependOn(&launch_bat_writer.step);
  exe.step.dependOn(&launch_bat_installed.step);

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
      .root_source_file = b.path(mainfile),
      .target =  target,
      .optimize = optimize,
      .link_libc = true,
    }),    
  });
  const run_unit_tests = b.addRunArtifact(unit_tests);
  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_unit_tests.step);
}
//#endregion ==================================================================
//=============================================================================