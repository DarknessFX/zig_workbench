//!zig-autodoc-section: BaseLua\\main.zig
//! main.zig :
//!	  Template for Lua program.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseLua/lib/lua/lua.h");
const lua = @cImport({
  @cInclude("lib/lua/lua.h");
  @cInclude("lib/lua/lualib.h");
  @cInclude("lib/lua/lauxlib.h");
  @cInclude("stdio.h");    
});

pub fn main() u8 {
  //HideConsoleWindow();
  const stderr = std.io.getStdErr().writer();
  const lua_state = lua.luaL_newstate();
  defer lua.lua_close(lua_state);

  lua.luaL_openlibs(lua_state);

  if (lua.luaL_loadfilex(lua_state, "script.lua", null) != 0) {
    stderr.print("Couldn't load file: {s}\n", .{lua.lua_tolstring(lua_state, -1, null)}) catch unreachable;
    return 1; // "Failed to load Lua script"
  }

  lua.lua_newtable(lua_state);

  var i: c_int = 1;
  while (i <= 5) : (i += 1) {
    lua.lua_pushnumber(lua_state, @floatFromInt(i));
    lua.lua_pushnumber(lua_state, @floatFromInt(i * 2));
    lua.lua_rawset(lua_state, -3);
  }

  lua.lua_setglobal(lua_state, "foo");

  if (lua.lua_pcallk(lua_state, 0, lua.LUA_MULTRET, 0, 0, lua_cont) != 0) {
    // Error handling
    stderr.print("Failed to run script: {s}\n", .{lua.lua_tolstring(lua_state, -1, null)}) catch unreachable;
    return 2; // "Failed to run Lua script"
  }

  const sum = lua.lua_tonumberx(lua_state, -1, null);

  _ = lua.printf("Script returned: %.0f\n", sum);

  lua.lua_pop(lua_state, 1);

  return 0;
}

fn lua_cont(lua_state: ?*lua.lua_State, status: c_int, ctx: lua.lua_KContext) callconv(.C) c_int {
  _ = lua_state; _ = status; _ = ctx;
  return 0;
}


// ============================================================================
// Helpers
//
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};

fn HideConsoleWindow() void {
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = ShowWindow(hwndFound, SW_HIDE);
}

pub extern "kernel32" fn GetConsoleTitleA(
  lpConsoleTitle: win.LPSTR,
  nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

pub extern "kernel32" fn FindWindowA(
  lpClassName: ?win.LPSTR,
  lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;

pub const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: i32
) callconv(win.WINAPI) win.BOOL;

pub const MB_OK = 0x00000000;
pub extern "user32" fn MessageBoxA(
  hWnd: ?win.HWND,
  lpText: [*:0]const u8,
  lpCaption: [*:0]const u8,
  uType: win.UINT
) callconv(win.WINAPI) win.INT;

// ============================================================================
// Tests
//
test " " {
}