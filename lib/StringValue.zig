//!zig-autodoc-section: StringValue Type
//! StringValue.zig :
//!   A simple string type that owns its memory and length, and provides a couple of helper functions for C interoperability.
//!
//! Usage:
//!   var hello_world: StringValue(16) = .init("Hello?");  // Or = .{};
//!   std.debug.print("Say: {s} | buffer {s} | len {d}\n", .{ hello_world.get(), hello_world.buffer, hello_world.len });
//!   hello_world.set("Hello, World!");
//!   std.debug.print("Say: {s} | buffer {s} | len {d}\n", .{ hello_world.get(), hello_world.buffer, hello_world.len });
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: StringValue
//=============================================================================
pub fn StringValue(comptime capacity: usize) type {
  return struct {
    const Self = @This();

    buffer: [capacity]u8 = [_]u8{0} ** capacity,
    len: usize = 0,

    pub fn init(value: []const u8) Self {
      var self: Self = .{};
      self.set(value);
      return self;
    }

    fn update(self: *Self, value: []const u8, length: usize) void {
      const copy_len = @min(length, capacity);
      @memset(&self.buffer, 0);
      @memcpy(self.buffer[0..copy_len], value[0..copy_len]);
      self.len = copy_len;
    }

    pub fn set(self: *Self, value: []const u8) void {
      self.update(value, value.len);
    }

    pub fn setC(self: *Self, value: []const u8, length: usize) void {
      self.update(value, length + 1);
      if (self.len == self.buffer.len) { self.buffer[self.len - 1] = 0; }
    }

    pub fn get(self: *const Self) []const u8 {
      return self.buffer[0..self.len];
    }

    /// Ensure you have enough capacity for the sentinel as the last byte,
    /// or you will lose the last character of the string.
    pub fn getC(self: *const Self) [:0]const u8 {
      if (self.len == self.buffer.len and self.buffer[self.len - 1] != 0) { @constCast(self).buffer[self.len - 1] = 0; }
      return self.buffer[0..self.len :0];
    }
  };
}
