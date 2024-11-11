//!zig-autodoc-section: BaseWebGPU\\main.zig
//! main.zig :
//!	  Template for a WebGPU project that build both .bin/.exe and HTML5 Wasm.
// Build using Zig 0.13.0
const std = @import("std");

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