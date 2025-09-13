//!zig-autodoc-section: BaseChipmunk2D\\main.zig
//! main.zig :
//!  Template for Chipmunk2D physics.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseChipmunk/lib/chipmunk/include/chipmunk.h");
const cp = @cImport({
  @cInclude("lib/chipmunk/include/chipmunk.h");
});

// Define custom collision types
const BALL_COLLISION_TYPE: cp.cpCollisionType = 1;
const GROUND_COLLISION_TYPE: cp.cpCollisionType = 2;
var collision_detected: bool = false;
var collision_pos: cp.cpVect = undefined;
const collision_tolerance: f32 = 0.1;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !u8 {
  //HideConsoleWindow();

  // Create a space
  const space: ?*cp.cpSpace = cp.cpSpaceNew();
  defer cp.cpSpaceFree(space);

  // Assuming Chipmunk provides a function to set gravity
  cp.cpSpaceSetGravity(space, cp.cpVect{ .x = 0, .y = -100 });

  // Create a static body for the ground
  const ground = cp.cpBodyNewStatic();
  _ = cp.cpSpaceAddBody(space, ground); // Add the body first
  const groundShape = cp.cpSegmentShapeNew(ground, cp.cpVect{ .x = -20, .y = -15 }, cp.cpVect{ .x = 20, .y = -15 }, 0);
  cp.cpShapeSetElasticity(groundShape, 0.0);
  cp.cpShapeSetFriction(groundShape, 1);
  cp.cpShapeSetCollisionType(groundShape, GROUND_COLLISION_TYPE);
  _ = cp.cpSpaceAddShape(space, groundShape);

  // Create a dynamic body - a ball
  const ballBody = cp.cpBodyNew(1.0, cp.cpMomentForCircle(1.0, 0, 15, cp.cpVect{ .x = 0, .y = 0 }));
  _ = cp.cpSpaceAddBody(space, ballBody);
  const ballShape = cp.cpCircleShapeNew(ballBody, 15, cp.cpVect{ .x = 0, .y = 0 });
  cp.cpBodySetMass(ballBody, 1.0);
  cp.cpShapeSetElasticity(ballShape, 0.0);
  cp.cpShapeSetFriction(ballShape, 0.7);
  cp.cpShapeSetCollisionType(ballShape, BALL_COLLISION_TYPE);
  _ = cp.cpSpaceAddShape(space, ballShape);

  // Set initial position for the ball
  cp.cpBodySetPosition(ballBody, cp.cpVect{ .x = 0, .y = 15 });

  // Set up collision detection
  var handler: *cp.struct_cpCollisionHandler = cp.cpSpaceAddCollisionHandler(space, BALL_COLLISION_TYPE, GROUND_COLLISION_TYPE);
  handler.preSolveFunc = ballGroundCollision;

  // Simulate physics
  const timeStep = 1.0 / 60.0; // 60 FPS
  const steps = 100;  // Simulate for 100 steps

  for (0..steps) |_| {
    cp.cpSpaceStep(space, timeStep);
    const pos = cp.cpBodyGetPosition(ballBody);
    std.debug.print("Ball position: x={d:.2}, y={d:.2}\n", .{pos.x, pos.y});

    if (collision_detected) {
      if (@abs(collision_pos.y - pos.y) > collision_tolerance) { 
        collision_pos = pos;
        collision_detected = false;
      } else {
        std.debug.print("Ball has settled at position: x={d:.2}, y={d:.2}\n", .{pos.x, pos.y});
        break;
      }
    }    
  }

  return 0;
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
export fn ballGroundCollision(arbiter: ?*cp.cpArbiter, space: ?*cp.cpSpace, data: ?*anyopaque) callconv(.c) cp.cpBool {
  _ = arbiter; _ = space; _ = data;
  collision_detected = true;
  std.debug.print("Collision detected.\n", .{ });
  return cp.cpTrue;
}

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
// _ = MessageBoxA(null, "Console window is hide.", "BaseChipmunk2D", MB_OK);
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