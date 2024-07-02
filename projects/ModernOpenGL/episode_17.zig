//!zig-autodoc-section: SDL3
//!  OpenGL SDL3 program.
// Build using Zig 0.13.0
// Credits : 
//   [Episode 17] glError - Debug errors in OpenGL State Machine - Modern OpenGL
//   Mike Shah - https://www.youtube.com/watch?v=uTidLlObMMw

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

const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
  @cInclude("lib/SDL.h");
  @cInclude("lib/glad.h");
});
 
// Main loop flag
var gQuit : bool = false; // If TRUE terminates the program.

// Screen dimensions
const gScreenWidth : c_int = 1920;
const gScreenHeight : c_int = 1080;

// SDL Window and OpenGL context pointers
var gAppWindow : ?*sdl.SDL_Window = null;
var gOpenGLCtx : sdl.SDL_GLContext = null;

// UniqueID for the graphics pipeline program object
// that will be used for our OpenGL draw calls
var gGraphicsPipelineShader : sdl.GLuint = 0; // Program Object for our shaders

// VAO = Encapsulate all of the items needed to render an object
var gVertexArrayObject : sdl.GLuint = 0;  // VAO

// VBO = Store information relating to vertices (positions, normals, textures).
var gVertexBufferObject : sdl.GLuint = 0; // VBO

// IBO = Store array of indices of vertices allowing to reuse vertices when 
// drawing the triangle.
var gIndexBufferObject : sdl.GLuint = 0; // VBO

// ============================================================================
// Shaders.
//

// VertexShader executes once per vertex, and will be in charge of
// the final position of the vertex.
const gVertexShaderSource: [:0]const u8 = 
\\#version 460 core
\\
\\layout(location=0) in vec3 position;
\\layout(location=1) in vec3 colors;
\\
\\out vec3 v_colors;
\\
\\void main() {
\\  gl_Position = vec4(position, 1.0f);
\\  v_colors = colors;
\\}
;

// FragmentShader executes once per fragment (roughly for every pixel)
// and in part determines the final color that will be sent to screen.
const gFragmentShaderSource: [:0]const u8 = 
\\#version 460 core
\\
\\in vec3 v_colors;
\\out vec4 color;
\\
\\void main() {
\\  color = vec4(v_colors, 1.0f);
\\}
;

// ============================================================================
// Main core and app flow.
//
pub export fn main() u8 {
  // 1. Setup the graphics program
  InitializeProgram();

  // 2. Setup our geometry
  VertexSpecification();

  // 3. Create our graphics pipeline
  CreateGraphicsPipeline();

  // 4. Call the main application loop
  MainLoop();

  // 5. Call the cleanup function when our program terminates
  CleanUp();

  return 0;
}

/// Main Application Loop, infinite loop until gQuit = True;
fn MainLoop() void {
  // While application is running
  while(!gQuit) {
    // Setup anything (i.e. OpenGL State) that needs to take
    // place before draw calls
    PreDraw();
    // Draw Calls in OpenGL
    Draw();
    // Update screen front buffer of our specified window
    _ = sdl.SDL_GL_SwapWindow(gAppWindow);
    // Handle Input
    Input();
  }
}

/// Initialization of the graphics application. Typically this will involver
/// settings up a window and the OpenGL context (with appropriate version)
fn InitializeProgram() void {
  // Initialize SDL
  if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
    print("SDL3 could not initialize video subsystem.\n", .{});
    win.ExitProcess(1);
  }

  // Setup OpenGL Context
  // Use OpenGL 4.6 core or greater
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 6);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);

  // Setup Double Buffer for smooth updating.
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
  _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);

  // Create an application window using OpenGL that supports SDL
  gAppWindow = sdl.SDL_CreateWindow("OpenGL Window", gScreenWidth, gScreenHeight, sdl.SDL_WINDOW_OPENGL);
  if (gAppWindow == null) {
    print("SDL3 Window was not able to be created.\n", .{});
    win.ExitProcess(1);
  }

  // Create an OpenGL Graphics Context
  gOpenGLCtx = sdl.SDL_GL_CreateContext(gAppWindow);
  if (gOpenGLCtx == null) {
    print("SDL3 OpenGL Context was not able to be created.\n", .{});
    win.ExitProcess(1);
  }

  //VSync
  _ = sdl.SDL_GL_SetSwapInterval(1);

  // Initalize GLAD Library and print GL infos
  GetGLVersionInfo();
}

/// Helper function to get OpenGL Information.
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

