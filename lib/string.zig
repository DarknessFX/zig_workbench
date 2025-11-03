//!zig-autodoc-section: zesp-idf\\string.zig
//!  main.zig :
//!    Zig String Type.
// Build using Zig 0.15.2

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

pub const StringKind = enum {
  Const,
  Buffer,
  FBA,
  Alloc,
  List,
};

//#endregion ==================================================================
//#region MARK: String function
//=============================================================================
pub fn String(comptime arg: anytype) @TypeOf(StringType: {
  break :StringType switch (@typeInfo(@TypeOf(arg))) {
    .pointer => StringConst(arg),
    .@"struct" => switch (arg.kind) {
      .Buffer => StringBuffer(arg.text, arg.capacity),
      .FBA => StringFBA(arg.text, arg.capacity),
      .Alloc => StringAlloc(arg.text),
      .List => StringAlloc(arg.text),
      else => void,
    },
    else => void,
  };
}) {
  const typeInfo = @typeInfo(@TypeOf(arg));
  const isSlice: bool = switch (typeInfo) {
    .pointer => true,
    else => false,
  };
  const isStruct: bool = switch (typeInfo) {
    .@"struct" => true,
    else => false,
  };

  if (isSlice) { return StringConst(arg); }
  if (isStruct) { 
    return switch (arg.kind) {
      .Buffer => StringBuffer(arg.text, arg.capacity),
      .FBA => StringFBA(arg.text, arg.capacity),
      .Alloc => StringAlloc(arg.text),
      .List => StringAlloc(arg.text),
      else => {},
    };
  }
}

//#endregion ==================================================================
//#region MARK: Shared
//=============================================================================
fn printShared(text: []const u8) void {
  std.debug.print("{s}\n", .{ text }); 
}

//#endregion ==================================================================
//#region MARK: StringConst
//=============================================================================
pub const StringType = struct {
  const Self = @This();  
  kind: StringKind,
  text: []const u8,

  pub fn print(self: Self) void { printShared(self.text); } 
  pub fn append(self: Self, new_text: []const u8, comptime capacity: usize) @TypeOf(StringBuffer(self.text, capacity)) {
    var fba = StringBuffer(self.text, capacity);
    return fba.append(new_text);    
  }
};

pub fn StringConst(text: []const u8) StringType {
  return StringType{
    .kind = .Const,
    .text = text,
  };
}

//#endregion ==================================================================
//#region MARK: StringBuffer
//=============================================================================
pub fn StringBuffer(text: []const u8, comptime capacity: usize) struct {
  const Self = @This();  
  text: [capacity]u8,
  len: usize,
  capacity: usize = capacity,  

  pub fn print(self: Self) void { printShared(self.text[0..]); }
  pub fn append(self: *Self, new_text: []const u8) Self {
    const new_len = self.len + new_text.len;
    @memcpy(self.text[self.len..new_len], new_text);
    self.len = new_len;
    return self.*;
  }  
} {
  var fixed: [capacity]u8 = @splat(0);
  @memcpy(fixed[0..text.len], text);

  return .{
    .text = fixed,
    .len = text.len,
    .capacity = capacity,  
  };
}

//#endregion ==================================================================
//#region MARK: StringFBA
//=============================================================================
pub fn StringFBA(text: []const u8, comptime capacity: usize) struct {
  const Self = @This();
  allocator: std.heap.FixedBufferAllocator,
  text: [capacity]u8,
  len: usize,
  capacity: usize = capacity,

  pub fn print(self: Self) void { printShared(self.text[0..self.len]); }
  pub fn append(self: Self, new_text: []const u8, comptime new_capacity: usize) @TypeOf(StringFBA("", new_capacity)) {
    var strfba = StringFBA(self.text[0..self.text.len], new_capacity);
    @memcpy(strfba.text[self.text.len..self.text.len + new_text.len], new_text);
    strfba.len = self.text.len + new_text.len;
    return strfba;
  }
} {
  var fixed_buf: [capacity]u8 = @splat(0);
  const fba = std.heap.FixedBufferAllocator.init(&fixed_buf);
  @memcpy(fixed_buf[0..text.len], text);

  return .{
    .allocator = fba,
    .text = fixed_buf,
    .len = text.len,
    .capacity = capacity,
  };
}

