//!zig-autodoc-section: Basebox3D\\main.zig
//! main.zig :
//!  Template using Box3D physics engine.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

const b3 = @cImport({
  @cInclude("lib/box3D/box3D.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main(_: std.process.Init) void {
  var worldDef: b3.b3WorldDef = b3.b3DefaultWorldDef();
  worldDef.gravity = b3.b3Vec3{ .x = 0.0, .y = -9.81, .z = 0.0 };
  const worldId: b3.b3WorldId = b3.b3CreateWorld(&worldDef);

  var groundBodyDef: b3.b3BodyDef = b3.b3DefaultBodyDef();
  groundBodyDef.position = b3.b3Vec3{ .x = 0.0, .y = -10.0, .z = 0.0 };
  const groundId: b3.b3BodyId = b3.b3CreateBody(worldId, &groundBodyDef);

  const groundBox: b3.b3BoxHull = b3.b3MakeBoxHull(50.0, 10.0, 50.0);
  const groundShapeDef: b3.b3ShapeDef = b3.b3DefaultShapeDef();
  _ = b3.b3CreateHullShape(groundId, &groundShapeDef, &groundBox.base);

  var bodyDef: b3.b3BodyDef = b3.b3DefaultBodyDef();
  bodyDef.type = b3.b3_dynamicBody;
  bodyDef.position = b3.b3Vec3{ .x = 0.0, .y = 6.0, .z = 0.0 };
  const bodyId: b3.b3BodyId = b3.b3CreateBody(worldId, &bodyDef);

  const dynamicBox: b3.b3BoxHull = b3.b3MakeCubeHull(1.0);
  var shapeDef: b3.b3ShapeDef = b3.b3DefaultShapeDef();
  shapeDef.density = 1.0;
  shapeDef.baseMaterial.friction = 0.3;
  _ = b3.b3CreateHullShape(bodyId, &shapeDef, &dynamicBox.base);

  std.debug.print("Cube falling from: Y {d:4.2} , with world gravity: Y {d:4.2} .\n=== 90 Steps ===\n", .{ bodyDef.position.y, worldDef.gravity.y });

  const timeStep: f32 = 1.0 / 60.0;
  const subStepCount: c_int = 4;
  for (0..90) |_| {
    b3.b3World_Step(worldId, timeStep, subStepCount);

    const position: b3.b3Vec3 = b3.b3Body_GetPosition(bodyId);
    // const rotation: b3.b3Quat = b3.b3Body_GetRotation(bodyId);

    std.debug.print("Position: {d:4.2} {d:4.2} {d:4.2}\n", .{ //   | Quaternion Rotation: {d:4.2} {d:4.2} {d:4.2} {d:4.2}\n", .{
      position.x, position.y, position.z,
      // rotation.v.x, rotation.v.y, rotation.v.z, rotation.s
    });
  }
  std.debug.print("=== Finished! ===\n", .{ });

  b3.b3DestroyWorld(worldId);
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " " {

}

//#endregion ==================================================================
//=============================================================================