/// Closes all objects still in use befor terminate the program.
fn CleanUp() void {
  _ = sdl.SDL_GL_DeleteContext(gOpenGLCtx);
  sdl.SDL_DestroyWindow(gAppWindow);
  sdl.SDL_Quit();
}

/// Handle user input, called in MainLoop.
fn Input() void {
  // Event handlerr that handles various events in SDL
  var evt : sdl.SDL_Event = undefined;
  var isQuit : bool = false;

  // Handle events on queue
  while(sdl.SDL_PollEvent(&evt) != 0) {

    // Keyboard: LSHIFT+ESC = Quit
    if (evt.key.key == sdl.SDLK_ESCAPE 
    and evt.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
      //_ = sdl.SDL_RegisterEvents(1);
      //_ = sdl.SDL_PushEvent(sdl.SDL_EVENT_QUIT);
      isQuit = true;
    }

    // If user post an event to Quit (i.e. Close the window, Alt+F4).
    if (evt.type == sdl.SDL_EVENT_QUIT) {
      isQuit = true;
    }

    if (isQuit) {
      print("Goodbye!\n", .{});
      gQuit = true;
      break;
    }
  }
}

/// Typically we will use this for setting some sort of 'state', called in MainLoop
/// Note: Some calls may take place at different stages (post-processing) of
/// the pipeline.
fn PreDraw() void {
  // Disable Depth Test and Face Culling.
  sdl.glDisable(sdl.GL_DEPTH_TEST);
  sdl.glDisable(sdl.GL_CULL_FACE);
  // Initialize clear color
  // This is the background of the screen.
  sdl.glViewport(0, 0, gScreenWidth, gScreenHeight);
  sdl.glClearColor(1.0, 1.0, 0.1, 1.0);
  // Clear buffer and Depth Buffer
  sdl.glClear(sdl.GL_DEPTH_BUFFER_BIT | sdl.GL_COLOR_BUFFER_BIT);

  // Use our shaders
  sdl.glUseProgram(gGraphicsPipelineShader);
}

/// Render function, called in MainLoop.
/// Typically includes 'glDraw'related calls, and the relevant setup of
/// buffers for those calls.
fn Draw() void {
  // Enable our attributes.
  sdl.glBindVertexArray(gVertexArrayObject);
  // Select the vertex buffer object we want to enable
  sdl.glBindBuffer(sdl.GL_ARRAY_BUFFER, gVertexBufferObject);
  // Render data
  GLCheck();
  sdl.glDrawElements(sdl.GL_TRIANGLES, 6, sdl.GL_UNSIGNED_INT, @ptrFromInt(0));
  GLCheck();

  // Stop using our current graphics pipeline.
  // Note: Not necessary in our case since we only have one graphics pipeline.
  sdl.glUseProgram(0);
}

