// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpGearJoint cpGearJoint
/// @{

/// Check if a constraint is a damped rotary springs.
CP_EXPORT cpBool cpConstraintIsGearJoint(const cpConstraint *constraint);

/// Allocate a gear joint.
CP_EXPORT cpGearJoint* cpGearJointAlloc(void);
/// Initialize a gear joint.
CP_EXPORT cpGearJoint* cpGearJointInit(cpGearJoint *joint, cpBody *a, cpBody *b, cpFloat phase, cpFloat ratio);
/// Allocate and initialize a gear joint.
CP_EXPORT cpConstraint* cpGearJointNew(cpBody *a, cpBody *b, cpFloat phase, cpFloat ratio);

/// Get the phase offset of the gears.
CP_EXPORT cpFloat cpGearJointGetPhase(const cpConstraint *constraint);
/// Set the phase offset of the gears.
CP_EXPORT void cpGearJointSetPhase(cpConstraint *constraint, cpFloat phase);

/// Get the angular distance of each ratchet.
CP_EXPORT cpFloat cpGearJointGetRatio(const cpConstraint *constraint);
/// Set the ratio of a gear joint.
CP_EXPORT void cpGearJointSetRatio(cpConstraint *constraint, cpFloat ratio);

/// @}
