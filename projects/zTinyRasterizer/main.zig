//
// DFX porting to zig
//
// Credits:
//   Nikita Lisitsa - @lisyarus
//   https://lisyarus.github.io/blog/posts/implementing-a-tiny-cpu-rasterizer-part-1.html
//
//

const std = @import("std");
const Self = struct {
  usingnamespace @This();
};
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;
pub const sdl = @cImport({
  // NOTE: Need full path to SDL2/include
  @cInclude("SDL.h");
  @cInclude("SDL_ttf.h");
});

// from log.zig
pub inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
pub inline fn toCString(text: []u8) [*:0] const u8 { return @as([*:0]const u8, @ptrCast(text.ptr)); }

const TITLE = "zTiny rasterizer";
const ASSET_FONT_PATH = "asset/font/Roboto-Medium.ttf";

const app = struct {
  var isRunning: bool = false;

  var window: *(sdl.SDL_Window)  = undefined;
  var surface: *sdl.SDL_Surface = undefined;
  var size: Vector2Type(i32) = .{ .x = 1280, .y = 720, };
  var mouse: Vector2Type(i32) = .{ .x = 0.0, .y = 0.0, };

  const clock = struct {
    var started: i64 = undefined; //PerformanceCounter();
    var delta: i64 = undefined;
  };
  var frameCount: u32 = 0;

  const font = struct {
    const file = @embedFile(ASSET_FONT_PATH);
    const size = 16;
    var ttf: *sdl.TTF_Font = undefined;
    var color: ColorType = .{ .r = 255, .g = 255, .b = 255, .a = 255};
  };
};


const ColorType = struct{
  r: u8 = 0,
  g: u8 = 0,
  b: u8 = 0,
  a: u8 = 255,

  fn value(self: ColorType, format: enum{ RGBA, ABGR, SDL_Color }) u32 { return switch (format) { .RGBA => self.toRGBA(), .ABGR => self.toABGR(), .ABGR => self.toSDL(), }; }
  fn toRGBA(self: ColorType) u32 { return (as32(self.r) << 24) | (as32(self.g) << 16) | (as32(self.b) << 8) | as32(self.a); }
  fn toABGR(self: ColorType) u32 { return (as32(self.a) << 24) | (as32(self.b) << 16) | (as32(self.g) << 8) | as32(self.r); }
  fn toSDL(self: ColorType) sdl.SDL_Color { self.normalize(); return sdl.SDL_Color{ .r = self.r, .g = self.g, .b = self.b, .a = self.a, }; }
  fn normalize(self: ColorType) void { normalizeChannel( &self.r ); normalizeChannel( &self.g ); normalizeChannel( &self.b ); normalizeChannel( &self.a ); }// for each self fields?
  inline fn normalizeChannel(channel: *const u8) void { var channel_w = @as(*u8, @ptrCast(@constCast(channel)));  channel_w = @ptrFromInt(@max(0, @min(255, channel.*))); }
  inline fn as32(element: u8) u32 { return @as(u32, @intCast(element)); }
};

inline fn Vector4Type(comptime T: type) type { return struct{ x: T, y: T, z: T, w: T, }; }
inline fn Vector2Type(comptime T: type) type { return struct{ x: T, y: T, }; }
const vector = struct {
  var position: Vector4Type(i32) = {};
  var color: ColorType = {};
};

const SurfaceViewBuffers: u8 = 2;
var SurfaceViews: [SurfaceViewBuffers]SurfaceViewType = undefined;
const SurfaceViewType = struct{
  color: ColorType,
  size: Vector2Type(usize),

  fn clear(self: SurfaceViewType) void { drawSurface( app.surface , self.size, self.color); }
};

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hInstance; _ = hPrevInstance; _ = pCmdLine; _ = nCmdShow;
  app.clock.started = std.time.milliTimestamp();

  _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
  app.window = sdl.SDL_CreateWindow(
    TITLE, 
    sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED,
    app.size.x, app.size.y,
    sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_SHOWN).?;
  _ = sdl.TTF_Init();

  createFont();
  createSurface();

  app.clock.delta = std.time.milliTimestamp();
  app.isRunning = true;
	while (app.isRunning) {
    ProcessInput();
    RenderFrame();

    {
      app.clock.delta = std.time.milliTimestamp() - app.clock.delta;
      app.frameCount +%= 1;
    }
  }

  sdl.TTF_CloseFont(app.font.ttf);
  sdl.SDL_DestroyWindow(app.window);
  sdl.TTF_Quit();
  sdl.SDL_Quit();  

  return 0;
}

