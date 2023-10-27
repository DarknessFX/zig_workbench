pub const mu = @cImport({
  @cInclude("microui.h");
});

pub extern fn strcat([*c]u8, [*c]const u8) [*c]u8;
pub extern fn sprintf(__stream: [*c]u8, __format: [*c]const u8, ...) c_int;

pub var logbuf: [64000]u8 = @import("std").mem.zeroes([64000]u8);
pub var logbuf_updated: c_int = 0;
pub var bg: [3]f32 = [3]f32{ 90, 95, 100, };

pub fn present(ctx: *mu.mu_Context) void {
  mu.mu_begin(ctx);
  style_window(ctx);
  log_window(ctx);
  test_window(ctx);
  mu.mu_end(ctx);
}

fn style_window(ctx: *mu.mu_Context) void {
  const s_colors = extern struct {
      label: [*c]const u8,
      idx: c_int,
  };

  var colors: [14]s_colors = undefined;
  colors[0]  = .{ .label="text:",         .idx=mu.MU_COLOR_TEXT        };
  colors[1]  = .{ .label="border:",       .idx=mu.MU_COLOR_BORDER      };
  colors[2]  = .{ .label="windowbg:",     .idx=mu.MU_COLOR_WINDOWBG    };
  colors[3]  = .{ .label="titlebg:",      .idx=mu.MU_COLOR_TITLEBG     };
  colors[4]  = .{ .label="titletext:",    .idx=mu.MU_COLOR_TITLETEXT   };
  colors[5]  = .{ .label="panelbg:",      .idx=mu.MU_COLOR_PANELBG     };
  colors[6]  = .{ .label="button:",       .idx=mu.MU_COLOR_BUTTON      };
  colors[7]  = .{ .label="buttonhover:",  .idx=mu.MU_COLOR_BUTTONHOVER };
  colors[8]  = .{ .label="buttonfocus:",  .idx=mu.MU_COLOR_BUTTONFOCUS };
  colors[9]  = .{ .label="base:",         .idx=mu.MU_COLOR_BASE        };
  colors[10] = .{ .label="basehover:",    .idx=mu.MU_COLOR_BASEHOVER   };
  colors[11] = .{ .label="basefocus:",    .idx=mu.MU_COLOR_BASEFOCUS   };
  colors[12] = .{ .label="scrollbase:",   .idx=mu.MU_COLOR_SCROLLBASE  };
  colors[13] = .{ .label="scrollthumb:",  .idx=mu.MU_COLOR_SCROLLTHUMB };

  if (mu.mu_begin_window(ctx, "Style Editor", mu.mu_rect(350, 250, 300, 240)) != 0) {
    //var bctx = mu.mu_get_current_container(ctx).*;
    //var sw: c_int = @as(c_int, @intFromFloat(@as(f32, @floatFromInt(bctx.body.w)) * 0.14));
    //var lrow = @as([*c]c_int, @ptrCast(@constCast(&.{ 80, sw, sw, sw, sw, -1 })));
    const clow: c_int = @as(c_int, 0);
    const chigh: c_int = @as(c_int, 255);
    //mu.mu_layout_row(ctx, 6, lrow, 0);
    var sw: c_int = @as(c_int, @intFromFloat(@as(f64, @floatFromInt(mu.mu_get_current_container(ctx).*.body.w)) * 0.14));
    mu.mu_layout_row(ctx, @as(c_int, 6), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([6]c_int{
        80, sw, sw, sw, sw, -@as(c_int, 1), }))))), @as(c_int, 0));
    for (colors, 0..) |sc, i| {
      mu.mu_label(ctx, sc.label);
      _ = slider(ctx, &ctx.*.style.*.colors[@as(c_uint, @intCast(i))].r, clow, chigh);
      _ = slider(ctx, &ctx.*.style.*.colors[@as(c_uint, @intCast(i))].g, clow, chigh);
      _ = slider(ctx, &ctx.*.style.*.colors[@as(c_uint, @intCast(i))].b, clow, chigh);
      _ = slider(ctx, &ctx.*.style.*.colors[@as(c_uint, @intCast(i))].a, clow, chigh);
      mu.mu_draw_rect(ctx, mu.mu_layout_next(ctx), ctx.*.style.*.colors[@as(c_uint, @intCast(i))]);
    }
    mu.mu_end_window(ctx);
  }
}

