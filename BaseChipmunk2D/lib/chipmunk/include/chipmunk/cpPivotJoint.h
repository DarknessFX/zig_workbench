// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpPivotJoint cpPivotJoint
/// @{

/// Check if a constraint is a slide joint.
CP_EXPORT cpBool cpConstraintIsPivotJoint(const cpConstraint *constraint);

/// Allocate a pivot joint
CP_EXPORT cpPivotJoint* cpPivotJointAlloc(void);
/// Initialize a pivot joint.
CP_EXPORT cpPivotJoint* cpPivotJointInit(cpPivotJoint *joint, cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB);
/// Allocate and initialize a pivot joint.
CP_EXPORT cpConstraint* cpPivotJointNew(cpBody *a, cpBody *b, cpVect pivot);
/// Allocate and initialize a pivot joint with specific anchors.
CP_EXPORT cpConstraint* cpPivotJointNew2(cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB);

/// Get the location of the first anchor relative to the first body.
CP_EXPORT cpVect cpPivotJointGetAnchorA(const cpConstraint *constraint);
/// Set the location of the first anchor relative to the first body.
CP_EXPORT void cpPivotJointSetAnchorA(cpConstraint *constraint, cpVect anchorA);

/// Get the location of the second anchor relative to the second body.
CP_EXPORT cpVect cpPivotJointGetAnchorB(const cpConstraint *constraint);
/// Set the location of the second anchor relative to the second body.
CP_EXPORT void cpPivotJointSetAnchorB(cpConstraint *constraint, cpVect anchorB);

/// @}
