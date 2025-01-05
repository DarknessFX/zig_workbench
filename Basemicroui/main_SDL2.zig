//!zig-autodoc-section: BaseMicroui.Main
//! BaseMicroui//main.zig :
//!   Template using Microui and SDL2.
// Build using Zig 0.13.0

const std = @import("std");
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_microui/lib/SDL2/include/SDL.h"); 
//
// Verify other .ZIG files, there are cInclude too that need full path.
//
pub const sdl = @cImport({
  @cInclude("SDL.h");
  @cInclude("SDL_opengl.h");
});

pub const mu = @cImport({
  @cInclude("microui.h");
});
const atlas = @import("atlas.zig");

// Demos:
//   gui_min.zig - minimal window with one button.
//const gui = @import("gui_min.zig");
//
//   gui_demo.zig - microui default SDL2 demo sample.
const gui = @import("gui.zig");

//
// MAIN
//
var winhWnd: win.HWND = undefined;
var window: *(sdl.SDL_Window) = undefined;
var glctx: sdl.SDL_GLContext = undefined;

var width: c_int = 1024;
var height: c_int = 768;

var buf_idx: c_int = 0;
var bg: [3]c_int = [3]c_int { 50, 50, 50 };
const BUFFER_SIZE: c_int = 16384;
var   tex_buf:  [16384 *  6]sdl.GLfloat = std.mem.zeroes([16384 *  6]sdl.GLfloat);
var  vert_buf:  [16384 *  6]sdl.GLfloat = std.mem.zeroes([16384 *  6]sdl.GLfloat);
var color_buf:  [16384 *  6]sdl.GLubyte = std.mem.zeroes([16384 *  6]sdl.GLubyte);
var  index_buf: [16384 *  6]sdl.GLuint  = std.mem.zeroes([16384 *  6]sdl.GLuint );

pub export fn WinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  _ = hInstance;
  _ = hPrevInstance;
  _ = pCmdLine;
  _ = nCmdShow;

  _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
  window = sdl.SDL_CreateWindow(
    "microui", 
    sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 
    width, height, 
    sdl.SDL_WINDOW_OPENGL | sdl.SDL_RENDERER_PRESENTVSYNC ).?; // | sdl.SDL_WINDOW_BORDERLESS | sdl.SDL_WINDOW_ALLOW_HIGHDPI | sdl.SDL_WINDOW_RESIZABLE 
  defer sdl.SDL_DestroyWindow(window);

  r_init();

  var ctx_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer ctx_arena.deinit();
  const ctx_alloc = ctx_arena.allocator();
  var ctx: *mu.mu_Context = ctx_alloc.create(mu.mu_Context) catch unreachable;
  defer ctx_alloc.destroy(ctx);

  mu.mu_init(ctx);
  ctx.text_width = text_width;
  ctx.text_height = text_height;

  var e: sdl.SDL_Event = undefined; 
  var quit: bool = false;
  while( !quit ) {
    while (sdl.SDL_PollEvent(&e) != 0) {
      switch (e.type) {
        sdl.SDL_QUIT => { quit = true; break; }, 

        sdl.SDL_MOUSEMOTION => { mu.mu_input_mousemove(ctx, e.motion.x, e.motion.y); break; },
        sdl.SDL_MOUSEWHEEL =>  { mu.mu_input_scroll(ctx, 0, e.wheel.y * -30); break; },
        sdl.SDL_TEXTINPUT =>   { mu.mu_input_text(ctx, @as([*]const u8, @constCast(&e.text.text))); break; },

        sdl.SDL_MOUSEBUTTONDOWN => { mu.mu_input_mousedown(ctx, e.button.x, e.button.y, e.button.button); break; },
        sdl.SDL_MOUSEBUTTONUP => { mu.mu_input_mouseup(ctx, e.button.x, e.button.y, e.button.button); break; },

        sdl.SDL_KEYDOWN => {
          switch (e.key.keysym.sym) { // Shortcut: Shift+Esc quits.
            sdl.SDLK_ESCAPE => { 
              if ((e.key.keysym.mod & sdl.KMOD_LSHIFT) != 0){ quit = true; }
            },
            else => { mu.mu_input_keyup(ctx, e.key.keysym.sym); },
          }
        },
        else => {},
      }
    }

    gui.present(ctx);

    r_clear(mu.mu_color(bg[0], bg[1], bg[2], 255));
    var cmd: [*c]mu.mu_Command = null;
    while (mu.mu_next_command(ctx, &cmd) != 0) {
      switch (cmd.*.type) {
        mu.MU_COMMAND_TEXT => { r_draw_text(&cmd.*.text.str, cmd.*.text.pos, cmd.*.text.color); },
        mu.MU_COMMAND_RECT => { r_draw_rect(cmd.*.rect.rect, cmd.*.rect.color); },
        mu.MU_COMMAND_ICON => { r_draw_icon(cmd.*.icon.id, cmd.*.icon.rect, cmd.*.icon.color); },
        mu.MU_COMMAND_CLIP => { r_set_clip_rect(cmd.*.clip.rect); },
        else => {  }
      }
    }

    r_present();
  }

  return 0;
}

