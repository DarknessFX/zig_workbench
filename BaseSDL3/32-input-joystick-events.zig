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
var colors : [64]sdl.SDL_Color = std.mem.zeroes([64]sdl.SDL_Color);

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

const MOTION_EVENT_COOLDOWN = 40;

const EventMessage = struct {
  str: [:0]u8,
  color: sdl.SDL_Color,
  start_ticks: u64,
};

var messages: std.ArrayList(EventMessage) = undefined;

fn hatStateString(state: u8) ?[*:0]const u8 {
  return switch (state) {
    sdl.SDL_HAT_CENTERED => "CENTERED",
    sdl.SDL_HAT_UP => "UP",
    sdl.SDL_HAT_RIGHT => "RIGHT",
    sdl.SDL_HAT_DOWN => "DOWN",
    sdl.SDL_HAT_LEFT => "LEFT",
    sdl.SDL_HAT_RIGHTUP => "RIGHT+UP",
    sdl.SDL_HAT_RIGHTDOWN => "RIGHT+DOWN",
    sdl.SDL_HAT_LEFTUP => "LEFT+UP",
    sdl.SDL_HAT_LEFTDOWN => "LEFT+DOWN",
    else => "UNKNOWN",
  };
}

fn batteryStateString(state: sdl.SDL_PowerState) ?[*:0]const u8 {
  return switch (state) {
    sdl.SDL_POWERSTATE_ERROR => "ERROR",
    sdl.SDL_POWERSTATE_UNKNOWN => "UNKNOWN",
    sdl.SDL_POWERSTATE_ON_BATTERY => "ON BATTERY",
    sdl.SDL_POWERSTATE_NO_BATTERY => "NO BATTERY",
    sdl.SDL_POWERSTATE_CHARGING => "CHARGING",
    sdl.SDL_POWERSTATE_CHARGED => "CHARGED",
    else => "UNKNOWN",
  };
}
fn add_message(jid: sdl.SDL_JoystickID, comptime fmt: []const u8, args: anytype) void {
  const color = &colors[jid % colors.len];

  var buf_str: [512]u8 = std.mem.zeroes([512]u8);
  const buf_len = (std.fmt.bufPrint(&buf_str, fmt, args) catch unreachable).len;

  messages.append(std.heap.page_allocator, EventMessage{
    .str = std.heap.page_allocator.dupeZ(u8, buf_str[0..buf_len]) catch unreachable,
    .color = color.*,
    .start_ticks = sdl.SDL_GetTicks(),
  }) catch unreachable;
}
//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
//* This function runs once at startup. */
pub export fn SDL_AppInit(appstate: ?*anyopaque, argc: c_int, argv: [*][*]u8) sdl.SDL_AppResult {
  _ = appstate; _ = argc; _ = argv;
  const appTitle = "SDL3 Example Input Joystick Events";
  _ = sdl.SDL_SetAppMetadata(appTitle, "1.0", "com.example.input-joystick-events");

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
  messages = std.ArrayList(EventMessage).initCapacity(std.heap.page_allocator, 0) catch unreachable;
  add_message(0, "Please plug in a joystick.", .{ });

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
  switch (event.*.type) {
    sdl.SDL_EVENT_JOYSTICK_ADDED => {
      const which = event.*.jdevice.which;
      const joystick = sdl.SDL_OpenJoystick(which);
      const joystick_null: bool = @intFromPtr(joystick) == 0;
      if (!joystick_null) {
        add_message(which, "Joystick #{d} add, but not opened: {s}", .{ which, sdl.SDL_GetError() } );
      } else {
        add_message(which, "Joystick #{d} ('{any}') added", .{ which, joystick } );
      }
    },
    sdl.SDL_EVENT_JOYSTICK_REMOVED => {
      const which = event.*.jdevice.which;
      const joystick = sdl.SDL_GetJoystickFromID(which);
      const joystick_null: bool = @intFromPtr(joystick) == 0;
      if (!joystick_null) {
        sdl.SDL_CloseJoystick(joystick);
      }
      add_message(which, "Joystick #{d} removed", .{ which });
    },
    sdl.SDL_EVENT_JOYSTICK_AXIS_MOTION => {
      var axisMotionCooldownTime: u64 = 0;
      const now = sdl.SDL_GetTicks();
      if (now >= axisMotionCooldownTime) {
        const which = event.*.jaxis.which;
        axisMotionCooldownTime = now + MOTION_EVENT_COOLDOWN;
        add_message(which, "Joystick #{d} axis {d} -> {d}", .{ which, event.*.jaxis.axis, event.*.jaxis.value });
      }
    },
    sdl.SDL_EVENT_JOYSTICK_BALL_MOTION => {
      var ballMotionCooldownTime: u64 = 0;
      const now = sdl.SDL_GetTicks();
      if (now >= ballMotionCooldownTime) {
        const which = event.*.jball.which;
        ballMotionCooldownTime = now + MOTION_EVENT_COOLDOWN;
        add_message(which, "Joystick #{d} ball {d} -> x:{d} y:{d}", .{ which, event.*.jball.ball, event.*.jball.xrel, event.*.jball.yrel });
      }
    },
    sdl.SDL_EVENT_JOYSTICK_HAT_MOTION => {
      const which = event.*.jhat.which;
      add_message(which, "Joystick #{d} hat {d} -> {s}", .{ which, event.*.jhat.hat, hatStateString(event.*.jhat.value).? });
    },
    sdl.SDL_EVENT_JOYSTICK_BUTTON_UP,
    sdl.SDL_EVENT_JOYSTICK_BUTTON_DOWN => {
      const which = event.*.jbutton.which;
      add_message(which, "Joystick #{d} button {d} -> {s}", .{ which, event.*.jbutton.button, if (event.*.jbutton.down) "PRESSED" else "RELEASED" });
    },
    sdl.SDL_EVENT_JOYSTICK_BATTERY_UPDATED => {
      const which = event.*.jbattery.which;
      add_message(which, "Joystick #{d} battery -> {s} - {d}%", .{ which,  batteryStateString(event.*.jbattery.state).?, event.*.jbattery.percent });
    },
    else => {
      // Handle unexpected event types if necessary.
    },
  }

  if (event.*.type == sdl.SDL_EVENT_QUIT) {
    return sdl.SDL_APP_SUCCESS; // end the program, reporting success to the OS
  }
  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once per frame, and is the heart of the program. */
pub export fn SDL_AppIterate(appstate: ?*anyopaque) sdl.SDL_AppResult {
  _ = appstate;
  const now: u64 = sdl.SDL_GetTicks();
  const SDL_Debug_Text_Font_Size = 16; // Example font size
  const msg_lifetime: f32 = 3500.0; // milliseconds

  var prev_y: f32 = 0.0;
  const fwinw: f32 = @floatFromInt(WINDOW_WIDTH);
  const fwinh: f32 = @floatFromInt(WINDOW_HEIGHT);

  _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  _ = sdl.SDL_RenderClear(renderer);
  //sdl.SDL_GetWindowSize(window, &fwinw, &fwinh);

  var messages_remove = std.ArrayList(u8).initCapacity(std.heap.page_allocator, 0) catch unreachable;

  for (messages.items, 0..) |*msg1, i| {
    const msg_len = msg1.str.len;
    const msg_str = &msg1.str[0];
    //sdl.SDL_Log("%d - %d - %s.", i, msg_len, msg_str);

    var x: f32 = 0; var y: f32 = 0;
    const life_percent = @as(f32, @floatFromInt(@as(u32, @intCast(now - msg1.start_ticks)))) / msg_lifetime;
    if (life_percent >= 1.0) { // msg is done.
      messages_remove.append(std.heap.page_allocator, @intCast(i)) catch unreachable;
      continue;
    }

    x = fwinw - @as(f32, @floatFromInt(msg_len * SDL_Debug_Text_Font_Size)) / 2.0;
    y = fwinh * life_percent;
    if (prev_y != 0.0 and (prev_y - y) < @as(f32, @floatFromInt(SDL_Debug_Text_Font_Size))) {
      msg1.start_ticks = now;
      break; // wait for the previous message to tick up a little.
    }

    const fade: u8 = @intFromFloat((1.0 - life_percent) * @as(f32, @floatFromInt(msg1.color.a)));
    _ = sdl.SDL_SetRenderDrawColor(renderer, msg1.color.r, msg1.color.g, msg1.color.b, fade);
    _ = sdl.SDL_RenderDebugText(renderer, x, y, msg_str);

    prev_y = y;
  }

  for (messages_remove.items, 0..) |rem, i| {
    std.heap.page_allocator.free(messages.items[rem].str);
    _ = messages.orderedRemove(rem - i);
  }

  // Present the new rendering
  _ = sdl.SDL_RenderPresent(renderer);

  return sdl.SDL_APP_CONTINUE; // carry on with the program
}

//* This function runs once at shutdown. */
pub export fn SDL_AppQuit(appstate: ?*anyopaque, result: sdl.SDL_AppResult) void {
  _ = appstate; _ = result;

  messages.deinit(std.heap.page_allocator);

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