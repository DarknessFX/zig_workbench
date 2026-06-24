// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpGrooveJoint cpGrooveJoint
/// @{

/// Check if a constraint is a slide joint.
CP_EXPORT cpBool cpConstraintIsGrooveJoint(const cpConstraint *constraint);

/// Allocate a groove joint.
CP_EXPORT cpGrooveJoint* cpGrooveJointAlloc(void);
/// Initialize a groove joint.
CP_EXPORT cpGrooveJoint* cpGrooveJointInit(cpGrooveJoint *joint, cpBody *a, cpBody *b, cpVect groove_a, cpVect groove_b, cpVect anchorB);
/// Allocate and initialize a groove joint.
CP_EXPORT cpConstraint* cpGrooveJointNew(cpBody *a, cpBody *b, cpVect groove_a, cpVect groove_b, cpVect anchorB);

/// Get the first endpoint of the groove relative to the first body.
CP_EXPORT cpVect cpGrooveJointGetGrooveA(const cpConstraint *constraint);
/// Set the first endpoint of the groove relative to the first body.
CP_EXPORT void cpGrooveJointSetGrooveA(cpConstraint *constraint, cpVect grooveA);

/// Get the first endpoint of the groove relative to the first body.
CP_EXPORT cpVect cpGrooveJointGetGrooveB(const cpConstraint *constraint);
/// Set the first endpoint of the groove relative to the first body.
CP_EXPORT void cpGrooveJointSetGrooveB(cpConstraint *constraint, cpVect grooveB);

/// Get the location of the second anchor relative to the second body.
CP_EXPORT cpVect cpGrooveJointGetAnchorB(const cpConstraint *constraint);
/// Set the location of the second anchor relative to the second body.
CP_EXPORT void cpGrooveJointSetAnchorB(cpConstraint *constraint, cpVect anchorB);

/// @}
