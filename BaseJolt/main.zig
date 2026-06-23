//!zig-autodoc-section: BaseJolt.Main
//! BaseJolt\\main.zig :
//!   Template using Jolt Physics via JoltC wrapper.
//! Jolt from https://github.com/jrouwe/JoltPhysics
//! JoltC from https://github.com/SecondHalfGames/JoltC
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const jolt = @cImport({
  @cInclude("lib/JoltC/joltc.h");
});

const Hello_ObjectLayers = enum(c_uint) {
  NON_MOVING = 0,
  MOVING = 1,
  COUNT = 2,
};

const Hello_BroadPhaseLayers = enum(c_uint) {
  NON_MOVING = 0,
  MOVING = 1,
  COUNT = 2,
};

fn Hello_BPL_GetNumBroadPhaseLayers(_: ?*const anyopaque) callconv(.c) c_uint {
  return @intFromEnum(Hello_BroadPhaseLayers.COUNT);
}

fn Hello_BPL_GetBroadPhaseLayer(_: ?*const anyopaque, inLayer: jolt.JPC_ObjectLayer) callconv(.c) jolt.JPC_BroadPhaseLayer {
  return switch (inLayer) {
    @intFromEnum(Hello_ObjectLayers.NON_MOVING) => @intFromEnum(Hello_BroadPhaseLayers.NON_MOVING),
    @intFromEnum(Hello_ObjectLayers.MOVING) => @intFromEnum(Hello_BroadPhaseLayers.MOVING),
    else => 0,
  };
}

fn Hello_OVB_ShouldCollide(_: ?*const anyopaque, inLayer1: jolt.JPC_ObjectLayer, inLayer2: jolt.JPC_BroadPhaseLayer) callconv(.c) bool {
  return switch (inLayer1) {
    @intFromEnum(Hello_ObjectLayers.NON_MOVING) => inLayer2 == @intFromEnum(Hello_BroadPhaseLayers.MOVING),
    @intFromEnum(Hello_ObjectLayers.MOVING) => true,
    else => false,
  };
}