/// Setup our geometry during the vertex specification step
fn VertexSpecification() void {
  // Geometry Data, lives on the CPU, here we are storing (x,y,z) attributes 
  // within vertexPositionss for the data. I use Zig @Vector here to test 
  // compatibility and for now looks like it works fine with OpenGL.
  const vertexVectorLen = 24;
  // Triangles winding direction is CCW Counter-ClockWise.
  const vertexData = @Vector(vertexVectorLen, sdl.GLfloat){
  // x|r   y|g   z|b
    -0.5, -0.5,  0.0,   // vertex 0, bottom left
     1.0,  0.0,  0.0,   // color
     0.5, -0.5,  0.0,   // vertex 1, bottom right
     0.0,  1.0,  0.0,   // color
    -0.5,  0.5,  0.0,   // vertex 2, top left
     0.0,  0.0,  1.0,   // color
     0.5,  0.5,  0.0,   // vertex 3, top right
     1.0,  0.0,  0.0,   // color
  };

  // Setting things up for the GPU:
  // Vertex Array Object (VAO), we can think of it as a 'wrapper aroud' all 
  // Vertex Buffer Objects, in the sense that it encapsulates all VBO state
  // that we are setting up.
  sdl.glGenVertexArrays(1, &gVertexArrayObject);
  sdl.glBindVertexArray(gVertexArrayObject);

  // Vertex Buffer Object, we can think that VAO describes what is inside 
  // the burrito, while VBO allocates the proper amount of space for each
  // content.
  sdl.glGenBuffers(1, &gVertexBufferObject);
  sdl.glBindBuffer(sdl.GL_ARRAY_BUFFER, gVertexBufferObject);

  // Now, in oput currently binded (i.e selected) buffer, we populate the data
  // from our vertexPositions (which is on the CPU), onto a buffer that will 
  // live on the GPU
  sdl.glBufferData(
    sdl.GL_ARRAY_BUFFER,  // Kind of buffer we are working with
    vertexVectorLen * @sizeOf(sdl.GLfloat), // Size of data in bytes
    &vertexData, // Raw array of data
    sdl.GL_STATIC_DRAW); //How we intend to use the data

  // Setup the Index Buffer Object (IBO, aka Element Buffer Object EBO)
  const indexVectorLen = 6;
  const indexData = @Vector(indexVectorLen, sdl.GLuint){
    2, 0, 1,
    3, 2, 1,
  };
  sdl.glGenBuffers(1, &gIndexBufferObject);
  sdl.glBindBuffer(sdl.GL_ELEMENT_ARRAY_BUFFER, gIndexBufferObject);
  sdl.glBufferData(
    sdl.GL_ELEMENT_ARRAY_BUFFER,  // Kind of buffer we are working with
    indexVectorLen * @sizeOf(sdl.GLuint), // Size of data in bytes
    &indexData, // Raw array of data
    sdl.GL_STATIC_DRAW); //How we intend to use the data

  // Attributes, given our VAO we need to tell OpenGL
  // 'how' the information in our buffer will be used.
  sdl.glEnableVertexAttribArray(0);  // Creates Attribute at position (or layout) 0.
  sdl.glVertexAttribPointer(  // Setup Position attribute
    0, // Attribute Position
    3, // Number of components to read (e.g 3 = x,y,z)
    sdl.GL_FLOAT, // Type of component
    sdl.GL_FALSE, // Is data normalized
    6 * @sizeOf(sdl.GLfloat), // Stride (skip Colors)
    @ptrFromInt(0)); // Offset

  // Now linking up color attributes in our VAO
  sdl.glEnableVertexAttribArray(1);  // Creates Attribute at position (or layout) 1.
  sdl.glVertexAttribPointer(  // Setup Color attribute
    1, // Attribute Position
    3, // Number of components to read (e.g 3 = r,g,b)
    sdl.GL_FLOAT, // Type of component
    sdl.GL_FALSE, // Is data normalized
    6 * @sizeOf(sdl.GLfloat), // Stride (skip Positions)
    @ptrFromInt(3 * @sizeOf(sdl.GLfloat))); // Offset (skip initial Postions)

  // Unbind our currently bound VAO
  sdl.glBindVertexArray(0);
  // Disable any attributes we opened in our Vertex Attribute Array,
  // as we do not want to leave them open
  sdl.glDisableVertexAttribArray(0);
  sdl.glDisableVertexAttribArray(1);
}

/// Create the graphics pipeline and compile shaders
fn CreateGraphicsPipeline() void {
  // The lesson moves to external files, but I prefer to use internal string, 
  // this option allow to change the default behaviour.
  const UseExternalShaderFiles: bool = false;
  if (!UseExternalShaderFiles) {
    // Default: Use internal shader source, from Zig String Literal.
    gGraphicsPipelineShader = CreateShaderProgram( .{ 
      .{sdl.GL_VERTEX_SHADER, gVertexShaderSource}, 
      .{sdl.GL_FRAGMENT_SHADER, gFragmentShaderSource}} );
  } else {
    // Optional: Use external .glsl file for shader source.
    var bytes_read: usize = 0;

    var vssource: [1024]u8 = undefined;
    bytes_read = ReadShaderFile(sdl.GL_VERTEX_SHADER, &vssource);
    const vertexshadersource: [:0]const u8 = @as([:0]const u8, @ptrCast(vssource[0..bytes_read]));

    var fssource: [1024]u8 = undefined;
    bytes_read = ReadShaderFile(sdl.GL_FRAGMENT_SHADER, &fssource);
    const fragmentshadersource: [:0]const u8 = @as([:0]const u8, @ptrCast(fssource[0..bytes_read]));

    std.debug.print("{s}\n", .{ vertexshadersource });
    std.debug.print("{s}\n", .{ fragmentshadersource });

    gGraphicsPipelineShader = CreateShaderProgram( .{ 
      .{sdl.GL_VERTEX_SHADER, vertexshadersource}, 
      .{sdl.GL_FRAGMENT_SHADER, fragmentshadersource}} );
  }
}

