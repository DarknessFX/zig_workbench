//!zig-autodoc-section: BaseSokol\\main.zig
//! main.zig :
//!  Template using Sokol framework and Nuklear UI.
// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
pub extern fn main() void; // Skip Zig Maig in favor of Sokol_Main.

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseSokol/lib/sokol/include/sokol_app.h");
const sk = @cImport({
  @cDefine("SOKOL_GLCORE", "");
  @cInclude("sokol_app.h");
  @cInclude("sokol_gfx.h");
  @cInclude("sokol_log.h");
  @cInclude("sokol_glue.h");
  @cDefine("NK_INCLUDE_FIXED_TYPES", "");
  @cDefine("NK_INCLUDE_STANDARD_IO", "");
  @cDefine("NK_INCLUDE_DEFAULT_ALLOCATOR", "");
  @cDefine("NK_INCLUDE_VERTEX_BUFFER_OUTPUT", "");
  @cDefine("NK_INCLUDE_FONT_BAKING", "");
  @cDefine("NK_INCLUDE_DEFAULT_FONT", "");
  @cDefine("NK_INCLUDE_STANDARD_VARARGS", "");
  @cInclude("nuklear.h");
  @cDefine("SOKOL_NUKLEAR_IMPL", "");
  @cInclude("sokol_nuklear.h");
});

const state = struct {
  var pass_action: sk.sg_pass_action = undefined;
};

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

pub export fn sokol_main() sk.sapp_desc {
  HideConsoleWindow();
  return sk.sapp_desc{
    .init_cb = init,
    .frame_cb = frame,
    .cleanup_cb = cleanup,
    .event_cb = event,
    .window_title = "Hello Sokol + Nuklear UI",
    .width = 1280,
    .height = 720,
    .icon = .{ .sokol_default = true },
    .logger = .{ .func = sk.slog_func },
  };
}

fn init() callconv(.C) void {
  sk.sg_setup(&sk.sg_desc{
    .environment = sk.sglue_environment(),
    .logger = .{ .func = sk.slog_func },
  });

  sk.snk_setup(&sk.snk_desc_t{
    .enable_set_mouse_cursor = true,
    .dpi_scale = sk.sapp_dpi_scale(),
    .logger = .{ .func = sk.slog_func },
  });

  state.pass_action = sk.sg_pass_action{
    .colors = .{
      .{ 
        .load_action = sk.SG_LOADACTION_CLEAR, 
        .clear_value = .{ .r=0.0, .g=0.5, .b=1.0, .a=1.0 }
      }, .{}, .{}, .{},
    },
  };
}

fn frame() callconv(.C) void {
  const ctx: *sk.nk_context = sk.snk_new_frame();
  _ = draw_demo_ui(ctx);

  sk.sg_begin_pass(&sk.sg_pass{
    .action = state.pass_action,
    .swapchain = sk.sglue_swapchain(),
  });
  sk.snk_render(sk.sapp_width(), sk.sapp_height());
  sk.sg_end_pass();
  sk.sg_commit();
}
//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

fn cleanup() callconv(.C) void {
  sk.snk_shutdown();
  sk.sg_shutdown();
}

fn event(ev: [*c]const sk.sapp_event) callconv(.C) void {
  _ = sk.snk_handle_event(ev);
}

// Nuklear
var show_menu: i32 = 1;
var mprog: usize = 60;
var mslider: i32 = 10;
var mcheck: i32 = 1;
var prog: usize = 40;
var slider: i32 = 10;
var check: i32 = 1;

fn draw_demo_ui(ctx: *sk.struct_nk_context) i32 {
  sk.nk_style_hide_cursor(ctx);

  //var titlebar: i32 = 1;
  const border: i32 = 1;
  const resize: i32 = 1;
  const movable: i32 = 1;
  const no_scrollbar: i32 = 0;
  const scale_left: i32 = 0;
  const minimizable: i32 = 1;

  var window_flags: sk.nk_flags = 0;
  if (border != 0) window_flags |= sk.NK_WINDOW_BORDER;
  if (resize != 0) window_flags |= sk.NK_WINDOW_SCALABLE;
  if (movable != 0) window_flags |= sk.NK_WINDOW_MOVABLE;
  if (no_scrollbar != 0) window_flags |= sk.NK_WINDOW_NO_SCROLLBAR;
  if (scale_left != 0) window_flags |= sk.NK_WINDOW_SCALE_LEFT;
  if (minimizable != 0) window_flags |= sk.NK_WINDOW_MINIMIZABLE;

  if (sk.nk_begin(ctx, "Overview", sk.nk_rect(10, 25, 400, 600), window_flags) != 0) {
    if (show_menu != 0) {
      sk.nk_menubar_begin(ctx);

      sk.nk_layout_row_begin(ctx, sk.NK_STATIC, 25, 5);
      sk.nk_layout_row_push(ctx, 45);
      if (sk.nk_menu_begin_label(ctx, "MENU", sk.NK_TEXT_LEFT, sk.nk_vec2(120, 200)) != 0) {
        sk.nk_layout_row_dynamic(ctx, 25, 1);
        if (sk.nk_menu_item_label(ctx, "Hide", sk.NK_TEXT_LEFT) != 0) show_menu = 0;
        _ = sk.nk_progress(ctx, &prog, 100, sk.NK_MODIFIABLE);
        _ = sk.nk_slider_int(ctx, 0, &slider, 16, 1);
        _ = sk.nk_checkbox_label(ctx, "check", &check);
        sk.nk_menu_end(ctx);
      }

      sk.nk_layout_row_push(ctx, 60);
      _ = sk.nk_progress(ctx, &mprog, 100, sk.NK_MODIFIABLE);
      _ = sk.nk_slider_int(ctx, 0, &mslider, 16, 1);
      _ = sk.nk_checkbox_label(ctx, "check", &mcheck);
      sk.nk_menubar_end(ctx);
    }

    sk.nk_end(ctx);
  }
  return if (sk.nk_window_is_closed(ctx, "Overview") != 0) 0 else 1;
}

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================

fn HideConsoleWindow() void {
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);
}

const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
pub extern "kernel32" fn GetConsoleTitleA(
  lpConsoleTitle: win.LPSTR,
  nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

pub extern "kernel32" fn FindWindowA(
  lpClassName: ?win.LPSTR,
  lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;

pub const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: i32
) callconv(win.WINAPI) win.BOOL;

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================