//Fix when using subsystem Windows and linking Libc
pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, 
  pCmdLine: ?win.LPWSTR, nCmdShow: win.INT) callconv(WINAPI) win.INT {
  return wWinMain(hInstance, hPrevInstance, pCmdLine, nCmdShow);
}

//
// microui/SRC/RENDERER.C Port
//
pub fn r_present() void {
  //sdl.glDisable(sdl.GL_SCISSOR_TEST);
  flush();
  sdl.SDL_GL_SwapWindow(window);
}

pub fn text_width(font: ?*anyopaque, text: [*c]const u8, len: c_int) callconv(.C) c_int {
  _ = font;
  return r_get_text_width(text, len);
}

pub fn text_height(font: ?*anyopaque) callconv(.C) c_int {
  _ = font;
  return r_get_text_height();
}

pub fn r_get_text_width(text: [*c]const u8, len: c_int) callconv(.C) c_int {
  _ = len;
  var res: c_int = 0;
  var p = text;
  while (p.* != 0) : (p += 1) {
    const chr: u8 = @min(p.*, 127);
    res += atlas.atlas[@as(usize, atlas.ATLAS_FONT) + @as(usize, chr)].w;
  }
  return res;
}

pub fn r_get_text_height() callconv(.C) c_int {
  return 18;
}

pub fn r_init() void {
  glctx = sdl.SDL_GL_CreateContext(window);

  sdl.glEnable(sdl.GL_BLEND);
  sdl.glBlendFunc(sdl.GL_SRC_ALPHA, sdl.GL_ONE_MINUS_SRC_ALPHA);
  sdl.glDisable(sdl.GL_CULL_FACE);
  sdl.glDisable(sdl.GL_DEPTH_TEST);
  sdl.glEnable(sdl.GL_SCISSOR_TEST);
  sdl.glEnable(sdl.GL_TEXTURE_2D);
  sdl.glEnableClientState(sdl.GL_VERTEX_ARRAY);
  sdl.glEnableClientState(sdl.GL_TEXTURE_COORD_ARRAY);
  sdl.glEnableClientState(sdl.GL_COLOR_ARRAY);

  var id: sdl.GLuint = undefined;
  sdl.glGenTextures(1, &id);
  sdl.glBindTexture(sdl.GL_TEXTURE_2D, id);
  sdl.glTexImage2D(sdl.GL_TEXTURE_2D, 0, sdl.GL_ALPHA, atlas.ATLAS_WIDTH, atlas.ATLAS_HEIGHT, 0,
    sdl.GL_ALPHA, sdl.GL_UNSIGNED_BYTE, &atlas.atlas_texture);
  sdl.glTexParameteri(sdl.GL_TEXTURE_2D, sdl.GL_TEXTURE_MIN_FILTER, sdl.GL_NEAREST);
  sdl.glTexParameteri(sdl.GL_TEXTURE_2D, sdl.GL_TEXTURE_MAG_FILTER, sdl.GL_NEAREST);
}

pub fn flush() void {
  if (buf_idx == 0) { return; }

  sdl.glViewport(0, 0, width, height);
  sdl.glMatrixMode(sdl.GL_PROJECTION);
  sdl.glPushMatrix();
  sdl.glLoadIdentity();
  sdl.glOrtho(0.0, @as(f64, @floatFromInt(width)), @as(f64, @floatFromInt(height)), 0.0, -1.0, 1.0);
  sdl.glMatrixMode(sdl.GL_MODELVIEW);
  sdl.glPushMatrix();
  sdl.glLoadIdentity();

  sdl.glTexCoordPointer(2, sdl.GL_FLOAT, 0, &tex_buf);
  sdl.glVertexPointer(2, sdl.GL_FLOAT, 0, &vert_buf);
  sdl.glColorPointer(4, sdl.GL_UNSIGNED_BYTE, 0, &color_buf);
  const cBuf_idx: c_int = buf_idx * 6;
  sdl.glDrawElements(sdl.GL_TRIANGLES, cBuf_idx, sdl.GL_UNSIGNED_INT, &index_buf);

  sdl.glMatrixMode(sdl.GL_MODELVIEW);
  sdl.glPopMatrix();
  sdl.glMatrixMode(sdl.GL_PROJECTION);
  sdl.glPopMatrix();

  buf_idx = 0;
}

pub fn r_clear(clr: mu.mu_Color) void {
  flush();
  sdl.glClearColor(
    @as(f32, @floatFromInt(clr.r)) / 255.0, 
    @as(f32, @floatFromInt(clr.g)) / 255.0, 
    @as(f32, @floatFromInt(clr.b)) / 255.0, 
    @as(f32, @floatFromInt(clr.a)) / 255.0);
  //sdl.glEnable(sdl.GL_SCISSOR_TEST);
  sdl.glClear(sdl.GL_COLOR_BUFFER_BIT);
}