fn RenderFrame() void {
  const window_surface = sdl.SDL_GetWindowSurface(app.window);

  // Clear screen
  SurfaceViews[0].clear();

  // DrawText
  const textSurface = sdl.TTF_RenderText_Blended(app.font.ttf, 
    toCString( fmt(
      "Time: {d} | Frames : {d}  | Frame Rate : {} |", .{
      std.time.milliTimestamp() - app.clock.started,
      app.frameCount, 
      @as(u32, @truncate(@abs(app.clock.delta))) })) , 
    sdl.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255, } // app.font.color.toSDL()
  );
  var textRect = sdl.SDL_Rect{ .x = 8,.y = 8, .w = 0,.h = 0, };
  _ = sdl.SDL_BlitSurface(textSurface, null, app.surface, &textRect);

  // Render
  var surfaceRect: sdl.SDL_Rect = sdl.SDL_Rect{.x = 0, .y = 0, .w = app.size.x, .h = app.size.y};
  _ = sdl.SDL_BlitSurface(app.surface, null, window_surface, &surfaceRect);
  _ = sdl.SDL_UpdateWindowSurface(app.window);

  sdl.SDL_FreeSurface(textSurface);
}

fn ProcessInput() void {
	var event: sdl.SDL_Event = undefined;
  while (sdl.SDL_PollEvent(&event) != 0) {
    switch (event.type) {
      sdl.SDL_QUIT => {
        app.isRunning = false;
        break;
      },
      sdl.SDL_KEYDOWN => {
        if ((event.key.keysym.sym == sdl.SDLK_ESCAPE) and 
            (event.key.keysym.mod & sdl.SDLK_LSHIFT == 1)) {
          app.isRunning = false;
          break;
        }
      },
      sdl.SDL_WINDOWEVENT => {
        switch (event.window.event) {
          sdl.SDL_WINDOWEVENT_RESIZED => {
            setSurfaceReset();
            app.size.x = event.window.data1;
            app.size.y = event.window.data2;
            break;
          },
          else => {},
        }
      },
      sdl.SDL_MOUSEMOTION => {
        app.mouse.x = event.motion.x;
        app.mouse.y = event.motion.y;
        break;

      },
      else => {},
    }
  }
}

fn setSurfaceReset() void {
  if (app.surface == undefined) { 
    _ = sdl.SDL_FreeSurface(app.surface);
    app.surface = undefined;
  }
  createSurface();
}

fn createSurface() void {
  app.surface = sdl.SDL_CreateRGBSurfaceWithFormat(0, 
    app.size.x, app.size.y, 32, 
    sdl.SDL_PIXELFORMAT_RGBA32);
  _ = sdl.SDL_SetSurfaceBlendMode(app.surface, sdl.SDL_BLENDMODE_NONE);

  createSurfaceViews();
}

fn createSurfaceViews() void {
  for (0..SurfaceViewBuffers) |index| {
    SurfaceViews[index] = SurfaceViewType{
      .color = ColorType{ .r = 0, .g = 0, .b = 0, .a = 255 },
      .size = .{ .x = @as(usize, @intCast(app.size.x)), .y = @as(usize, @intCast(app.size.y)) },      
    };
  }
}