pub fn slider(arg_ctx: [*c]mu.mu_Context, arg_value: [*c]u8, arg_low: c_int, arg_high: c_int) callconv(.C) c_int {
  var ctx = arg_ctx;
  var value = arg_value;
  var low = arg_low;
  var high = arg_high;
  const tmp = struct { var static: f32 = @import("std").mem.zeroes(f32); };
  mu.mu_push_id(ctx, @as(?*const anyopaque, @ptrCast(&value)), @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf([*c]u8))))));
  tmp.static = @as(f32, @floatFromInt(value.*));
  var res: c_int = mu.mu_slider_ex(ctx, &tmp.static, @as(mu.mu_Real, @floatFromInt(low)), @as(mu.mu_Real, 
    @floatFromInt(high)), @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), "%.0f", mu.MU_OPT_ALIGNCENTER);
  value.* = @as(u8, @intFromFloat(tmp.static));
  mu.mu_pop_id(ctx);
  return res;
}

pub fn log_window(arg_ctx: [*c]mu.mu_Context) callconv(.C) void {
  var ctx = arg_ctx;
  if (mu.mu_begin_window_ex(ctx, "Log Window", mu.mu_rect(@as(c_int, 350), @as(c_int, 40), @as(c_int, 300), @as(c_int, 200)), @as(c_int, 0)) != 0) {
    mu.mu_layout_row(ctx, @as(c_int, 1), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([1]c_int{
      -@as(c_int, 1),
    }))))), -@as(c_int, 25));
    mu.mu_begin_panel_ex(ctx, "Log Output", @as(c_int, 0));
    var panel: [*c]mu.mu_Container = mu.mu_get_current_container(ctx);
    mu.mu_layout_row(ctx, @as(c_int, 1), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([1]c_int{
      -@as(c_int, 1),
    }))))), -@as(c_int, 1));
    mu.mu_text(ctx, @as([*c]u8, @constCast(@ptrCast(@alignCast(&logbuf)))));
    mu.mu_end_panel(ctx);
    if (logbuf_updated != 0) {
      panel.*.scroll.y = panel.*.content_size.y;
      logbuf_updated = 0;
    }
    const buf = struct {
      var static: [128]u8 = @import("std").mem.zeroes([128]u8);
    };
    var submitted: c_int = 0;
    mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
      -@as(c_int, 70),
      -@as(c_int, 1),
    }))))), @as(c_int, 0));
    if ((mu.mu_textbox_ex(ctx, @as([*c]u8, @ptrCast(@alignCast(&buf.static))), @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf([128]u8))))), @as(c_int, 0)) & mu.MU_RES_SUBMIT) != 0) {
      mu.mu_set_focus(ctx, ctx.*.last_id);
      submitted = 1;
    }
    if (mu.mu_button_ex(ctx, "Submit", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
      submitted = 1;
    }
    if (submitted != 0) {
      write_log(@as([*c]u8, @ptrCast(@alignCast(&buf.static))));
      buf.static[@as(c_uint, @intCast(@as(c_int, 0)))] = '\x00';
    }
    mu.mu_end_window(ctx);
  }
}

pub fn write_log(arg_text: [*c]const u8) callconv(.C) void {
    var text = arg_text;
    if (logbuf[@as(c_uint, @intCast(@as(c_int, 0)))] != 0) {
        _ = strcat(@as([*c]u8, @ptrCast(@alignCast(&logbuf))), "\n");
    }
    _ = strcat(@as([*c]u8, @ptrCast(@alignCast(&logbuf))), text);
    logbuf_updated = 1;
}

