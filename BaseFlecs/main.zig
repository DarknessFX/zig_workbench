//!zig-autodoc-section: BaseFlecs.Main
//! BaseFlecs//Main.zig :
//!   Template project with FLECS entity component system.
//!   Flecs/Examples/Hello_World ported to Zig.
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const ecs = @cImport({
  @cDefine("FLECS_NO_CPP", "1");
  @cDefine("FLECS_USE_OS_ALLOC", "1");
  // @cDefine("FLECS_NO_LOG", "1");
  // @cDefine("FLECS_NO_DEBUG", "1");
  // @cDefine("FLECS_NO_HTTP", "1");
  // @cDefine("FLECS_NO_REST", "1");
  @cInclude("lib/flecs/flecs.h");
});

const Position = extern struct { x: f64, y: f64 };
const Velocity = extern struct { x: f64, y: f64 };

//=============================================================================
//#region MARK: Main
//=============================================================================
pub fn main() !void {
  const world = ecs.ecs_init() orelse return error.Failed;
  defer _ = ecs.ecs_fini(world);

  // === Components ===
  const pos_id = registerComponent(world, Position, "Position");
  const vel_id = registerComponent(world, Velocity, "Velocity");

  // === Tags ===
  const eats_id = ecs.ecs_entity_init(world, &ecs.ecs_entity_desc_t{
    .name = "Eats",
    .use_low_id = true,
  });
  const apples_id = ecs.ecs_entity_init(world, &ecs.ecs_entity_desc_t{
    .name = "Apples",
    .use_low_id = true,
  });

  // === System ===
  var sys_entity_desc: ecs.ecs_entity_desc_t = .{
    .name = "Move",
    .use_low_id = true,
  };
  const system_entity = ecs.ecs_entity_init(world, &sys_entity_desc);
  var sys_desc: ecs.ecs_system_desc_t = .{
    .entity = system_entity,
    .phase = ecs.EcsOnUpdate,
    .callback = Move,
  };
  sys_desc.query.terms[0].id = pos_id;
  sys_desc.query.terms[0].inout = ecs.EcsInOut;
  sys_desc.query.terms[1].id = vel_id;
  sys_desc.query.terms[1].inout = ecs.EcsIn;
  _ = ecs.ecs_system_init(world, &sys_desc);

  // === Entity ===
  const bob = ecs.ecs_entity_init(world, &ecs.ecs_entity_desc_t{
    .name = "Bob",
    .use_low_id = true,
  });
  _ = ecs.ecs_add_id(world, bob, pos_id);
  _ = ecs.ecs_add_id(world, bob, vel_id);

  _ = ecs.ecs_set_id(world, bob, pos_id, @sizeOf(Position), &Position{ .x = 0, .y = 0 });
  _ = ecs.ecs_set_id(world, bob, vel_id, @sizeOf(Velocity), &Velocity{ .x = 1, .y = 2 });
  _ = ecs.ecs_add_pair(world, bob, eats_id, apples_id);

  std.debug.print("Bob = {d}, pos_id = {d}, vel_id = {d}\n", .{ bob, pos_id, vel_id });

  // === Run systems ===
  std.debug.print("=== Progress 1 ===\n", .{});
  _ = ecs.ecs_progress(world, 0);
  std.debug.print("=== Progress 2 ===\n", .{});
  _ = ecs.ecs_progress(world, 0);

  if (ecs.ecs_get_id(world, bob, pos_id)) |ptr| {
    const p: *const Position = @ptrCast(@alignCast(ptr));
    std.debug.print("Bob's position is {d}, {d}\n", .{ p.x, p.y });
  }
}

//=============================================================================
//#region MARK: registerComponent
//=============================================================================
fn registerComponent(world: *ecs.ecs_world_t, comptime T: type, name: [:0]const u8) ecs.ecs_entity_t {
  var ed: ecs.ecs_entity_desc_t = .{};
  ed.name = name.ptr;
  ed.symbol = name.ptr;
  ed.use_low_id = true;

  const entity = ecs.ecs_entity_init(world, &ed);
  if (entity == 0) @panic("entity init failed");

  var cd: ecs.ecs_component_desc_t = .{};
  cd.entity = entity;
  cd.type.size = @sizeOf(T);
  cd.type.alignment = @alignOf(T);

  const comp_id = ecs.ecs_component_init(world, &cd);
  if (comp_id == 0) @panic("component init failed");

  return comp_id;
}

//=============================================================================
//#region MARK: Move
//=============================================================================
fn Move(it: [*c]ecs.ecs_iter_t) callconv(.c) void {
  const count = @as(usize, @intCast(it.*.count));
  if (count == 0) return;

  const p = ecs.ecs_field(it, Position, 0) orelse return;
  const v = ecs.ecs_field(it, Velocity, 1) orelse return;

  if (ecs.ecs_table_str(it.*.world, it.*.table)) |type_str| {
    if (type_str) |str| {
      defer {
        if (ecs.ecs_os_api.free_) |free_fn| {
          free_fn(str);
        }
      }
    }
  }

  std.debug.print("Move called on table with {d} entities!\n", .{it.*.count});
  for (0..@as(usize, @intCast(it.*.count))) |i| {
    p[i].x += v[i].x;
    p[i].y += v[i].y;
  }
}


//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================



//#endregion ==================================================================
//=============================================================================