fn push_quad(dst: mu.mu_Rect, src: mu.mu_Rect, color: mu.mu_Color) void {
  if (buf_idx == BUFFER_SIZE) { flush(); }

  const texvert_idx: usize  = @as(usize, @intCast(buf_idx * 8));
  const color_idx: usize    = @as(usize, @intCast(buf_idx * 16));
  const element_idx: c_uint = @as(c_uint, @intCast(buf_idx * 4));
  const index_idx: usize    = @as(usize, @intCast(buf_idx * 6));
  buf_idx += 1;

  const x: sdl.GLfloat = @as(sdl.GLfloat, @floatFromInt(src.x)) / @as(sdl.GLfloat, @floatFromInt(atlas.ATLAS_WIDTH));
  const y: sdl.GLfloat = @as(sdl.GLfloat, @floatFromInt(src.y)) / @as(sdl.GLfloat, @floatFromInt(atlas.ATLAS_HEIGHT));
  const w: sdl.GLfloat = @as(sdl.GLfloat, @floatFromInt(src.w)) / @as(sdl.GLfloat, @floatFromInt(atlas.ATLAS_WIDTH));
  const h: sdl.GLfloat = @as(sdl.GLfloat, @floatFromInt(src.h)) / @as(sdl.GLfloat, @floatFromInt(atlas.ATLAS_HEIGHT));
  tex_buf[texvert_idx + 0] = x;
  tex_buf[texvert_idx + 1] = y;
  tex_buf[texvert_idx + 2] = x + w;
  tex_buf[texvert_idx + 3] = y;
  tex_buf[texvert_idx + 4] = x;
  tex_buf[texvert_idx + 5] = y + h;
  tex_buf[texvert_idx + 6] = x + w;
  tex_buf[texvert_idx + 7] = y + h;

  vert_buf[texvert_idx + 0] = @as(sdl.GLfloat, @floatFromInt(dst.x));
  vert_buf[texvert_idx + 1] = @as(sdl.GLfloat, @floatFromInt(dst.y));
  vert_buf[texvert_idx + 2] = @as(sdl.GLfloat, @floatFromInt(dst.x + dst.w));
  vert_buf[texvert_idx + 3] = @as(sdl.GLfloat, @floatFromInt(dst.y));
  vert_buf[texvert_idx + 4] = @as(sdl.GLfloat, @floatFromInt(dst.x));
  vert_buf[texvert_idx + 5] = @as(sdl.GLfloat, @floatFromInt(dst.y + dst.h));
  vert_buf[texvert_idx + 6] = @as(sdl.GLfloat, @floatFromInt(dst.x + dst.w));
  vert_buf[texvert_idx + 7] = @as(sdl.GLfloat, @floatFromInt(dst.y + dst.h));

  _ = @memcpy(@as([*]u8, @ptrCast(color_buf[color_idx + 0..])),  @as([*]const u8, @ptrCast(&color))[0..4]);
  _ = @memcpy(@as([*]u8, @ptrCast(color_buf[color_idx + 4..])),  @as([*]const u8, @ptrCast(&color))[0..4]);
  _ = @memcpy(@as([*]u8, @ptrCast(color_buf[color_idx + 8..])),  @as([*]const u8, @ptrCast(&color))[0..4]);
  _ = @memcpy(@as([*]u8, @ptrCast(color_buf[color_idx + 12..])), @as([*]const u8, @ptrCast(&color))[0..4]);

  index_buf[index_idx + 0] = element_idx + 0;
  index_buf[index_idx + 1] = element_idx + 1;
  index_buf[index_idx + 2] = element_idx + 2;
  index_buf[index_idx + 3] = element_idx + 2;
  index_buf[index_idx + 4] = element_idx + 3;
  index_buf[index_idx + 5] = element_idx + 1;
}

pub fn r_draw_rect(rect: mu.mu_Rect, color: mu.mu_Color) void {
  push_quad(rect, atlas.atlas[atlas.ATLAS_WHITE], color);
}

pub fn r_draw_text(text: []const u8, pos: mu.mu_Vec2, color: mu.mu_Color) void {
  var dst:mu.mu_Rect = .{ .x = pos.x, .y = pos.y, .w = 0, .h = 0 };

  var idx: u8 = 0;
  while (text.ptr[idx] != 0) {
    const chr: u8 = @min(text.ptr[idx], 127);
    const src: mu.mu_Rect = @as(mu.mu_Rect, atlas.atlas[@as(usize, atlas.ATLAS_FONT) + @as(usize, chr)]);
    dst.w = src.w;
    dst.h = src.h;
    push_quad(dst, src, color);
    dst.x += dst.w;

    idx += 1;
  }
}

pub fn r_draw_icon(id: c_int, rect: mu.mu_Rect, color: mu.mu_Color) void {
  const src: mu.mu_Rect = atlas.atlas[@as(usize, @intCast(id))];
  const x: c_int = rect.x + @divTrunc((rect.w - src.w), 2);
  const y: c_int = rect.y + @divTrunc((rect.h - src.h), 2);
  push_quad(mu.mu_rect(x, y, src.w, src.h), src, color);
}

pub fn r_set_clip_rect(rect: mu.mu_Rect) void {
  flush();
  sdl.glScissor(rect.x, height - (rect.y + rect.h), rect.w, rect.h);
}