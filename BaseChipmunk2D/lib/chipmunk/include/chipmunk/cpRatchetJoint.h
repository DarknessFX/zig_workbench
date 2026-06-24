// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpRatchetJoint cpRatchetJoint
/// @{

/// Check if a constraint is a damped rotary springs.
CP_EXPORT cpBool cpConstraintIsRatchetJoint(const cpConstraint *constraint);

/// Allocate a ratchet joint.
CP_EXPORT cpRatchetJoint* cpRatchetJointAlloc(void);
/// Initialize a ratched joint.
CP_EXPORT cpRatchetJoint* cpRatchetJointInit(cpRatchetJoint *joint, cpBody *a, cpBody *b, cpFloat phase, cpFloat ratchet);
/// Allocate and initialize a ratchet joint.
CP_EXPORT cpConstraint* cpRatchetJointNew(cpBody *a, cpBody *b, cpFloat phase, cpFloat ratchet);

/// Get the angle of the current ratchet tooth.
CP_EXPORT cpFloat cpRatchetJointGetAngle(const cpConstraint *constraint);
/// Set the angle of the current ratchet tooth.
CP_EXPORT void cpRatchetJointSetAngle(cpConstraint *constraint, cpFloat angle);

/// Get the phase offset of the ratchet.
CP_EXPORT cpFloat cpRatchetJointGetPhase(const cpConstraint *constraint);
/// Get the phase offset of the ratchet.
CP_EXPORT void cpRatchetJointSetPhase(cpConstraint *constraint, cpFloat phase);

/// Get the angular distance of each ratchet.
CP_EXPORT cpFloat cpRatchetJointGetRatchet(const cpConstraint *constraint);
/// Set the angular distance of each ratchet.
CP_EXPORT void cpRatchetJointSetRatchet(cpConstraint *constraint, cpFloat ratchet);

/// @}
