//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 5] [Code] Setup SDL2 and OpenGL and first OpenGL function (glGetString) - Modern OpenGL
//   Mike Shah - https://www.youtube.com/watch?v=wg4om77Drr0

// ============================================================================
// Globals.
//

const std = @import("std");
const print = std.debug.print;
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};
const WINAPI = win.WINAPI;

pub const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
  @cInclude("lib/SDL3/SDL.h");
  @cInclude("lib/SDL3/glad.h");
});

var gQuit : bool = false;
const gScreenWidth : c_int = 1920;
const gScreenHeight : c_int = 1080;
var gAppWindow : ?*sdl.SDL_Window = null;
var gOpenGLCtx : sdl.SDL_GLContext = null;

// ============================================================================
// Main core and app flow.
//

fn MainLoop() void {
  while(!gQuit) {
    PreDraw();
    Draw();
    Input();
  }
}

pub export fn main() u8 {

  InitializeProgram();
  MainLoop();
  CleanUp();

  return 0;
}

fn InitializeProgram() void {
  if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
    print("SDL3 could not initialize video subsystem.\n", .{});
    win.ExitProcess(1);
  }

  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 6);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);

  gAppWindow = sdl.SDL_CreateWindow("OpenGL Window", gScreenWidth, gScreenHeight, sdl.SDL_WINDOW_OPENGL);
  if (gAppWindow == null) {
    print("SDL3 Window was not able to be created.\n", .{});
    win.ExitProcess(1);
  }

  gOpenGLCtx = sdl.SDL_GL_CreateContext(gAppWindow);
  if (gOpenGLCtx == null) {
    print("SDL3 OpenGL Context was not able to be created.\n", .{});
    win.ExitProcess(1);
  }

  //VSync
  _ = sdl.SDL_GL_SetSwapInterval(1);

  // Load GLAD and print GL infos
  GetGLVersionInfo();
}

fn GetGLVersionInfo() void {
  if (sdl.gladLoadGLLoader(@as(sdl.GLADloadproc, @ptrCast(&sdl.SDL_GL_GetProcAddress))) == 0) {
    print("SDL3 Glad failed to initialize.\n", .{});
    win.ExitProcess(1);
  }
  print("Vendor  : {s}\n", .{ sdl.glGetString(sdl.GL_VENDOR) });
  print("Renderer: {s}\n", .{ sdl.glGetString(sdl.GL_RENDERER)});
  print("Version : {s}\n", .{ sdl.glGetString(sdl.GL_VERSION)});
  print("Shader  : {s}\n", .{ sdl.glGetString(sdl.GL_SHADING_LANGUAGE_VERSION)});
}

fn CleanUp() void {
  _ = sdl.SDL_GL_DeleteContext(gOpenGLCtx);
  sdl.SDL_DestroyWindow(gAppWindow);
  sdl.SDL_Quit();
}

fn Input() void {
  var evt : sdl.SDL_Event = undefined;
  while(sdl.SDL_PollEvent(&evt) != 0) {

    // LSHIFT+ESC = Quit
    if (evt.key.key == sdl.SDLK_ESCAPE 
    and evt.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
      //_ = sdl.SDL_RegisterEvents(1);
      //_ = sdl.SDL_PushEvent(sdl.SDL_EVENT_QUIT);
      gQuit = true;
      break;
    }

    if (evt.type == sdl.SDL_EVENT_QUIT) {
      print("Goodbye!\n", .{});
      gQuit = true;
      break;
    }
  }
}

fn PreDraw() void {}
fn Draw() void {
  //* Clear our buffer with a red background */
  sdl.glClearColor ( 1.0, 0.0, 0.0, 1.0 );
  sdl.glClear ( sdl.GL_COLOR_BUFFER_BIT );
  _ = sdl.SDL_GL_SwapWindow(gAppWindow);
  sdl.SDL_Delay(160);

  //* Same as above, but green */
  sdl.glClearColor ( 0.0, 1.0, 0.0, 1.0 );
  sdl.glClear ( sdl.GL_COLOR_BUFFER_BIT );
  _ = sdl.SDL_GL_SwapWindow(gAppWindow);
  sdl.SDL_Delay(160);

  //* Same as above, but blue */
  sdl.glClearColor ( 0.0, 0.0, 1.0, 1.0 );
  sdl.glClear ( sdl.GL_COLOR_BUFFER_BIT );
  _ = sdl.SDL_GL_SwapWindow(gAppWindow);
  sdl.SDL_Delay(160);

  //_ = sdl.SDL_GL_SwapWindow(gAppWindow);
}

// ============================================================================
// Events.
//


// ============================================================================
// Tests.
//