/// Create a graphics program object (i.e. graphics pipeline).
/// @param pipeline: Tuple of (Tuple of ShaderType and ShaderSource).
/// .{ .{sdl.GL_VERTEX_SHADER, gVertexShaderSource}, 
///    .{sdl.GL_FRAGMENT_SHADER, gFragmentShaderSource} }
/// @return ID of program object
fn CreateShaderProgram(pipeline: anytype) sdl.GLuint {
  // Create a new program object
  const programObject: sdl.GLuint = sdl.glCreateProgram();

  // Compile our shaders and attach to program object
  inline for (pipeline) |shader| {
    const shaderObj: sdl.GLuint = CompileShader(shader[0], shader[1]);
    sdl.glAttachShader(programObject, shaderObj);
  }
  // Link our shaders programs together.
  sdl.glLinkProgram(programObject);

  // Validate our program
  sdl.glValidateProgram(programObject);
  // glDetachShader, glDeleteShader

  return programObject;
}

/// Compile any valid vertex, fragment, geometry, tesselation, compute shader.
/// @param shadertype : Use sdl.GL_TYPE_SHADER to determine which shader is compiling.
/// @param source : Shader source code (in Zig Liteal, const src = "MyShader";)
/// @return ID of the compiled shaderObject.
fn CompileShader(shadertype: sdl.GLuint, shadersource: [:0]const u8) sdl.GLuint {
  // Create our shader object
  const shaderObject : sdl.GLuint = sdl.glCreateShader(shadertype);
  // Validate if CreateShader operate successfully.
  if (shaderObject == 0) {
    print("CreateShader {d} failed .\n", .{ shadertype });
  }
  // Pass source of our shader to shader object.
  sdl.glShaderSource(
    shaderObject, 
    1, 
    (&shadersource.ptr)[0..1],
    (&@as(c_int, @intCast(shadersource.len)))[0..1]);

  // Compile our shader source in shader object
  sdl.glCompileShader(shaderObject);

  // Validate is the CompileShader was successful
  var success: c_int = undefined;
  sdl.glGetShaderiv(shaderObject, sdl.GL_COMPILE_STATUS, &success);
  if (success == sdl.GL_FALSE) {
    // If CompileShader failed, print out the log with the reason for failure.
    var info_log_buf: [512:0]u8 = undefined;
    sdl.glGetShaderInfoLog(shaderObject, info_log_buf.len, null, &info_log_buf);
    print("CompileShader {d} failed: {s}\n", .{ shadertype, std.mem.sliceTo(&info_log_buf, 0)});
    return 0;
  }

  return shaderObject;
}

/// Helper to read shader .glsl files
fn ReadShaderFile(shadertype: sdl.GLuint, shadersource: *[1024]u8) usize {
  // Clear the source buffer
  @memset(shadersource, ' ');

  // Prepare file names by shader type
  const shaderfile: [:0] const u8 = switch (shadertype) {
    sdl.GL_VERTEX_SHADER => "vs.glsl",
    sdl.GL_FRAGMENT_SHADER => "fs.glsl",
    else => return 0,
  };

  // Check if the file exist, if not create a new file using default sources.
  CheckShaderFile(shadertype, shaderfile);

  // Open shader file
  var file = std.fs.cwd().openFile(shaderfile, .{ .mode = .read_only }) catch unreachable;
  defer file.close();

  // Create a buffer and store the shader file content
  const slice = shadersource[0..];
  return file.readAll(slice) catch unreachable;
}

/// Check if the shader source file exist, if not create a new file using default sources.
fn CheckShaderFile(shadertype: sdl.GLuint, shaderfile: [:0] const u8) void {
  var file = std.fs.cwd().openFile(shaderfile, .{ .mode = .read_only }) catch |err| switch (err) {
    error.FileNotFound => {
        var newfile = std.fs.cwd().createFile(shaderfile, .{}) catch unreachable;
        newfile.writeAll(switch (shadertype) {
          sdl.GL_VERTEX_SHADER => gVertexShaderSource,
          sdl.GL_FRAGMENT_SHADER => gFragmentShaderSource,
          else => "",
        }) catch unreachable;
        newfile.close();
        return;
      },
    else => {
      std.debug.print("Error opening file: {}\n", .{err});
      return;
    }
  };
  file.close();
}

// Loop all errors in queue until there is no more errors
fn ClearAllErrors() void {
  while(sdl.glGetError() != sdl.GL_NO_ERROR) {}
}

// Returns true if we have an error
fn CheckErrorStatus() void {
  const err = sdl.glGetError();
  if (err != 0) {
    print("OpenGL Error: {}\n", .{ err });
  }
}

// From C++ Macro : #define GLCheck(x) GLClearErrors(); x; GLCheckErrorStatus();
// Inline function to debug.print errors wrap OpenGL calls with error checking
inline fn GLCheck() void {
  CheckErrorStatus();
  ClearAllErrors();
}

// ============================================================================
// Events.
//


// ============================================================================
// Tests.
//
