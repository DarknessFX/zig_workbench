//!zig-autodoc-section: BaseFLTK\\main.zig
//!  main.zig :
//!    Template for a program using FLTK (via cFLTK).
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");
const fl = @cImport({
  @cInclude("lib/CFLTK/include/cFl.h");
  @cInclude("lib/CFLTK/include/cFL_button.h");
  @cInclude("lib/CFLTK/include/cFL_image.h");
  @cInclude("lib/CFLTK/include/cFL_widget.h");
  @cInclude("lib/CFLTK/include/cFl_Window.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

pub fn main() !void {
  _ = fl.Fl_init_all();
  _ = fl.Fl_register_images();
  _ = fl.Fl_lock();

  const w = fl.Fl_Window_new(100, 100, 1280, 720, "Zig+FLTK");
  const b = fl.Fl_Button_new(160, 210, 80, 40, "Click me");

  fl.Fl_Window_end(w);
  fl.Fl_Window_show(w);
  fl.Fl_Button_set_callback(b, cb, null);

  _ = fl.Fl_run();
}


//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

export fn cb(w: ?*fl.Fl_Widget, data: ?*anyopaque) callconv(.c) void {
  _ = data;
  fl.Fl_Widget_set_label(w, "Works!");
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " " {
}

//#endregion ==================================================================
//=============================================================================