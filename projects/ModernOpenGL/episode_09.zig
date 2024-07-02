//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 9] [Code] First OpenGL Triangle - Modern OpenGL
//   Mike Shah - https://www.youtube.com/watch?v=sXbqwzXtecE
// Note: See episode_10.zig for a commented source code version.
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

var gVertexArrayObject : sdl.GLuint = 0;  // VAO
var gVertexBufferObject : sdl.GLuint = 0; // VBO
var gGraphicsPipelineShader : sdl.GLuint = 0; // Program Object for our shaders

const gVertexShaderSource: [:0]const u8 = 
\\#version 460 core
\\in vec4 position;
\\void main() {
\\  gl_Position = vec4(position.x, position.y, position.z, position.w);
\\}
;

const gFragmentShaderSource: [:0]const u8 = 
\\#version 460 core
\\out vec4 color;
\\void main() {
\\  color = vec4(1.0f, 0.5f, 0.0f, 1.0f);
\\}
;

// ============================================================================
// Main core and app flow.
//
pub export fn main() u8 {
  InitializeProgram();
  VertexSpecification();
  CreateGraphicsPipeline();
  MainLoop();
  CleanUp();

  return 0;
}

fn MainLoop() void {
  while(!gQuit) {
    PreDraw();
    Draw();
    Input();
  }
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

fn PreDraw() void {
  sdl.glDisable(sdl.GL_DEPTH_TEST);
  sdl.glDisable(sdl.GL_CULL_FACE);
  sdl.glViewport(0, 0, gScreenWidth, gScreenHeight);
  sdl.glClearColor(1.0, 1.0, 0.1, 1.0);
  sdl.glClear(sdl.GL_DEPTH_BUFFER_BIT | sdl.GL_COLOR_BUFFER_BIT);
  sdl.glUseProgram(gGraphicsPipelineShader);
}

fn Draw() void {
  sdl.glBindVertexArray(gVertexArrayObject);
  sdl.glBindBuffer(sdl.GL_ARRAY_BUFFER, gVertexBufferObject);
  sdl.glDrawArrays(sdl.GL_TRIANGLES, 0, 3);

  _ = sdl.SDL_GL_SwapWindow(gAppWindow);
}

fn VertexSpecification() void {
  // Lives on the CPU
  const vertexPositionLen = 9;
  const vertexPosition = @Vector(vertexPositionLen, sdl.GLfloat){
  //  x     y    z
    -0.8, -0.8, 0.0, // vertex 1
     0.8, -0.8, 0.0, // vertex 2
     0.0,  0.8, 0.0  // vertex 3
  };

  // Setting things up to GPU:
  // Start generating our VAO
  sdl.glGenVertexArrays(1, &gVertexArrayObject);
  sdl.glBindVertexArray(gVertexArrayObject);

  // Start generating our VBO
  sdl.glGenBuffers(1, &gVertexBufferObject);
  sdl.glBindBuffer(sdl.GL_ARRAY_BUFFER, gVertexBufferObject);
  sdl.glBufferData(sdl.GL_ARRAY_BUFFER, 
    vertexPositionLen * @sizeOf(sdl.GLfloat),
    &vertexPosition,
    sdl.GL_STATIC_DRAW);

  // Attributes
  sdl.glEnableVertexAttribArray(0);
  sdl.glVertexAttribPointer(
    0,
    3,
    sdl.GL_FLOAT,
    sdl.GL_FALSE,
    0,
    null); //(void*)0

  // Close
  sdl.glBindVertexArray(0);
  sdl.glDisableVertexAttribArray(0);
}

fn CreateGraphicsPipeline() void {
  gGraphicsPipelineShader = CreateShaderProgram(gVertexShaderSource, gFragmentShaderSource);
}

fn CreateShaderProgram(vertexshadersource: [:0]const u8, fragmentshadersource: [:0]const u8) sdl.GLuint {
  const programObject: sdl.GLuint = sdl.glCreateProgram();
  const myVertexShader: sdl.GLuint = CompileShader(sdl.GL_VERTEX_SHADER, vertexshadersource);
  const myFragmentShader: sdl.GLuint =  CompileShader(sdl.GL_FRAGMENT_SHADER, fragmentshadersource);

  sdl.glAttachShader(programObject, myVertexShader);
  sdl.glAttachShader(programObject, myFragmentShader);
  sdl.glLinkProgram(programObject);

  // Validate our program
  sdl.glValidateProgram(programObject);
  // glDetachShader, glDeleteShader

  return programObject;
}

fn CompileShader(shadertype: sdl.GLuint, shadersource: [:0]const u8) sdl.GLuint {
  const shaderObject : sdl.GLuint = sdl.glCreateShader(shadertype);
  if (shaderObject == 0) {
    print("CreateShader {d} failed .\n", .{ shadertype });
  }
  sdl.glShaderSource(
    shaderObject, 
    1, 
     (&shadersource.ptr)[0..1],
    (&@as(c_int, @intCast(shadersource.len)))[0..1]);
  sdl.glCompileShader(shaderObject);

  var success: c_int = undefined;
  sdl.glGetShaderiv(shaderObject, sdl.GL_COMPILE_STATUS, &success);
  if (success == sdl.GL_FALSE) {
    var info_log_buf: [512:0]u8 = undefined;
    sdl.glGetShaderInfoLog(shaderObject, info_log_buf.len, null, &info_log_buf);
    print("CompileShader {d} failed: {s}\n", .{ shadertype, std.mem.sliceTo(&info_log_buf, 0)});
    return 0;
  }

  return shaderObject;
}

// ============================================================================
// Events.
//


// ============================================================================
// Shaders.
//


// ============================================================================
// Tests.
//