fn Hello_OVO_ShouldCollide(_: ?*const anyopaque, inLayer1: jolt.JPC_ObjectLayer, inLayer2: jolt.JPC_ObjectLayer) callconv(.c) bool {
  return switch (inLayer1) {
    @intFromEnum(Hello_ObjectLayers.NON_MOVING) => inLayer2 == @intFromEnum(Hello_ObjectLayers.MOVING),
    @intFromEnum(Hello_ObjectLayers.MOVING) => true,
    else => false,
  };
}

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main(_: std.process.Init) void {
  jolt.JPC_RegisterDefaultAllocator();
  jolt.JPC_FactoryInit();
  jolt.JPC_RegisterTypes();

  const temp_allocator = jolt.JPC_TempAllocatorImpl_new(10 * 1024 * 1024);
  const job_system = jolt.JPC_JobSystemThreadPool_new2(jolt.JPC_MAX_PHYSICS_JOBS, jolt.JPC_MAX_PHYSICS_BARRIERS);

  const bpl_fns: jolt.JPC_BroadPhaseLayerInterfaceFns = .{
    .GetNumBroadPhaseLayers = Hello_BPL_GetNumBroadPhaseLayers,
    .GetBroadPhaseLayer = Hello_BPL_GetBroadPhaseLayer,
  };
  const ovb_fns: jolt.JPC_ObjectVsBroadPhaseLayerFilterFns = .{
    .ShouldCollide = Hello_OVB_ShouldCollide,
  };
  const ovo_fns: jolt.JPC_ObjectLayerPairFilterFns = .{
    .ShouldCollide = Hello_OVO_ShouldCollide,
  };

  const broad_phase_layer_interface = jolt.JPC_BroadPhaseLayerInterface_new(null, bpl_fns);
  const object_vs_broad_phase_layer_filter = jolt.JPC_ObjectVsBroadPhaseLayerFilter_new(null, ovb_fns);
  const object_vs_object_layer_filter = jolt.JPC_ObjectLayerPairFilter_new(null, ovo_fns);

  const physics_system = jolt.JPC_PhysicsSystem_new();
  jolt.JPC_PhysicsSystem_Init(
    physics_system,
    1024,
    0,
    1024,
    1024,
    broad_phase_layer_interface,
    object_vs_broad_phase_layer_filter,
    object_vs_object_layer_filter,
  );

  const body_interface = jolt.JPC_PhysicsSystem_GetBodyInterface(physics_system);

  var floor_shape_settings: jolt.JPC_BoxShapeSettings = .{};
  jolt.JPC_BoxShapeSettings_default(&floor_shape_settings);
  floor_shape_settings.HalfExtent = jolt.JPC_Vec3{ .x = 100.0, .y = 1.0, .z = 100.0 };
  floor_shape_settings.Density = 500.0;

  var floor_shape: ?*jolt.JPC_Shape = null;
  var err: ?*jolt.JPC_String = null;
  if (!jolt.JPC_BoxShapeSettings_Create(&floor_shape_settings, &floor_shape, &err)) {
    std.debug.print("Fatal Floor Setup Error\n", .{});
    return;
  }

  var floor_settings: jolt.JPC_BodyCreationSettings = std.mem.zeroes(jolt.JPC_BodyCreationSettings);
  jolt.JPC_BodyCreationSettings_default(&floor_settings);
  floor_settings.Position = jolt.JPC_RVec3{ .x = 0.0, .y = -1.0, .z = 0.0 };
  floor_settings.MotionType = jolt.JPC_MOTION_TYPE_STATIC;
  floor_settings.ObjectLayer = @intFromEnum(Hello_ObjectLayers.NON_MOVING);
  floor_settings.Shape = floor_shape;

  const floor = jolt.JPC_BodyInterface_CreateBody(body_interface, &floor_settings);
  const floor_id = jolt.JPC_Body_GetID(floor);
  jolt.JPC_BodyInterface_AddBody(body_interface, floor_id, jolt.JPC_ACTIVATION_DONT_ACTIVATE);

  var sphere_shape_settings: jolt.JPC_SphereShapeSettings = std.mem.zeroes(jolt.JPC_SphereShapeSettings);
  jolt.JPC_SphereShapeSettings_default(&sphere_shape_settings);
  sphere_shape_settings.Radius = 0.5;

  var sphere_shape: ?*jolt.JPC_Shape = null;
  if (!jolt.JPC_SphereShapeSettings_Create(&sphere_shape_settings, &sphere_shape, &err)) {
    std.debug.print("Fatal Sphere Setup Error\n", .{});
    return;
  }

  var sphere_settings: jolt.JPC_BodyCreationSettings = std.mem.zeroes(jolt.JPC_BodyCreationSettings);
  jolt.JPC_BodyCreationSettings_default(&sphere_settings);
  sphere_settings.Position = jolt.JPC_RVec3{ .x = 0.0, .y = 2.0, .z = 0.0 };
  sphere_settings.MotionType = jolt.JPC_MOTION_TYPE_DYNAMIC;
  sphere_settings.ObjectLayer = @intFromEnum(Hello_ObjectLayers.MOVING);
  sphere_settings.Shape = sphere_shape;

  const sphere = jolt.JPC_BodyInterface_CreateBody(body_interface, &sphere_settings);
  const sphere_id = jolt.JPC_Body_GetID(sphere);
  jolt.JPC_BodyInterface_AddBody(body_interface, sphere_id, jolt.JPC_ACTIVATION_ACTIVATE);

  jolt.JPC_BodyInterface_SetLinearVelocity(body_interface, sphere_id, jolt.JPC_Vec3{ .x = 0.0, .y = -5.0, .z = 0.0 });

  jolt.JPC_PhysicsSystem_OptimizeBroadPhase(physics_system);

  const delta_time: f32 = 1.0 / 60.0;
  var step: u32 = 0;

  std.debug.print("\n--- Running Ported JoltC Simulation ---\n", .{});

  while (jolt.JPC_BodyInterface_IsActive(body_interface, sphere_id)) {
    step += 1;

    const pos = jolt.JPC_BodyInterface_GetCenterOfMassPosition(body_interface, sphere_id);
    const vel = jolt.JPC_BodyInterface_GetLinearVelocity(body_interface, sphere_id);

    std.debug.print("Step {d:02}: Position = ({d:.4}, {d:.4}, {d:.4}), Velocity = ({d:.4}, {d:.4}, {d:.4})\n", .{
      step, pos.x, pos.y, pos.z, vel.x, vel.y, vel.z,
    });

    _ = jolt.JPC_PhysicsSystem_Update(physics_system, delta_time, 1, temp_allocator, @ptrCast(job_system));
  }

  jolt.JPC_BodyInterface_RemoveBody(body_interface, sphere_id);
  jolt.JPC_BodyInterface_DestroyBody(body_interface, sphere_id);

  jolt.JPC_BodyInterface_RemoveBody(body_interface, floor_id);
  jolt.JPC_BodyInterface_DestroyBody(body_interface, floor_id);

  jolt.JPC_PhysicsSystem_delete(physics_system);
  jolt.JPC_BroadPhaseLayerInterface_delete(broad_phase_layer_interface);
  jolt.JPC_ObjectVsBroadPhaseLayerFilter_delete(object_vs_broad_phase_layer_filter);
  jolt.JPC_ObjectLayerPairFilter_delete(object_vs_object_layer_filter);

  jolt.JPC_JobSystemThreadPool_delete(job_system);
  jolt.JPC_TempAllocatorImpl_delete(temp_allocator);

  jolt.JPC_UnregisterTypes();
  jolt.JPC_FactoryDelete();

  std.debug.print("\nSimulation complete! Clean exit achieved.\n", .{});
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================


//#endregion ==================================================================
//=============================================================================
