//!zig-autodoc-section: BaseClay
//!  Template using Clay UI and RayLib.
//!  Credits:
//!    Clay from nicbarker - https://github.com/nicbarker/clay
//!    Clay-zig binding from johan0A - https://github.com/johan0A/clay-zig-bindings
// Build using Zig 0.15.1

const std = @import("std");
const cl = @import("lib/zClay/zclay.zig");
const renderer = @import("lib/zClay/raylib_render_clay.zig");
const rl = renderer.rl;

const light_grey: cl.Color = .{ 224, 215, 210, 255 };
const red: cl.Color = .{ 168, 66, 28, 255 };
const orange: cl.Color = .{ 225, 138, 50, 255 };
const white: cl.Color = .{ 250, 250, 255, 255 };

const sidebar_item_layout: cl.LayoutConfig = .{ .sizing = .{ .w = .grow, .h = .fixed(50) } };

// Re-useable components are just normal functions
fn sidebarItemComponent(index: u32) void {
  cl.UI()(.{
    .id = .IDI("SidebarBlob", index),
    .layout = sidebar_item_layout,
    .background_color = orange,
  })({});
}

// An example function to begin the "root" of your layout tree
fn createLayout(profile_picture: *const rl.Texture2D) []cl.RenderCommand {
  cl.beginLayout();
  cl.UI()(.{
    .id = .ID("OuterContainer"),
    .layout = .{ .direction = .left_to_right, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
    .background_color = white,
  })({
    cl.UI()(.{
      .id = .ID("SideBar"),
      .layout = .{
        .direction = .top_to_bottom,
        .sizing = .{ .h = .grow, .w = .fixed(300) },
        .padding = .all(16),
        .child_alignment = .{ .x = .center, .y = .top },
        .child_gap = 16,
      },
      .background_color = light_grey,
    })({
      cl.UI()(.{
        .id = .ID("ProfilePictureOuter"),
        .layout = .{ .sizing = .{ .w = .grow }, .padding = .all(16), .child_alignment = .{ .x = .left, .y = .center }, .child_gap = 16 },
        .background_color = red,
      })({
        cl.UI()(.{
          .id = .ID("ProfilePicture"),
          .layout = .{ .sizing = .{ .h = .fixed(60), .w = .fixed(60) } },
          .aspect_ratio = .{ .aspect_ratio = 60 / 60 },
          .image = .{ .image_data = @ptrCast(profile_picture) },
        })({});
        cl.text("Clay - UI Library", .{ .font_size = 24, .color = light_grey });
      });

      for (0..5) |i| sidebarItemComponent(@intCast(i));
    });

    cl.UI()(.{
      .id = .ID("MainContent"),
      .layout = .{ .sizing = .grow },
      .background_color = light_grey,
    })({
      //...
    });
  });
  return cl.endLayout();
}

fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) !void {
  renderer.raylib_fonts[font_id] = rl.LoadFontFromMemory(".ttf", file_data.?.ptr, @as(c_int, @intCast(file_data.?.len)), font_size * 2, null, 0);
  rl.SetTextureFilter(renderer.raylib_fonts[font_id].?.texture, rl.TEXTURE_FILTER_BILINEAR);
}

fn loadImage(comptime path: [:0]const u8) !rl.Texture2D {
  const file_data = @embedFile(path);
  const texture = rl.LoadTextureFromImage(rl.LoadImageFromMemory(@ptrCast(std.fs.path.extension(path)), file_data.ptr, file_data.len));
  rl.SetTextureFilter(texture, rl.TEXTURE_FILTER_BILINEAR);
  return texture;
}

pub fn main() !void {
  const allocator = std.heap.page_allocator;

  // init clay
  const min_memory_size: u32 = cl.minMemorySize();
  const memory = try allocator.alloc(u8, min_memory_size);
  defer allocator.free(memory);
  const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
  _ = cl.initialize(arena, .{ .h = 720, .w = 1280 }, .{});
  cl.setMeasureTextFunction(void, {}, renderer.measureText);

  // init raylib
  rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_WINDOW_RESIZABLE);
  rl.InitWindow(1280, 720, "Clay+Raylib zig Example");
  rl.SetTargetFPS(60);

  // load assets
  try loadFont(@embedFile("./asset/Roboto-Regular.ttf"), 0, 24);
  const profile_picture = try loadImage("./asset/profile-picture.png");

  var debug_mode_enabled = false;
  while (!rl.WindowShouldClose()) {
    if (rl.IsKeyPressed(rl.KEY_D)) {
      debug_mode_enabled = !debug_mode_enabled;
      cl.setDebugModeEnabled(debug_mode_enabled);
    }

    const mouse_pos = rl.GetMousePosition();
    cl.setPointerState(.{
      .x = mouse_pos.x,
      .y = mouse_pos.y,
    }, rl.IsMouseButtonDown(rl.KEY_LEFT));

    var scroll_delta = rl.GetMouseWheelMoveV();
    scroll_delta = .{ 
      .x = scroll_delta.x * 6, 
      .y = scroll_delta.y * 6, };
    cl.updateScrollContainers(
      false,
      .{ .x = scroll_delta.x, .y = scroll_delta.y },
      rl.GetFrameTime(),
    );

    cl.setLayoutDimensions(.{
      .w = @floatFromInt(rl.GetScreenWidth()),
      .h = @floatFromInt(rl.GetScreenHeight()),
    });
    const render_commands = createLayout(&profile_picture);

    rl.BeginDrawing();
    try renderer.clayRaylibRender(render_commands, allocator);
    rl.EndDrawing();
  }
}
