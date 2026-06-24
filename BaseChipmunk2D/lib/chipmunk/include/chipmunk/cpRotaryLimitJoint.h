// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpRotaryLimitJoint cpRotaryLimitJoint
/// @{

/// Check if a constraint is a damped rotary springs.
CP_EXPORT cpBool cpConstraintIsRotaryLimitJoint(const cpConstraint *constraint);

/// Allocate a damped rotary limit joint.
CP_EXPORT cpRotaryLimitJoint* cpRotaryLimitJointAlloc(void);
/// Initialize a damped rotary limit joint.
CP_EXPORT cpRotaryLimitJoint* cpRotaryLimitJointInit(cpRotaryLimitJoint *joint, cpBody *a, cpBody *b, cpFloat min, cpFloat max);
/// Allocate and initialize a damped rotary limit joint.
CP_EXPORT cpConstraint* cpRotaryLimitJointNew(cpBody *a, cpBody *b, cpFloat min, cpFloat max);

/// Get the minimum distance the joint will maintain between the two anchors.
CP_EXPORT cpFloat cpRotaryLimitJointGetMin(const cpConstraint *constraint);
/// Set the minimum distance the joint will maintain between the two anchors.
CP_EXPORT void cpRotaryLimitJointSetMin(cpConstraint *constraint, cpFloat min);

/// Get the maximum distance the joint will maintain between the two anchors.
CP_EXPORT cpFloat cpRotaryLimitJointGetMax(const cpConstraint *constraint);
/// Set the maximum distance the joint will maintain between the two anchors.
CP_EXPORT void cpRotaryLimitJointSetMax(cpConstraint *constraint, cpFloat max);

/// @}
