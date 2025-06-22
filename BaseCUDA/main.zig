//!zig-autodoc-section: BaseCUDA.Main
//!   BaseCUDA, template for Nvidia CUDA program.
// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE: There are hard-coded paths pointing to cl.exe (Microsoft VC compiler)
//       at .vscode/tasks.json (Lines 6 and 28) AND build.zig (line 28), 
//       make sure to fix this paths to your local Visual Studio folders.
extern fn helloWorld(arg1: i32, arg2: f32) callconv(.C) void;


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() void {
  std.debug.print("Calling CUDA function...\n", .{});
  helloWorld(10298, 3.141592);
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================