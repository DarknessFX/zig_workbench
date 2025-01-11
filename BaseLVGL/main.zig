//!zig-autodoc-section: BaseLVGL.Main
//! BaseLVGL//main.zig :
//!   Template using LVGL.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseLVGL/lib/lvgl/lvgl.h");
pub const lv = @cImport({
  @cInclude("lib/lvgl/lvgl.h");
  @cInclude("lib/lvgl_drv/win32drv.h");
});

// NOTE: 
// - Get Demos and Examples folders from https://github.com/lvgl/lvgl 
// - Need to add all .C files for demos or examples to work.
//
// pub const lvexamples = @cImport({
//   @cInclude("lib/lvgl/examples/lv_examples.h");
// });

// pub const lvdemos = @cImport({
//   @cInclude("lib/lvgl/demos/lv_demos.h");
// });


pub fn main() void {
  HideConsole();

  lv.lv_init();

  lv.lv_tick_set_cb(tick_count_callback);

  if (!single_display_mode_initialization()) {
    return;
  }

  //lvdemos.lv_demo_widgets();
  // //lv_demo_benchmark(LV_DEMO_BENCHMARK_MODE_RENDER_AND_DRIVER);

  while (!lv.lv_win32_quit_signal) {
    const time_till_next: u32 = lv.lv_timer_handler();
    lv.Sleep(time_till_next);
  }

}

fn single_display_mode_initialization() bool {
  if (!lv.lv_win32_init(
    lv.GetModuleHandleW(null),
    lv.SW_SHOW,
    800,
    480,
    lv.LoadIconW(lv.GetModuleHandleW(null), null)))
  {
    return false;
  }

  lv.lv_win32_add_all_input_devices_to_group(null);

  return true;
}

fn tick_count_callback() callconv(.C) u32 {
    return lv.GetTickCount();
}

fn HideConsole() void {
  const BUF_TITLE = 1024;
  var hwndFound: lv.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]lv.CHAR = std.mem.zeroes([BUF_TITLE:0]lv.CHAR); 

  _ = lv.GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound = lv.FindWindowA(null, &pszWindowTitle);
  _ = lv.ShowWindow(hwndFound, lv.SW_HIDE);
}