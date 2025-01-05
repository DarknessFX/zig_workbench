//!zig-autodoc-section: BaseSokol\\main.zig
//! main.zig :
//!	  Template using Sokol framework and Dear ImGui.
// Build using Zig 0.13.0

const std = @import("std");
pub extern fn main() void; // Skip Zig Maig in favor of Sokol_Main.

const sk = @cImport({
  @cInclude("sokol_app.h");
  @cInclude("sokol_gfx.h");
  @cInclude("sokol_log.h");
  @cInclude("sokol_glue.h");
  @cInclude("cimgui.h");
  @cInclude("sokol_imgui.h");
});

const state = struct {
  var pass_action: sk.sg_pass_action = undefined;
};

fn init() callconv(.C) void {
  sk.sg_setup(&sk.sg_desc{
    .environment = sk.sglue_environment(),
    .logger = .{ .func = sk.slog_func },
  });
  sk.simgui_setup(&sk.simgui_desc_t{});

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
  sk.simgui_new_frame(&sk.simgui_frame_desc_t{
    .width = sk.sapp_width(),
    .height = sk.sapp_height(),
    .delta_time = sk.sapp_frame_duration(),
    .dpi_scale = sk.sapp_dpi_scale(),
  });

  // UI Code
  sk.igSetNextWindowPos((sk.ImVec2{ .x = 10, .y = 10 }), sk.ImGuiCond_Once);
  sk.igSetNextWindowSize((sk.ImVec2{ .x = 400, .y = 100 }), sk.ImGuiCond_Once);
  _ = sk.igBegin("Hello Dear ImGui!", null, sk.ImGuiWindowFlags_None);
  _ = sk.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, sk.ImGuiColorEditFlags_None);
  sk.igEnd();

  sk.sg_begin_pass(&sk.sg_pass{
    .action = state.pass_action,
    .swapchain = sk.sglue_swapchain(),
  });
  sk.simgui_render();
  sk.sg_end_pass();
  sk.sg_commit();
}

fn cleanup() callconv(.C) void {
  sk.simgui_shutdown();
  sk.sg_shutdown();
}

fn event(ev: [*c]const sk.sapp_event) callconv(.C) void {
  _ = sk.simgui_handle_event(ev);
}

pub export fn sokol_main() sk.sapp_desc {
  return sk.sapp_desc{
    .init_cb = init,
    .frame_cb = frame,
    .cleanup_cb = cleanup,
    .event_cb = event,
    .window_title = "Hello Sokol + Dear ImGui",
    .width = 1280,
    .height = 720,
    .icon = .{ .sokol_default = true },
    .logger = .{ .func = sk.slog_func },
  };
}