//!zig-autodoc-section: BaseWebGPU\\main.zig
//! main.zig :
//!  Template for a WebGPU project that build both bin/.exe and HTML5 WebGPU and Wasm.
// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() void {
  const builtin = @import("builtin");
  platform: {
    switch (builtin.target.os.tag) {
      .windows => { @import("app.zig").main(); },
      .emscripten => {},
      else => |tag| { std.log.debug("Platform {s} not implemented.", .{ tag }); },
    }
    break :platform;
  }  
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================