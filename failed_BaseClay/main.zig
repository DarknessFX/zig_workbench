//!zig-autodoc-section: BaseClay
//!  Template using Clay UI and RayLib renderer.
//!  STATUS: BROKEN/INCOMPLETE , Zig cImport can't handle Clay's macros with variadric arguments (...).
// Build using Zig 0.13.0

const std = @import("std");
inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
inline fn fromcStr(c_str: [*c]const u8) [:0]const u8 { return std.mem.span(c_str); }

const clay = @cImport({
  @cInclude("clay.h");
  @cInclude("raylib.h"); 
  @cInclude("clay_renderer_raylib.c"); 
});

const layoutElement = clay.Clay_LayoutConfig{ .padding = .{ .x = 25, .y = 25 }};
const COLOR_WHITE: clay.Clay_Color = .{ 255, 255, 255, 255};

var profilePicture: clay.Texture2D = undefined;
var raylib_fonts: [2]clay.Raylib_Font = undefined;
const FONT_ID_BODY_24: u32 = 0;
const FONT_ID_BODY_16: u32 = 1;

var reinitializeClay: bool = false;
var rl_width: c_int = 0;
var rl_heigth: c_int = 0;

fn handleClayErrors(errorData: clay.Clay_ErrorData) callconv(.C) void {
  std.debug.print("{s}", .{errorData.errorText.chars});
}

pub fn main() void {
  var totalMemorySize = clay.Clay_MinMemorySize();
  const memAlloc = std.heap.page_allocator.alloc(u8, totalMemorySize) catch unreachable;
  defer std.heap.page_allocator.free(memAlloc);

  var clayMemory = clay.Clay_CreateArenaWithCapacityAndMemory(totalMemorySize, memAlloc.ptr);
  clay.Clay_SetMeasureTextFunction(clay.Raylib_MeasureText);

  rl_width = 1280; //clay.GetScreenWidth();
  rl_heigth = 720; //clay.GetScreenHeight();

  clay.Clay_Initialize(clayMemory,
    clay.Clay_Dimensions{ .width = @floatFromInt(rl_width), .height = @floatFromInt(rl_heigth) }, 
    clay.Clay_ErrorHandler{ .errorHandlerFunction = handleClayErrors });
  clay.Clay_Raylib_Initialize(rl_width, rl_heigth, "Clay - Raylib Renderer Example",
    clay.FLAG_VSYNC_HINT | clay.FLAG_WINDOW_RESIZABLE | 
    clay.FLAG_WINDOW_HIGHDPI | clay.FLAG_MSAA_4X_HINT);

  LoadAssets();

  // Main game loop
  while (!clay.WindowShouldClose()) {    // Detect window close button or ESC key
    if (reinitializeClay) {
      clay.Clay_SetMaxElementCount(8192);
      totalMemorySize = clay.Clay_MinMemorySize();
      clayMemory = clay.Clay_CreateArenaWithCapacityAndMemory(totalMemorySize, memAlloc.ptr);
      clay.Clay_Initialize(clayMemory,
        clay.Clay_Dimensions{  .width = @floatFromInt(rl_width), .height = @floatFromInt(rl_heigth) }, 
        clay.Clay_ErrorHandler{ .errorHandlerFunction = handleClayErrors });
      reinitializeClay = false;
    }
    UpdateDrawFrame();
  }
}

fn UpdateDrawFrame() void {
  clay.Clay_BeginLayout();
  _ = clay.CLAY__2_ARGS(
    clay.Clay_RectangleElementConfig{
      .color = .{ .r=140, .g=140, .b=140, .a=255 },
      .cornerRadius = .{
        .topLeft = 5,
        .topRight = 5,
        .bottomLeft = 5,
        .bottomRight = 5,
      },
    },
    layoutElement);
  const renderCommands = clay.Clay_EndLayout();

  clay.BeginDrawing();
  clay.ClearBackground(clay.BLACK);
  clay.Clay_Raylib_Render(renderCommands);
  clay.EndDrawing();
}

fn LoadAssets() void {
  const path_buf = std.heap.page_allocator.alloc(u8, std.fs.MAX_PATH_BYTES) catch unreachable;
  const path = std.process.getCwd(path_buf) catch unreachable;  
  const texture_path = std.heap.page_allocator.dupeZ(u8, fmt("{s}\\{s}", .{ path, "asset\\texture.png" })) catch unreachable;
  const font_path = std.heap.page_allocator.dupeZ(u8, fmt("{s}\\{s}", .{ path, "asset\\Roboto-Regular.ttf" })) catch unreachable;

  profilePicture = clay.LoadTextureFromImage(clay.LoadImage( texture_path.ptr ));
  raylib_fonts = .{
    .{
        .font = clay.LoadFontEx(font_path, 48, 0, 400),
        .fontId = FONT_ID_BODY_24,
    },
    .{
        .font = clay.LoadFontEx(font_path, 16, 0, 400),
        .fontId = FONT_ID_BODY_16,
    },
  };
  clay.SetTextureFilter(raylib_fonts[FONT_ID_BODY_24].font.texture, clay.TEXTURE_FILTER_BILINEAR);
  clay.SetTextureFilter(raylib_fonts[FONT_ID_BODY_16].font.texture, clay.TEXTURE_FILTER_BILINEAR);

  std.heap.page_allocator.free(font_path);
  std.heap.page_allocator.free(texture_path);
  std.heap.page_allocator.free(path_buf);
}