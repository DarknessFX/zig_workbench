// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");
pub extern fn main() void; // Zig Main, ignored, using SDL3

const sdl = @cImport({
  // NOTE: Need full path to SDL3/include
  // Remember to copy SDL3.dll to Zig.exe folder PATH
  @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
  @cInclude("SDL.h");
  @cInclude("SDL_main.h");
});

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;
var joystick: * sdl.SDL_Joystick = undefined;
var colors : [64]sdl.SDL_Color = std.mem.zeroes([64]sdl.SDL_Color);

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================


//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;

  const appTitle = "SDL3 Example Input Joystick Polling";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.input-joystick-polling");

  if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_JOYSTICK)) {
    sdl.SDL_Log("Couldn't initialize SDL: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  if (!sdl.SDL_CreateWindowAndRenderer(appTitle, WINDOW_WIDTH, WINDOW_HEIGHT, 0, @ptrCast(&window), @ptrCast(&renderer))) {
    sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
    return sdl.SDL_APP_FAILURE;
  }

  for (0..colors.len) |i| {
    colors[i].r = @as(u8, @intCast(sdl.SDL_rand(255)));
    colors[i].g = @as(u8, @intCast(sdl.SDL_rand(255)));
    colors[i].b = @as(u8, @intCast(sdl.SDL_rand(255)));
    colors[i].a = 255;
  }

  return sdl.SDL_APP_CONTINUE; // carry on with the program!
}
//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================


