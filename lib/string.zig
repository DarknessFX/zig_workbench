//!zig-autodoc-section: string
//! string.zig :
//!   String Type Library.

// Build using Zig 0.12.0
// updated based on:
// C++ Weekly With Jason Turner - Ep 430 - How Short String Optimizations Work
// https://www.youtube.com/watch?v=CIB_khrNPSU

// ============================================================================
// Internals
//
const string = @This();
const std = @import("std");

//<string struct>, removed to avoid reference as string.string : pub const string = struct {
const allocated_storage = struct {
  memory: std.mem.Allocator,
  data: []u8,
};

const small_storage = struct {
  data: [@sizeOf(allocated_storage)]u8,
};

/// Buffer union of Small_Storage and MemoryAllocation_Storage, switch automatically if string grows beyond small size.
storage: union(enum) {
  small: small_storage,
  alloc: allocated_storage,

  /// Return the current string buffer capacity.
  pub fn capacity(self: @This()) usize {
    return switch (self) {
      .small => self.small.data.len,
      .alloc => self.alloc.data.len,
    };
  }

  /// Return if the string is using small string optimization or memory alloc.
  pub fn is_small_storage(self: @This()) bool {
    return switch (self) {
      .small => true,
      .alloc => false,
    };
  }
} = .{ .small = .{ .data = [_]u8{0} ** @sizeOf(allocated_storage) }},
/// Current size of string
size: usize = 0,

// ============================================================================
// Methods
//

/// Return a new string
pub fn init() string {
  return string{};
}

/// Free memory if string is using memory allocation.
pub fn deinit(self: *string) void {
  if (!self.storage.is_small_storage()) {
    // Segmentation fault ?
    // self.storage.alloc.memory.free(self.storage.alloc.data);
  }
}

/// Internal: Realloc buffer memory size when necessary.
fn reserve(self: *string, current: []u8, data: []const u8) allocated_storage {
  var alloc = self.storage.alloc.memory.alloc(u8, self.size + data.len + 1) catch unreachable;
  @memcpy(alloc[0..self.size], current[0..self.size]);
  @memcpy(alloc[self.size..self.size + data.len], data);
  alloc[self.size + data.len] = 0; // null-terminator
  return .{ 
    .memory = self.storage.alloc.memory,
    .data = alloc, 
  };
}

/// Append string from Zig literal, ex: string.appendConst("Hello");
pub fn appendConst(self: *string, data: []const u8) string {
  if (self.size + data.len + 1 < @sizeOf(allocated_storage)) {
    @memcpy(self.storage.small.data[self.size..self.size + data.len], data);
    self.storage.small.data[self.size + data.len + 1] = 0; // null-terminator
    self.size = self.size + data.len;
  } else {
    var _small = [_]u8{0} ** @sizeOf(allocated_storage);
    @memcpy(_small[0..self.size], self.storage.small.data[0..self.size]);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    self.storage = .{ .alloc = .{ .memory = gpa.allocator(), .data = ""}};
    self.storage.alloc = reserve(self, &_small, data);
    self.size = self.size + data.len;
  }
  return self.*;
}

/// Return the string value;
pub fn value(self: *string) []u8 {
  if (self.size == 0) return "";
  if (self.storage.is_small_storage()) {
    return self.storage.small.data[0..self.size];
  } else {
    return self.storage.alloc.data[0..self.size];
  }
}

/// Return the string value as const;
pub fn valueConst(self: *string) []const u8 {
  if (self.size == 0) return "";
  if (self.storage.is_small_storage()) {
    return self.storage.small.data[0..self.size];
  } else {
    return self.storage.alloc.data[0..self.size];
  }
}
//</string struct>


// ============================================================================
// Helpers
//
/// Init a string from Zig Literal, ex: var str = string.fromConst("Hello");
pub fn fromConst(str: []const u8) string {
  return @constCast(&string.init()).appendConst(str);
}


// ============================================================================
// Tests
//
test "String Tests: Empty" {
  // Check if Empty string is working and is_small_storage;
  const tst = "";
  var str = fromConst("");
  defer str.deinit();
  try std.testing.expect(std.mem.eql(u8, tst, str.value()));
  try std.testing.expectEqualStrings(tst, str.valueConst());
  try std.testing.expect(str.storage.is_small_storage());
}

test "String Tests: Small string" {
  // Check if Zig Literal is equal to string contents and is_small_storage;
  const tst = "Hello World";
  var str = fromConst("Hello World");
  defer str.deinit();
  try std.testing.expect(std.mem.eql(u8, tst, str.value()));
  try std.testing.expectEqualStrings(tst, str.valueConst());
  try std.testing.expect(str.storage.is_small_storage());
}

test "String Tests: Big string" {
  // Check if a long Zig Literal is equal to string contents and is_small_storage changed;
  const tst = "Hello World, appending long string to change memory layout to allocator instead of small string optimization";
  var str = fromConst("Hello World, appending long string to change memory layout to allocator instead of small string optimization");
  defer str.deinit();
  try std.testing.expect(std.mem.eql(u8, tst, str.value()));
  try std.testing.expectEqualStrings(tst, str.valueConst());
  try std.testing.expect(!str.storage.is_small_storage());
}

test "String Tests: appendConst" {
  // Check if appendConst ZigLiterals is working and is_small_storage;
  const tst = "Hello World!";
  var str = fromConst("Hello");
  defer str.deinit();
  _ = str.appendConst(" World");
  _ = str.appendConst("!");
  try std.testing.expect(std.mem.eql(u8, tst, str.value()));
  try std.testing.expectEqualStrings(tst, str.valueConst());
  try std.testing.expect(str.storage.is_small_storage());
}