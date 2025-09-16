//!zig-autodoc-section: BaseFreeglut.Main
//! BaseFreeglut\\main.zig :
//!   Template for a program using freeglut.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");
const fg = @cImport({
  @cInclude("lib/freeglut/include/GL/freeglut.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

fn display() callconv(.c) void {
  fg.glClear(fg.GL_COLOR_BUFFER_BIT);
  fg.glColor3f(1.0, 0.0, 0.0);
  fg.glBegin(fg.GL_TRIANGLES);
  fg.glVertex2f(-0.5, -0.5);
  fg.glVertex2f(0.5, -0.5);
  fg.glVertex2f(0.0, 0.5);
  fg.glEnd();
  fg.glFlush();
}

pub fn main() void {
  var argc: c_int = 0;
  var argv = "zigapp";
  fg.glutInit(&argc, @ptrCast(&argv));
  fg.glutInitDisplayMode(fg.GLUT_SINGLE | fg.GLUT_RGB);
  fg.glutInitWindowSize(1280, 720);
  _ = fg.glutCreateWindow("Freeglut + Zig");
  fg.glutDisplayFunc(display);
  fg.glutMainLoop();
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " " { }

//#endregion ==================================================================
//=============================================================================