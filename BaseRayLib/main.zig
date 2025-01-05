//!zig-autodoc-section: BaseRayLib.Main
//! BaseRayLib//main.zig :
//!   Template using RayLib and RayGUI.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/BaseRayLib/lib/raylib/include/raylib.h"); 
const rl = @cImport({ 
  @cInclude("D:/workbench/zig_workbench/BaseRayLib/lib/raylib/include/raylib.h"); 
});
const gl = @cImport({ @cInclude("D:/workbench/zig_workbench/BaseRayLib/lib/raylib/include/rlgl.h"); });
const rm = @cImport({ @cInclude("D:/workbench/zig_workbench/BaseRayLib/lib/raylib/include/raymath.h"); });
const ui = @cImport({ 
  @cDefine("RAYGUI_IMPLEMENTATION","");
  @cInclude("D:/workbench/zig_workbench/BaseRayLib/lib/raylib/include/raygui.h"); 
});

const WINDOW_WIDTH: usize  = 800;
const WINDOW_HEIGHT: usize = 450;

/// Main function
pub fn main() void {
  // HideConsoleWindow();
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raylib [core] example + raygui - basic window");
  rl.SetTargetFPS(60);

  var showMessageBox: bool = true;

  while (!rl.WindowShouldClose())
  {
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    if (ui.GuiButton(ui.Rectangle{ .x=24, .y=24, .width=120,.height=30 }, "#191#Show Message") != 0) showMessageBox = true;

    if (showMessageBox) {
      const result: c_int = ui.GuiMessageBox(ui.Rectangle{ .x=85, .y=70, .width=250,.height=100 },
        "#191#Message Box", "Hi! This is a message!", "Nice;Cool");
      if (result >= 0) showMessageBox = false;
    }

    rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
    rl.EndDrawing();
  }

  rl.CloseWindow();
}

// ============================================================================
// Helpers
//
const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.kernel32;
};

fn HideConsoleWindow() void {
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [1024:0]win.CHAR = std.mem.zeroes([1024:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, 1024);
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
