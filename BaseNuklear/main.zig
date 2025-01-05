//!zig-autodoc-section: BaseNuklear.Main
//! BaseNuklear//main.zig :
//!   Template using Nuklear UI.
// Build using Zig 0.13.0

const std = @import("std");
const win = std.os.windows;
pub inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
const nk = @cImport({
  @cDefine("NK_INCLUDE_FIXED_TYPES", "");
  @cDefine("NK_INCLUDE_STANDARD_IO", "");
  @cDefine("NK_INCLUDE_STANDARD_VARARGS", "");
  @cDefine("NK_INCLUDE_DEFAULT_ALLOCATOR", "");
  //@cDefine("NK_IMPLEMENTATION", "");
  @cDefine("NK_GDI_IMPLEMENTATION", "");
  @cInclude("nuklear.h");
  @cInclude("nuklear_gdi.h");
  @cDefine("NKGDI_IMPLEMENT_WINDOW", "");
  @cInclude("window.h");
});

fn drawCallback(ctx: *nk.struct_nk_context) callconv(.C) c_int {
  var set: i32 = 0;
  var prev: i32 = 0;
  var op: i32 = 0;
  const numbers = "789456123";
  const ops = "+-*/";
  var a: f64 = 0;
  var b: f64 = 0;
  var current: *f64 = &a;

  var solve: i32 = 0;

  // Buffer for input
  var buffer: [256]u8 = undefined;
  var len: usize = 0;

  // Input field
  nk.nk_layout_row_dynamic(ctx, 35, 1);
  //len = snprintf(buffer, 256, "%.2f", *current);
  _ = nk.nk_edit_string(ctx, nk.NK_EDIT_SIMPLE, &buffer[0], @ptrCast(&len), buffer.len, nk.nk_filter_float);
  buffer[len] = 0;
  //*current = atof(buffer);}  

  // Layout for buttons
  nk.nk_layout_row_dynamic(ctx, 35, 4);
  var i: usize = 0;
  while (i < 16) : (i += 1) {
    if (i >= 12 and i < 15) {
      if (i > 12) continue;
      if (nk.nk_button_label(ctx, "C") == 1) {
        a = 0;
        b = 0;
        op = 0;
        current = &a;
        set = 0;
      }
      if (nk.nk_button_label(ctx, "0") == 1) {
        current.* *= 10.0;
        set = 0;
      }
      if (nk.nk_button_label(ctx, "=") == 1) {
        solve = 1;
        prev = op;
        op = 0;
      }
    } else if ((i + 1) % 4 != 0) {
      if (nk.nk_button_text(ctx, &numbers[(i / 4) * 3 + i % 4], 1) == 1) {
        current.* = current.* * 10.0 + @as(f64, @floatFromInt(numbers[(i / 4) * 3 + i % 4] - '0'));
        set = 0;
      }
    } else if (nk.nk_button_text(ctx, &ops[i / 4], 1) == 1) {
      if (set == 0) {
        if (current != &b) {
          current = &b;
        } else {
          prev = op;
          solve = 1;
        }
      }
      op = ops[i / 4];
      set = 1;
    }
  }

  // Solve operation
  if (solve != 0) {
    if (prev == '+') a = a + b;
    if (prev == '-') a = a - b;
    if (prev == '*') a = a * b;
    if (prev == '/') a = a / b;

    current = &a;
    if (set != 0) current = &b;
    b = 0;
    set = 0;
  }

  return 1;
}

pub fn wWinMain(
    hInstance: win.HINSTANCE,
    hPrevInstance: ?win.HINSTANCE,
    cmdArgs: win.PWSTR,
    cmdShow: win.INT,
) win.INT {
  _ = hInstance; _ = hPrevInstance; _ = cmdArgs; _ = cmdShow;

  // Setup all required prerequisites
  nk.nkgdi_window_init();

  // Prepare two window contexts
  var w1: nk.struct_nkgdi_window = std.mem.zeroes(nk.struct_nkgdi_window);
  var w2: nk.struct_nkgdi_window = std.mem.zeroes(nk.struct_nkgdi_window);

  // Configure and create window 1
  w1.allow_sizing = 0;
  w1.allow_maximize = 0;
  w1.allow_move = 1;
  w1.has_titlebar = 1;
  w1.cb_on_draw = @ptrCast(&drawCallback);
  nk.nkgdi_window_create(&w1, 500, 500, "F1", 10, 10);

  // Configure and create window 2
  w2.allow_sizing = 1;
  w2.allow_maximize = 1;
  w2.allow_move = 1;
  w2.has_titlebar = 1;
  w2.cb_on_draw = @ptrCast(&drawCallback);
  nk.nkgdi_window_create(&w2, 500, 500, "F2", 520, 10);

  // Update both windows as long as valid
  while (nk.nkgdi_window_update(&w1) != 0 and nk.nkgdi_window_update(&w2) != 0) {
    std.time.sleep(20);
  }

  // Destroy both window contexts
  nk.nkgdi_window_destroy(&w1);
  nk.nkgdi_window_destroy(&w2);

  // Properly shut down the gdi window framework
  nk.nkgdi_window_shutdown();

  return 0;
}

// Fix for libc linking error.
pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(win.WINAPI) win.INT {
  return wWinMain(hInstance, hPrevInstance, pCmdLine.?, nCmdShow);
}
