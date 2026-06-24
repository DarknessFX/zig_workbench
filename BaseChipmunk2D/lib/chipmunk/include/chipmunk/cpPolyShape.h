// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpPolyShape cpPolyShape
/// @{

/// Allocate a polygon shape.
CP_EXPORT cpPolyShape* cpPolyShapeAlloc(void);
/// Initialize a polygon shape with rounded corners.
/// A convex hull will be created from the vertexes.
CP_EXPORT cpPolyShape* cpPolyShapeInit(cpPolyShape *poly, cpBody *body, int count, const cpVect *verts, cpTransform transform, cpFloat radius);
/// Initialize a polygon shape with rounded corners.
/// The vertexes must be convex with a counter-clockwise winding.
CP_EXPORT cpPolyShape* cpPolyShapeInitRaw(cpPolyShape *poly, cpBody *body, int count, const cpVect *verts, cpFloat radius);
/// Allocate and initialize a polygon shape with rounded corners.
/// A convex hull will be created from the vertexes.
CP_EXPORT cpShape* cpPolyShapeNew(cpBody *body, int count, const cpVect *verts, cpTransform transform, cpFloat radius);
/// Allocate and initialize a polygon shape with rounded corners.
/// The vertexes must be convex with a counter-clockwise winding.
CP_EXPORT cpShape* cpPolyShapeNewRaw(cpBody *body, int count, const cpVect *verts, cpFloat radius);

/// Initialize a box shaped polygon shape with rounded corners.
CP_EXPORT cpPolyShape* cpBoxShapeInit(cpPolyShape *poly, cpBody *body, cpFloat width, cpFloat height, cpFloat radius);
/// Initialize an offset box shaped polygon shape with rounded corners.
CP_EXPORT cpPolyShape* cpBoxShapeInit2(cpPolyShape *poly, cpBody *body, cpBB box, cpFloat radius);
/// Allocate and initialize a box shaped polygon shape.
CP_EXPORT cpShape* cpBoxShapeNew(cpBody *body, cpFloat width, cpFloat height, cpFloat radius);
/// Allocate and initialize an offset box shaped polygon shape.
CP_EXPORT cpShape* cpBoxShapeNew2(cpBody *body, cpBB box, cpFloat radius);

/// Get the number of verts in a polygon shape.
CP_EXPORT int cpPolyShapeGetCount(const cpShape *shape);
/// Get the @c ith vertex of a polygon shape.
CP_EXPORT cpVect cpPolyShapeGetVert(const cpShape *shape, int index);
/// Get the radius of a polygon shape.
CP_EXPORT cpFloat cpPolyShapeGetRadius(const cpShape *shape);

/// @}
