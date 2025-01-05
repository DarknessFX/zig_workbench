//!zig-autodoc-section: BaseAllegro\\main.zig
//! main.zig :
//!	  Template using Allegro5.
// Build using Zig 0.13.0

const std = @import("std");
const all = @cImport({
// Necessary to fix :
// error: cannot combine with previous 
//   'long long' declaration specifier
//   __MINGW_EXTENSION typedef long long  int64_t;  
  @cDefine("_MSC_VER", "1935");  // Visual Studio 2022 17.5

  @cInclude("allegro5/allegro.h");
  @cInclude("allegro5/allegro_primitives.h");
});

pub fn main() void {
  var display: ?*all.ALLEGRO_DISPLAY = null;
  var event_queue: ?*all.ALLEGRO_EVENT_QUEUE = null;
  var running: bool = true;

  // Initialize Allegro
  if (!all.al_init()) {
    std.debug.print("failed to initialize allegro!\n", .{});
    return;
  }

  // Initialize primitives addon
  if (!all.al_init_primitives_addon()) {
    std.debug.print("Failed to initialize primitives addon!\n", .{});
    return;
  }

  // Create display
  display = all.al_create_display(640, 480);
  if (display == null) {
    std.debug.print("failed to create display!\n", .{});
    return;
  }

  // Create event queue
  event_queue = all.al_create_event_queue();
  if (event_queue == null) {
    std.debug.print("failed to create event_queue!\n", .{});
    all.al_destroy_display(display);
    return;
  }

  // Register event source
  all.al_register_event_source(event_queue, all.al_get_display_event_source(display));

  // Main loop
  while (running) {
    var ev: all.ALLEGRO_EVENT = undefined;
    all.al_wait_for_event(event_queue, &ev);

    if (ev.type == all.ALLEGRO_EVENT_DISPLAY_CLOSE) {
      running = false;
    }

    // Clear to black
    all.al_clear_to_color(all.al_map_rgb(0, 0, 0));

    // FAILING: I can only see the red rectangle while closing the screen...
    // Draw a rectangle (for example)
    const xpos: c_int = 320 * @as(c_int, @intFromFloat(std.math.sin(1.0)));
    const ypos: c_int = 240 * @as(c_int, @intFromFloat(std.math.cos(1.0)));
    all.al_draw_filled_rectangle(xpos, ypos, 300 - xpos, 300 - ypos, all.al_map_rgb(255, 0, 0));

    // Flip buffers
    all.al_flip_display();
    all.al_rest(0.005);
  }

  // Clean up
  all.al_destroy_display(display);
  all.al_destroy_event_queue(event_queue);
}