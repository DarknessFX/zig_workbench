//!zig-autodoc-section: BaseSFML2.Main
//! BaseSFML2//main.zig :
//!  Template using SFML2.6.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE Download https://www.sfml-dev.org/download/csfml/ 
// NOTE and copy all .DLL to your ZIG PATH.

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseCSFML2/lib/CSFML2/include/graphics.h");
const sfml = @cImport({
  @cInclude("lib/CSFML2/include/Graphics.h");
  @cInclude("lib/CSFML2/include/Window.h");
  @cInclude("lib/CSFML2/include/System.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() u8  {
  HideConsoleWindow();
  
  // Create the main window
  const mode = sfml.sfVideoMode{ .width = 800, .height = 600, .bitsPerPixel = 32 };
  const window = sfml.sfRenderWindow_create(mode, "BaseSFML2", sfml.sfDefaultStyle, null) orelse {
    std.debug.print("Failed to create window\n", .{});
    return 1;
  };
  defer sfml.sfRenderWindow_destroy(window);

  // Create the circle
  const circle = sfml.sfCircleShape_create() orelse {
    std.debug.print("Failed to create circle\n", .{});
    return 2;
  };
  defer sfml.sfCircleShape_destroy(circle);

  sfml.sfCircleShape_setRadius(circle, 100);
  sfml.sfCircleShape_setFillColor(circle, sfml.sfRed);

  // Main loop
  var time: f32 = 0.0;
  var event: sfml.sfEvent = undefined;
  while (sfml.sfRenderWindow_isOpen(window) == 1) {
    while (sfml.sfRenderWindow_pollEvent(window, &event) != 0) {
      if (event.type == sfml.sfEvtClosed) {
        sfml.sfRenderWindow_close(window);
      }
    }

    // Clear screen
    sfml.sfRenderWindow_clear(window, sfml.sfBlack);

    // Update time for animation
    time += 0.01;

    // Animate the circle position using sine and cosine
    const x = 300 + 250 * @sin(time);
    const y = 200 + 150 * @cos(time * 0.5); // Different frequency for y movement
    sfml.sfCircleShape_setPosition(circle, .{ .x = x, .y = y });

    // Draw the circle
    sfml.sfRenderWindow_drawCircleShape(window, circle, null);

    // Update the window
    sfml.sfRenderWindow_display(window);

    // Add a small delay to control frame rate (optional)
    sfml.sfSleep(sfml.sfSeconds(0.016)); // Approx. 60 FPS
  }

  return 0;
}


//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
const win = std.os.windows;

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
) callconv(.winapi) win.DWORD;

pub extern "kernel32" fn FindWindowA(
  lpClassName: ?win.LPSTR,
  lpWindowName: ?win.LPSTR,
) callconv(.winapi) win.HWND;

pub const SW_HIDE = 0;
pub extern "user32" fn ShowWindow(
  hWnd: win.HWND,
  nCmdShow: i32
) callconv(.winapi) win.BOOL;

pub const MB_OK = 0x00000000;
pub extern "user32" fn MessageBoxA(
  hWnd: ?win.HWND,
  lpText: [*:0]const u8,
  lpCaption: [*:0]const u8,
  uType: win.UINT
) callconv(.winapi) win.INT;

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================