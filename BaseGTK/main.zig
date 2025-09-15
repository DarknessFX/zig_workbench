//!zig-autodoc-section: BaseGTK\\main.zig
//!  main.zig :
//!  Template for aprogram using GTK4 UI.
// Build using Zig 0.15.1

// NOTE: Read lib/GTK/ReadMe.md before start.
const std = @import("std");
const gtk = @cImport({
  @cInclude("gtk.h");
});
const GtkCallback = ?*const fn() callconv(.c) void;

pub fn main() !void {
  var app: *gtk.GtkApplication = gtk.gtk_application_new("org.example.hello", gtk.G_APPLICATION_FLAGS_NONE);
  const gapp: *gtk.GApplication = @as(*gtk.GApplication, @ptrCast(app));

  _ = gtk.g_signal_connect_data(app,"activate", 
    @as(GtkCallback, @ptrCast(&activate)), null, null, 0);

  const status = gtk.g_application_run(gapp, 0, null);
  defer gtk.g_object_unref(@as(?*anyopaque, @ptrCast(&app)));

  std.process.exit(@as(u8, @intCast(status)));
}

fn activate(app: ?*gtk.GtkApplication, data: ?*anyopaque) callconv(.c) void {
  _ = data;

  const window = gtk.gtk_application_window_new(app);
  const gwindow = @as([*c]gtk.GtkWindow, @ptrCast(window));

  gtk.gtk_window_set_title(gwindow, "Hello Zig + GTK4!");
  gtk.gtk_window_set_default_size(gwindow, 1280, 720);

  const button = gtk.gtk_button_new_with_label("Click me!");
  _ = gtk.g_signal_connect_data(
    button,
    "clicked",
    @as(GtkCallback, @ptrCast(&button_clicked)),
    null,
    null,
    0,
  );

  gtk.gtk_window_set_child(gwindow, button);
  gtk.gtk_widget_show(window);
}

fn button_clicked(widget: ?*gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
  _ = widget;
  _ = data;
  std.debug.print("Button clicked!\n", .{});
}