//* This function runs when a new event (mouse input, keypresses, etc) occurs. */
pub export fn SDL_AppEvent(appstate: ?*anyopaque, event: *sdl.SDL_Event) sdl.SDL_AppResult {
  _ = appstate;

  // SHIFT + ESC to quit
  if (event.key.key == sdl.SDLK_ESCAPE 
  and event.key.mod & sdl.SDL_KMOD_LSHIFT == 1) {
    return sdl.SDL_EVENT_QUIT;
  }

  // Joystick
  var joystick_null = @intFromPtr(joystick) == 0;
  if (event.*.type == sdl.SDL_EVENT_JOYSTICK_ADDED) {
    // This event is sent for each hotplugged stick, and also for each already-connected joystick during SDL_Init().
    if (joystick_null) { // We don't have a stick yet and one was added, open it!
      joystick = sdl.SDL_OpenJoystick(event.*.jdevice.which).?;
      joystick_null = @intFromPtr(joystick) == 0;
      if (joystick_null) {
        sdl.SDL_Log("Failed to open joystick ID {d}: {s}", 
          @as(u32, @intCast(event.*.jdevice.which)),
          sdl.SDL_GetError());
      }
    }
  } else if (event.*.type == sdl.SDL_EVENT_JOYSTICK_REMOVED) {
    if (!joystick_null 
    and sdl.SDL_GetJoystickID(joystick) == event.*.jdevice.which) {
      sdl.SDL_CloseJoystick(joystick); // Our joystick was unplugged.
      joystick_null = @intFromPtr(joystick) == 0;
    }
  }

  if (event.*.type == sdl.SDL_EVENT_QUIT) {
    return sdl.SDL_APP_SUCCESS; // end the program, reporting success to the OS
  }
  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once per frame, and is the heart of the program. */
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;

  const joystick_null = @intFromPtr(joystick) == 0;
  const text: [*c]const u8 = if (!joystick_null)
    sdl.SDL_GetJoystickName(joystick)
    else "Plug in a joystick, please.";
  var x: f32 = 0;
  var y: f32 = 0;

  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  _ = sdl.SDL_RenderClear(renderer);

  var winw: c_int = 0;
  var winh: c_int = 0;
  _ = sdl.SDL_GetWindowSize(window, &winw, &winh);
  const fwinw: f32 = @floatFromInt(winw);
  const fwinh: f32 = @floatFromInt(winh);

  if (!joystick_null) {
    const size: f32 = 30.0;
    var total: c_int = 0;
    var ftotal: f32 = 0.0;
    var utotal: usize = 0;

    // Draw axes
    total = sdl.SDL_GetNumJoystickAxes(joystick);
    ftotal = @floatFromInt(total);
    utotal = @intCast(total);
    y = (fwinh - (ftotal * size)) / 2;
    x = fwinw / 2.0;
    for (0..utotal) |i| {
      const ci: c_int = @intCast(i);
      const color = &colors[i % colors.len];
      const axis: f32 =  @floatFromInt(sdl.SDL_GetJoystickAxis(joystick, ci));
      const val = axis / 32767.0;
      const dx = x + (val * x);
      const dst = sdl.SDL_FRect{
        .x = dx,
        .y = y,
        .w = x - @abs(dx),
        .h = size,
      };
      _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
      _ = sdl.SDL_RenderFillRect(renderer, &dst);
      y += size;
    }

    // Draw buttons
    total = sdl.SDL_GetNumJoystickButtons(joystick);
    ftotal = @floatFromInt(total);
    utotal = @intCast(total);
    x = (fwinw - (ftotal * size)) / 2;
    for (0..utotal) |i| {
      const ci: c_int = @intCast(i);
      const color = &colors[i % colors.len];
      const dst = sdl.SDL_FRect{
        .x = x,
        .y = 0.0,
        .w = size,
        .h = size,
      };
      if (sdl.SDL_GetJoystickButton(joystick, ci)) {
        _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
      } else {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
      }
      _ = sdl.SDL_RenderFillRect(renderer, &dst);
      _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, color.a);
      _ = sdl.SDL_RenderRect(renderer, &dst);
      x += size;
    }

    // Draw hats
    total = sdl.SDL_GetNumJoystickHats(joystick);
    ftotal = @floatFromInt(total);
    utotal = @intCast(total);
    x = ((fwinw - (ftotal * (size * 2.0))) / 2.0) + (size / 2.0);
    y = fwinh - size;
    for (0..utotal) |i| {
      const ci: c_int = @intCast(i);
      const color = &colors[i % colors.len];
      const thirdsize = size / 3.0;
      const cross = [_]sdl.SDL_FRect{
        .{ .x = x, .y = y + thirdsize, .w = size, .h = thirdsize },
        .{ .x = x + thirdsize, .y = y, .w = thirdsize, .h = size },
      };
      const hat = sdl.SDL_GetJoystickHat(joystick, ci);

      _ = sdl.SDL_SetRenderDrawColor(renderer, 90, 90, 90, 255);
      _ = sdl.SDL_RenderFillRects(renderer, &cross[0], cross.len);

      _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);

      if ((hat & sdl.SDL_HAT_UP) != 0) {
        const dst = sdl.SDL_FRect{ .x = x + thirdsize, .y = y, .w = thirdsize, .h = thirdsize };
        _ = sdl.SDL_RenderFillRect(renderer, &dst);
      }

      if ((hat & sdl.SDL_HAT_RIGHT) != 0) {
        const dst = sdl.SDL_FRect{ .x = x + (thirdsize * 2), .y = y + thirdsize, .w = thirdsize, .h = thirdsize };
        _ = sdl.SDL_RenderFillRect(renderer, &dst);
      }

      if ((hat & sdl.SDL_HAT_DOWN) != 0) {
        const dst = sdl.SDL_FRect{ .x = x + thirdsize, .y = y + (thirdsize * 2), .w = thirdsize, .h = thirdsize };
        _ = sdl.SDL_RenderFillRect(renderer, &dst);
      }

      if ((hat & sdl.SDL_HAT_LEFT) != 0) {
        const dst = sdl.SDL_FRect{ .x = x, .y = y + thirdsize, .w = thirdsize, .h = thirdsize };
        _ = sdl.SDL_RenderFillRect(renderer, &dst);
      }

      x += size * 2.0;
    }
  }

  x = (fwinw - (@as(f32, @floatFromInt(sdl.SDL_strlen(text))) * sdl.SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE)) / 2.0;
  y = (fwinh - sdl.SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE) / 2.0;
  _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
  _ = sdl.SDL_RenderDebugText(renderer, x, y, text);
  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  //* SDL will clean up the window/renderer for us. */
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================