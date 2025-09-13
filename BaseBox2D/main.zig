//!zig-autodoc-section: BaseBox2D\\main.zig
//! main.zig :
//!  Template for a console program that hide the console window.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseBox2D/lib/box2d/box2d.h");
const box = @cImport({
  @cInclude("lib/box2d/box2d.h");
});

const Entity = struct {
  bodyId: box.b2BodyId,
  extent: box.b2Vec2,
};

const width: c_int = 1920;
const height: c_int = 1080;
const GROUND_COUNT: c_int = 14;
const BOX_COUNT: c_int = 10;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() u8 {
  //HideConsoleWindow();
  const lengthUnitsPerMeter = 128.0;
  box.b2SetLengthUnitsPerMeter(lengthUnitsPerMeter);
  var worldDef = box.b2DefaultWorldDef();
  worldDef.gravity.y = 9.8 * lengthUnitsPerMeter;
  const worldId = box.b2CreateWorld(&worldDef);
  const groundExtent = box.b2Vec2{ .x = 0.5 * 48, .y = 0.5 * 48 };
  const boxExtent = box.b2Vec2{ .x = 0.5 * 48, .y = 0.5 * 48 };
  const groundPolygon = box.b2MakeBox(groundExtent.x, groundExtent.y);
  const boxPolygon = box.b2MakeBox(boxExtent.x, boxExtent.y);

  var groundEntities: [GROUND_COUNT]Entity = undefined;
  for (0..GROUND_COUNT) |i| {
    var entity = &groundEntities[i];
    var bodyDef = box.b2DefaultBodyDef();
    bodyDef.position = box.b2Vec2{ .x = (2.0 * @as(f32, @floatFromInt(i)) + 2.0) * groundExtent.x, .y = height - groundExtent.y - 100.0 };
    entity.bodyId = box.b2CreateBody(worldId, &bodyDef);
    var shapeDef = box.b2DefaultShapeDef();
    _ = box.b2CreatePolygonShape(entity.bodyId, &shapeDef, &groundPolygon);
  }

  var boxEntities: [BOX_COUNT]Entity = undefined;
  var boxIndex: usize = 0;
  for (0..4) |i| {
    const y = height - groundExtent.y - 100.0 - (2.5 * @as(f32, @floatFromInt(i)) + 2.0) * boxExtent.y - 20.0;

    for (i..4) |j| {
      const x = 0.5 * @as(f32, @floatFromInt(width)) + (3.0 * @as(f32, @floatFromInt(j)) - @as(f32, @floatFromInt(i)) - 3.0) * boxExtent.x;
      var entity = &boxEntities[boxIndex];
      var bodyDef = box.b2DefaultBodyDef();
      bodyDef.type = box.b2_dynamicBody;
      bodyDef.position = box.b2Vec2{ .x = x, .y = y };
      entity.bodyId = box.b2CreateBody(worldId, &bodyDef);
      var shapeDef = box.b2DefaultShapeDef();
      _ = box.b2CreatePolygonShape(entity.bodyId, &shapeDef, &boxPolygon);
      boxIndex += 1;
    }
  }

  var i: u8 = 0;
  const deltaTime: f32 = 0.00016;
  while (i < 100) {
    box.b2World_Step(worldId, deltaTime, 4);
    for (0..BOX_COUNT) |j| {
      std.debug.print("ID:{d} - x:{d} y:{d}\n", .{ 
        groundEntities[j].bodyId.index1, 
        groundEntities[j].extent.x, 
        groundEntities[j].extent.y });
    }
    win.kernel32.Sleep(@intFromFloat(16 * std.time.ns_per_ms));
    i += 1;
  }

  return 0;
}

//#endregion ==================================================================
//#region MARK: WINAPI
//=============================================================================
//  _ = MessageBoxA(null, "Console window is hide.", "BaseBox2D", MB_OK);
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