inline fn setSurfacePixel(surface: *sdl.SDL_Surface, x: usize, y: usize, pixel_ColorType: anytype) void {
  // packed struct(u32) { r: u8, g: u8, b: u8, a: u8 };
  const bytePerPixel = 4;
  const index = x * bytePerPixel + y * @as(usize, @intCast(surface.*.pitch));
  //const index = x * @sizeOf(u32) + y * @as(usize, @intCast(surface.*.pitch));
  const target_pixel = @intFromPtr(surface.*.pixels) + index;
  switch (@TypeOf(pixel_ColorType)) {
    u32 => {
      @as(*u32, @ptrFromInt(target_pixel)).* = pixel_ColorType;
    },
    sdl.SDL_Color => {
      @as(*u8, @ptrFromInt(target_pixel + 0)).* = pixel_ColorType.r;
      @as(*u8, @ptrFromInt(target_pixel + 1)).* = pixel_ColorType.g;
      @as(*u8, @ptrFromInt(target_pixel + 2)).* = pixel_ColorType.b;
      @as(*u8, @ptrFromInt(target_pixel + 3)).* = pixel_ColorType.a;
    },
    f32 => {
      @as(*u8, @ptrFromInt(target_pixel + 0)).* = @as(u8, @intFromFloat(pixel_ColorType.x * 255.99));
      @as(*u8, @ptrFromInt(target_pixel + 1)).* = @as(u8, @intFromFloat(pixel_ColorType.y * 255.99));
      @as(*u8, @ptrFromInt(target_pixel + 2)).* = @as(u8, @intFromFloat(pixel_ColorType.w * 255.99));
      @as(*u8, @ptrFromInt(target_pixel + 3)).* = @as(u8, @intFromFloat(pixel_ColorType.z * 255.99));
    },
    else => { 
      Self.log_( "Unknow setSurfacePixel.ColorType type" ); 
      @panic("Unknow setSurfacePixel.ColorType type");
    },
  }
}

inline fn convert(comptime T: type, value: anytype) T {
  return switch (@TypeOf(T)) {
    u32,i32 => @as(T, @intFromFloat(value)),
    f32 => @as(T, @floatFromInt(value)),
    else => convertAssert(T),
  };
}

inline fn convertAssert(comptime T: type) void {
  if ((@TypeOf(T) != u32) and
      (@TypeOf(T) != i32) and 
      (@TypeOf(T) != f32)) {
    
    std.debug.print("Unknow convert {}", .{ @TypeOf(T) }); 
    @panic("Unsupported type.");
    //unreachable;
  }
}

fn createSurfaceVector(comptime T: type, comptime length: usize) type {
  return @Vector(length, T);
}

fn createFont() void {
  const ttf_rwops = sdl.SDL_RWFromMem(
    @as(?*anyopaque, @ptrCast(@constCast(&app.font.file[0]))), 
    @as(c_int, @intCast(app.font.file.len)));
  const ttf = sdl.TTF_OpenFontRW(ttf_rwops, 1, @as(c_int, @intCast(app.font.size)))
    orelse {
      _ = win.MessageBoxA(null,
         sdl.SDL_GetError(), 
         TITLE, 0);
      unreachable;
    };

  app.font.ttf = ttf;
  // Fallback to .TTF file
  // if (app.font.ttf == undefined) {
  //   if (sdl.TTF_OpenFont(ASSET_FONT_PATH, app.font.size)) |ttf| { app.font.ttf = ttf; }
  //     _ = win.MessageBoxA(null, "Bi", TITLE, 0);
  // }

  // Fail to draw if closed.  :-/
  //_ = sdl.SDL_RWclose(ttf_rwops);
}


fn drawSurface(surface: *sdl.SDL_Surface, size: Vector2Type(usize), color: ColorType) void {
  for (0..size.x) |U| {    
    const U_normalized: f32 = @as(f32, @floatFromInt(U)) / @as(f32, @floatFromInt(size.x));
    for (0..size.y) |V| {
      const V_normalized: f32 =  @as(f32, @floatFromInt(V)) / @as(f32, @floatFromInt(size.y));

      var newcolor = color;
      newcolor.r = @as(u8, @intFromFloat(255.99 * U_normalized));
      newcolor.g = @as(u8, @intFromFloat(255.99 * V_normalized));
      setSurfacePixel(surface, U, V, newcolor.toABGR());
    }
  }
}

// Fix for libc linking error.
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return WinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}
