// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/* This header defines a number of "unsafe" operations on Chipmunk objects.
 * In this case "unsafe" is referring to operations which may reduce the
 * physical accuracy or numerical stability of the simulation, but will not
 * cause crashes.
 *
 * The prime example is mutating collision shapes. Chipmunk does not support
 * this directly. Mutating shapes using this API will caused objects in contact
 * to be pushed apart using Chipmunk's overlap solver, but not using real
 * persistent velocities. Probably not what you meant, but perhaps close enough.
 */

/// @defgroup unsafe Chipmunk Unsafe Shape Operations
/// These functions are used for mutating collision shapes.
/// Chipmunk does not have any way to get velocity information on changing shapes,
/// so the results will be unrealistic. You must explicity include the chipmunk_unsafe.h header to use them.
/// @{

#ifndef CHIPMUNK_UNSAFE_H
#define CHIPMUNK_UNSAFE_H

#ifdef __cplusplus
extern "C" {
#endif

/// Set the radius of a circle shape.
CP_EXPORT void cpCircleShapeSetRadius(cpShape *shape, cpFloat radius);
/// Set the offset of a circle shape.
CP_EXPORT void cpCircleShapeSetOffset(cpShape *shape, cpVect offset);

/// Set the endpoints of a segment shape.
CP_EXPORT void cpSegmentShapeSetEndpoints(cpShape *shape, cpVect a, cpVect b);
/// Set the radius of a segment shape.
CP_EXPORT void cpSegmentShapeSetRadius(cpShape *shape, cpFloat radius);

/// Set the vertexes of a poly shape.
CP_EXPORT void cpPolyShapeSetVerts(cpShape *shape, int count, cpVect *verts, cpTransform transform);
CP_EXPORT void cpPolyShapeSetVertsRaw(cpShape *shape, int count, cpVect *verts);
/// Set the radius of a poly shape.
CP_EXPORT void cpPolyShapeSetRadius(cpShape *shape, cpFloat radius);

#ifdef __cplusplus
}
#endif
#endif
/// @}
