/// StringType.text is a warper of ArrayList.
//  usingnamespace @import("string.zig");
/// var myStr: StringType = StringType.init("Hello");
/// myStr.append(" world!");
/// print("{s}", myStr.text.items);

const Array = @import("std").ArrayList;
const heap = @import("std").heap;

pub const String = struct {
 usingnamespace StringType;
 usingnamespace init;
};

pub fn init(comptime value: anytype) StringType {
  return StringType.init(value);
}

// Import example : const String =  @import("string.zig").String;
pub const StringType = struct {
  pub const Self = @This();

  text: Array(u8),

  var _mBuffer = [_]u8{0} ** 256;
  var _mBufFba = heap.FixedBufferAllocator.init(&_mBuffer);
  var _mAlloc = _mBufFba.allocator();

  pub fn init(value: anytype) Self {
    var ret: StringType = undefined;// = StringType.init(value);
    ret.text = Array(u8).init(_mAlloc);
    ret.text.appendSlice(@as([]u8, @constCast(value))) catch unreachable;
    return ret;
  }

  pub fn _(self: *Self) void {
    _=self;
  }

  pub fn size(self: *Self) usize {
    return self.text.items.len;
  }

  pub fn toConst(self: *Self) [*:0]const u8 {
    return @as([*:0]const u8, @ptrCast(self.text.items));
  }

  pub fn c_str(self: *Self) [*c]const u8 {
    return @as([*c]const u8, @ptrCast(self.text.items));
  }

  fn cleanBuffer(self: *Self) void {
    self._buffer = [_]u8{' '} ** 256;
    self.text.clearRetainingCapacity();
  }

  pub fn append(self: *Self, value: anytype) void {
    self.text.appendSlice(@as([]u8, @constCast(value))) catch unreachable;
  }

//== Unicode WIP ===
// Better move it to a dedicated StringUtf16.zig
  // textU: []u16 = undefined,
  
  // pub fn initU(value: anytype) Self {
  //   return .{
  //     .text = undefined,
  //     .textU = @as([]u16, @constCast(value)),
  //   };
  // }

  // pub fn sizeU(self: Self) usize {
  //   return self.text.len;
  // }

  // pub fn toConstU(self: Self) [*:0]const u16 {
  //   return @as([*:0]const u16, @ptrCast(self.textU));
  // }

  // pub fn c_strU(self: Self) [*c]const u16 {
  //   return @as([*c]const u16, @ptrCast(self.textU));
  // }
};

//pub fn initU(comptime value: anytype) StringType {
//  return StringType.initU(value);
//}
