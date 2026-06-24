// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpSlideJoint cpSlideJoint
/// @{

/// Check if a constraint is a slide joint.
CP_EXPORT cpBool cpConstraintIsSlideJoint(const cpConstraint *constraint);

/// Allocate a slide joint.
CP_EXPORT cpSlideJoint* cpSlideJointAlloc(void);
/// Initialize a slide joint.
CP_EXPORT cpSlideJoint* cpSlideJointInit(cpSlideJoint *joint, cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB, cpFloat min, cpFloat max);
/// Allocate and initialize a slide joint.
CP_EXPORT cpConstraint* cpSlideJointNew(cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB, cpFloat min, cpFloat max);

/// Get the location of the first anchor relative to the first body.
CP_EXPORT cpVect cpSlideJointGetAnchorA(const cpConstraint *constraint);
/// Set the location of the first anchor relative to the first body.
CP_EXPORT void cpSlideJointSetAnchorA(cpConstraint *constraint, cpVect anchorA);

/// Get the location of the second anchor relative to the second body.
CP_EXPORT cpVect cpSlideJointGetAnchorB(const cpConstraint *constraint);
/// Set the location of the second anchor relative to the second body.
CP_EXPORT void cpSlideJointSetAnchorB(cpConstraint *constraint, cpVect anchorB);

/// Get the minimum distance the joint will maintain between the two anchors.
CP_EXPORT cpFloat cpSlideJointGetMin(const cpConstraint *constraint);
/// Set the minimum distance the joint will maintain between the two anchors.
CP_EXPORT void cpSlideJointSetMin(cpConstraint *constraint, cpFloat min);

/// Get the maximum distance the joint will maintain between the two anchors.
CP_EXPORT cpFloat cpSlideJointGetMax(const cpConstraint *constraint);
/// Set the maximum distance the joint will maintain between the two anchors.
CP_EXPORT void cpSlideJointSetMax(cpConstraint *constraint, cpFloat max);

/// @}
