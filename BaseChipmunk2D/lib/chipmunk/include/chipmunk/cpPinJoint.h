// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpPinJoint cpPinJoint
/// @{

/// Check if a constraint is a pin joint.
CP_EXPORT cpBool cpConstraintIsPinJoint(const cpConstraint *constraint);

/// Allocate a pin joint.
CP_EXPORT cpPinJoint* cpPinJointAlloc(void);
/// Initialize a pin joint.
CP_EXPORT cpPinJoint* cpPinJointInit(cpPinJoint *joint, cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB);
/// Allocate and initialize a pin joint.
CP_EXPORT cpConstraint* cpPinJointNew(cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB);

/// Get the location of the first anchor relative to the first body.
CP_EXPORT cpVect cpPinJointGetAnchorA(const cpConstraint *constraint);
/// Set the location of the first anchor relative to the first body.
CP_EXPORT void cpPinJointSetAnchorA(cpConstraint *constraint, cpVect anchorA);

/// Get the location of the second anchor relative to the second body.
CP_EXPORT cpVect cpPinJointGetAnchorB(const cpConstraint *constraint);
/// Set the location of the second anchor relative to the second body.
CP_EXPORT void cpPinJointSetAnchorB(cpConstraint *constraint, cpVect anchorB);

/// Get the distance the joint will maintain between the two anchors.
CP_EXPORT cpFloat cpPinJointGetDist(const cpConstraint *constraint);
/// Set the distance the joint will maintain between the two anchors.
CP_EXPORT void cpPinJointSetDist(cpConstraint *constraint, cpFloat dist);

///@}