pub fn test_window(arg_ctx: [*c]mu.mu_Context) callconv(.C) void {
    var ctx = arg_ctx;
    if (mu.mu_begin_window_ex(ctx, "Demo Window", mu.mu_rect(@as(c_int, 40), @as(c_int, 40), @as(c_int, 300), @as(c_int, 450)), @as(c_int, 0)) != 0) {
        var win: [*c]mu.mu_Container = mu.mu_get_current_container(ctx);
        win.*.rect.w = if (win.*.rect.w > @as(c_int, 240)) win.*.rect.w else @as(c_int, 240);
        win.*.rect.h = if (win.*.rect.h > @as(c_int, 300)) win.*.rect.h else @as(c_int, 300);
        if (mu.mu_header_ex(ctx, "Window Info", @as(c_int, 0)) != 0) {
            var win_1: [*c]mu.mu_Container = mu.mu_get_current_container(ctx);
            var buf: [64]u8 = undefined;
            mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
                54,
                -@as(c_int, 1),
            }))))), @as(c_int, 0));
            mu.mu_label(ctx, "Position:");
            _ = sprintf(@as([*c]u8, @ptrCast(@alignCast(&buf))), "%d, %d", win_1.*.rect.x, win_1.*.rect.y);
            mu.mu_label(ctx, @as([*c]u8, @ptrCast(@alignCast(&buf))));
            mu.mu_label(ctx, "Size:");
            _ = sprintf(@as([*c]u8, @ptrCast(@alignCast(&buf))), "%d, %d", win_1.*.rect.w, win_1.*.rect.h);
            mu.mu_label(ctx, @as([*c]u8, @ptrCast(@alignCast(&buf))));
        }
        if (mu.mu_header_ex(ctx, "Test Buttons", mu.MU_OPT_EXPANDED) != 0) {
            mu.mu_layout_row(ctx, @as(c_int, 3), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([3]c_int{
                86,
                -@as(c_int, 110),
                -@as(c_int, 1),
            }))))), @as(c_int, 0));
            mu.mu_label(ctx, "Test buttons 1:");
            if (mu.mu_button_ex(ctx, "Button 1", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                write_log("Pressed button 1");
            }
            if (mu.mu_button_ex(ctx, "Button 2", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                write_log("Pressed button 2");
            }
            mu.mu_label(ctx, "Test buttons 2:");
            if (mu.mu_button_ex(ctx, "Button 3", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                write_log("Pressed button 3");
            }
            if (mu.mu_button_ex(ctx, "Popup", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                mu.mu_open_popup(ctx, "Test Popup");
            }
            if (mu.mu_begin_popup(ctx, "Test Popup") != 0) {
                _ = mu.mu_button_ex(ctx, "Hello", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER);
                _ = mu.mu_button_ex(ctx, "World", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER);
                mu.mu_end_popup(ctx);
            }
        }
        if (mu.mu_header_ex(ctx, "Tree and Text", mu.MU_OPT_EXPANDED) != 0) {
            mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
                140,
                -@as(c_int, 1),
            }))))), @as(c_int, 0));
            mu.mu_layout_begin_column(ctx);
            if (mu.mu_begin_treenode_ex(ctx, "Test 1", @as(c_int, 0)) != 0) {
                if (mu.mu_begin_treenode_ex(ctx, "Test 1a", @as(c_int, 0)) != 0) {
                    mu.mu_label(ctx, "Hello");
                    mu.mu_label(ctx, "world");
                    mu.mu_end_treenode(ctx);
                }
                if (mu.mu_begin_treenode_ex(ctx, "Test 1b", @as(c_int, 0)) != 0) {
                    if (mu.mu_button_ex(ctx, "Button 1", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                        write_log("Pressed button 1");
                    }
                    if (mu.mu_button_ex(ctx, "Button 2", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                        write_log("Pressed button 2");
                    }
                    mu.mu_end_treenode(ctx);
                }
                mu.mu_end_treenode(ctx);
            }
            if (mu.mu_begin_treenode_ex(ctx, "Test 2", @as(c_int, 0)) != 0) {
                mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
                    54,
                    54,
                }))))), @as(c_int, 0));
                if (mu.mu_button_ex(ctx, "Button 3", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                    write_log("Pressed button 3");
                }
                if (mu.mu_button_ex(ctx, "Button 4", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                    write_log("Pressed button 4");
                }
                if (mu.mu_button_ex(ctx, "Button 5", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                    write_log("Pressed button 5");
                }
                if (mu.mu_button_ex(ctx, "Button 6", @as(c_int, 0), mu.MU_OPT_ALIGNCENTER) != 0) {
                    write_log("Pressed button 6");
                }
                mu.mu_end_treenode(ctx);
            }
            if (mu.mu_begin_treenode_ex(ctx, "Test 3", @as(c_int, 0)) != 0) {
                const checks = struct {
                    var static: [3]c_int = [3]c_int{
                        1,
                        0,
                        1,
                    };
                };
                _ = mu.mu_checkbox(ctx, "Checkbox 1", &checks.static[@as(c_uint, @intCast(@as(c_int, 0)))]);
                _ = mu.mu_checkbox(ctx, "Checkbox 2", &checks.static[@as(c_uint, @intCast(@as(c_int, 1)))]);
                _ = mu.mu_checkbox(ctx, "Checkbox 3", &checks.static[@as(c_uint, @intCast(@as(c_int, 2)))]);
                mu.mu_end_treenode(ctx);
            }
            mu.mu_layout_end_column(ctx);
            mu.mu_layout_begin_column(ctx);
            mu.mu_layout_row(ctx, @as(c_int, 1), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([1]c_int{
                -@as(c_int, 1),
            }))))), @as(c_int, 0));
            mu.mu_text(ctx, "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus ipsum, eu varius magna felis a nulla.");
            mu.mu_layout_end_column(ctx);
        }
        if (mu.mu_header_ex(ctx, "Background Color", mu.MU_OPT_EXPANDED) != 0) {
            mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
                -@as(c_int, 78),
                -@as(c_int, 1),
            }))))), @as(c_int, 74));
            mu.mu_layout_begin_column(ctx);
            mu.mu_layout_row(ctx, @as(c_int, 2), @as([*c]c_int, @constCast(@ptrCast(@alignCast(&([2]c_int{
                46,
                -@as(c_int, 1),
            }))))), @as(c_int, 0));
            mu.mu_label(ctx, "Red:");
            _ = mu.mu_slider_ex(ctx, &bg[@as(c_uint, @intCast(@as(c_int, 0)))], @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 255))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), "%.2f", mu.MU_OPT_ALIGNCENTER);
            mu.mu_label(ctx, "Green:");
            _ = mu.mu_slider_ex(ctx, &bg[@as(c_uint, @intCast(@as(c_int, 1)))], @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 255))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), "%.2f", mu.MU_OPT_ALIGNCENTER);
            mu.mu_label(ctx, "Blue:");
            _ = mu.mu_slider_ex(ctx, &bg[@as(c_uint, @intCast(@as(c_int, 2)))], @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 255))), @as(mu.mu_Real, @floatFromInt(@as(c_int, 0))), "%.2f", mu.MU_OPT_ALIGNCENTER);
            mu.mu_layout_end_column(ctx);
            var r: mu.mu_Rect = mu.mu_layout_next(ctx);
            mu.mu_draw_rect(ctx, r, mu.mu_color(@as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 0)))])), @as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 1)))])), @as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 2)))])), @as(c_int, 255)));
            var buf: [32]u8 = undefined;
            _ = sprintf(@as([*c]u8, @ptrCast(@alignCast(&buf))), "#%02X%02X%02X", @as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 0)))])), @as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 1)))])), @as(c_int, @intFromFloat(bg[@as(c_uint, @intCast(@as(c_int, 2)))])));
            mu.mu_draw_control_text(ctx, @as([*c]u8, @ptrCast(@alignCast(&buf))), r, mu.MU_COLOR_TEXT, mu.MU_OPT_ALIGNCENTER);
        }
        mu.mu_end_window(ctx);
    }
}