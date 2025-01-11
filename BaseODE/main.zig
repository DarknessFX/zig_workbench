//!zig-autodoc-section: BaseODE\\main.zig
//! main.zig :
//!	  Template ODE physics.
// Build using Zig 0.13.0

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseODE/lib/ode/ode.h");
const ode = @cImport({
  @cInclude("lib/ode/ode.h");
});

var world: ode.dWorldID = undefined;
var contactgroup: ode.dJointGroupID = undefined;
var collision_detected: bool = false;

pub fn main() !u8 {
  //HideConsoleWindow();

  // Initialize ODE
  ode.dInitODE();
  defer ode.dCloseODE();
  world = ode.dWorldCreate();
  defer ode.dWorldDestroy(world);
  const space = ode.dHashSpaceCreate(null);
  defer ode.dSpaceDestroy(space);

  // Set gravity
  ode.dWorldSetGravity(world, 0, -9.81, 0);

  const body = ode.dBodyCreate(world);
  defer ode.dBodyDestroy(body);

  // Set mass for the body
  var mass: ode.dMass = undefined;
  ode.dMassSetBox(&mass, 1.0, 1.0, 1.0, 1.0);
  ode.dMassAdjust(&mass, 1.0);
  ode.dBodySetMass(body, &mass);

  // Create a geometry for collision
  const geom = ode.dCreateBox(space, 1.0, 1.0, 1.0);
  defer ode.dGeomDestroy(geom);
  ode.dGeomSetBody(geom, body);
  ode.dBodySetPosition(body, 0.0, 10.0, 0.0);
  
  // Add ground
  const ground_geom = ode.dCreatePlane(space, 0, 1, 0, 0); // plane equation: ax + by + cz = d, here y=0 is ground
  _ = ground_geom;

  // Collision group
  contactgroup = ode.dJointGroupCreate(0);
  defer ode.dJointGroupDestroy(contactgroup);
  var collision_pos: [3]f64 = .{0.0,0.0,0.0};
  const collision_tolerance: f64 = 0.001;

  // Simulation loop
  var i: usize = 0;
  while (i < 100) : (i += 1) {
    ode.dSpaceCollide(space, null, nearCallback);
    _ = ode.dWorldStep(world, 0.05);
    ode.dJointGroupEmpty(contactgroup);
        
    const pos: [3]f64 = ode.dBodyGetPosition(body)[0..3].*;
    std.debug.print("Body position: {d:.2}, {d:.2}, {d:.2}\n", .{pos[0], pos[1], pos[2]});

    if (collision_detected) {
      if (collision_pos[0] - pos[0] < collision_tolerance and
          collision_pos[1] - pos[1] < collision_tolerance and
          collision_pos[2] - pos[2] < collision_tolerance) {
        std.debug.print("Box has reached the ground at position: {d:.2}, {d:.2}, {d:.2}\n", .{pos[0], pos[1], pos[2]});
        std.debug.print("Collision tolerance reached.\n", .{ });
        break;
      } else {
        collision_pos = pos;
        collision_detected = false;
      }
    }
  }

  return 0;
}

// Near callback function for handling collisions
export fn nearCallback(data: ?*anyopaque, o1: ode.dGeomID, o2: ode.dGeomID) callconv(.C) void {
  _ = data;
  var contact: [10]ode.dContact = undefined;
  const numc = ode.dCollide(o1, o2, 10, &contact[0].geom, @sizeOf(ode.dContact));

  if (numc <= 0) return;
  for (0..@intCast(numc)) |i| {
    contact[i].surface.mode = ode.dContactBounce | ode.dContactSoftERP | ode.dContactSoftCFM;
    contact[i].surface.mu = 50.0; // friction
    contact[i].surface.mu2 = 50.0;
    contact[i].surface.bounce = 0.1; // elasticity
    contact[i].surface.bounce_vel = 0.1;
    contact[i].surface.soft_erp = 0.96;
    contact[i].surface.soft_cfm = 0.04;
    
    const joint = ode.dJointCreateContact(world, contactgroup, &contact[i]);
    ode.dJointAttach(joint, ode.dGeomGetBody(contact[i].geom.g1), ode.dGeomGetBody(contact[i].geom.g2));
  }
  collision_detected = true;
  std.debug.print("Collision detected.\n", .{});
}

// ============================================================================
// Helpers
//
//  _ = MessageBoxA(null, "Console window is hide.", "BaseODE", MB_OK);
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