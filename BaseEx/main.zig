const std = @import("std");

const win = struct {
  usingnamespace std.os.windows;
  usingnamespace std.os.windows.user32;
  usingnamespace std.os.windows.kernel32;
  usingnamespace std.os.windows.gdi32;
};

pub fn main() void {
  // Hide console window
  const BUF_TITLE = 1024;
  var hwndFound: win.HWND = undefined;
  var pszWindowTitle: [BUF_TITLE:0]win.CHAR = std.mem.zeroes([BUF_TITLE:0]win.CHAR); 

  _ = GetConsoleTitleA(&pszWindowTitle, BUF_TITLE);
  hwndFound=FindWindowA(null, &pszWindowTitle);
  _ = win.ShowWindow(hwndFound, win.SW_HIDE);
  // ===
  
  
  
}

pub extern "kernel32" fn GetConsoleTitleA(
    lpConsoleTitle: win.LPSTR,
    nSize: win.DWORD,
) callconv(win.WINAPI) win.DWORD;

pub extern "kernel32" fn FindWindowA(
    lpClassName: ?win.LPSTR,
    lpWindowName: ?win.LPSTR,
) callconv(win.WINAPI) win.HWND;


//
// Tests section
//
test " " {
}