//#endregion ==================================================================
//#region MARK: StringAlloc
//=============================================================================
pub const StringAllocType = struct {
  const Self = @This();  
  kind: StringKind,
  gpa: std.heap.GeneralPurposeAllocator(.{}),
  text: []u8,
  len: usize,

  pub fn print(self: Self) void { printShared(self.text[0..self.len]); }
  pub fn append(self: *Self, new_text: []const u8) void {
    const new_len = self.len + new_text.len;
    const new_slice = self.gpa.allocator().realloc(self.text, new_len) catch unreachable;
    @memcpy(new_slice[self.len..new_len], new_text);
    self.text = new_slice;
    self.len = new_len;
  }

  pub fn free(self: *Self) void {
    self.gpa.allocator().free(self.text);
    self.len = 0;
  }
};

pub fn StringAlloc(text: []const u8) StringAllocType {
  var strAlloc = StringAllocType{
    .kind = .Alloc,
    .gpa = std.heap.GeneralPurposeAllocator(.{}){},
    .len = 0,
    .text = &[_]u8{},
  };
  const slice = strAlloc.gpa.allocator().alloc(u8, text.len) catch unreachable;
  @memcpy(slice, text);
  strAlloc.text = slice;
  strAlloc.len = slice.len;

  return strAlloc;
}

//#endregion ==================================================================
//#region MARK: StringList
//=============================================================================
pub const StringListType = struct {
  const Self = @This();
  kind: StringKind,
  gpa: std.heap.GeneralPurposeAllocator(.{}),
  list: std.ArrayList(u8),
  text: []u8,

  pub fn print(self: Self) void {
    printShared(self.text);
  }

  pub fn append(self: *Self, new_text: []const u8) void {
    _ = self.list.appendSlice(self.gpa.allocator(), new_text) catch unreachable;
    self.text = self.list.items[0..self.list.items.len];
  }

  pub fn free(self: *Self) void {
    self.list.deinit(self.gpa.allocator());
  }
};

pub fn StringList(text: []const u8) StringListType {
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  var list = std.ArrayList(u8).initCapacity(gpa.allocator(), 0) catch unreachable;
  _ = list.appendSlice(gpa.allocator(), text) catch unreachable;

  return StringListType{
    .kind = .List,
    .gpa = gpa,
    .list = list,
    .text = list.items[0..list.items.len],
  };
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " StringConst" {
  const strConst1 = String("Hello StringConst");
  strConst1.print();

  const strConst2 = strConst1.append(" appending to s1 Const", 128);
  strConst2.print();
}

test " StringBuffer" {
  var strBuffer1 = String(.{ .kind = .Buffer, .text = "Hello StringBuffer", .capacity = 64 });
  strBuffer1.print();

  _ = strBuffer1.append(" appended for s2 Buffer");
  strBuffer1.print();
}

test " StringFBA" {
  var strFBA1 = String(.{ .kind = .FBA, .text = "Hello StringFBA", .capacity = 64 });
  strFBA1.print();

  const strFBA2 = strFBA1.append(" appending to s3 FBA", 128);
  strFBA2.print();
}

test " StringAlloc" {
  var strAlloc1 = StringAlloc("Hello StringAlloc");
  defer strAlloc1.free();
  strAlloc1.print();

  strAlloc1.append(" appending to s7 StringAlloc");
  strAlloc1.print();

  strAlloc1.append(" more and more and more, without knowing the size or capacity");
  strAlloc1.print();

  var strAlloc2 = String(.{ .kind = .Alloc, .text = "Hello StringAlloc via String" });
  defer strAlloc2.free();
  strAlloc2.print();
}

test " StringList" {
  var strList1 = StringList("Hello StringList");
  defer strList1.free();
  strList1.print();

  strList1.append(" and more!");
  strList1.print();

  var strList2 = String(.{ .kind = .List, .text = "Hello StringList via String" });
  defer strList2.free();
  strList2.print();

  strList2.append(" and more appending!");
  strList2.print();
}

//#endregion ==================================================================
//=============================================================================