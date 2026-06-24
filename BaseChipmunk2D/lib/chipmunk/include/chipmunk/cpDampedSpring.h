// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpDampedSpring cpDampedSpring
/// @{

/// Check if a constraint is a slide joint.
CP_EXPORT cpBool cpConstraintIsDampedSpring(const cpConstraint *constraint);

/// Function type used for damped spring force callbacks.
typedef cpFloat (*cpDampedSpringForceFunc)(cpConstraint *spring, cpFloat dist);

/// Allocate a damped spring.
CP_EXPORT cpDampedSpring* cpDampedSpringAlloc(void);
/// Initialize a damped spring.
CP_EXPORT cpDampedSpring* cpDampedSpringInit(cpDampedSpring *joint, cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB, cpFloat restLength, cpFloat stiffness, cpFloat damping);
/// Allocate and initialize a damped spring.
CP_EXPORT cpConstraint* cpDampedSpringNew(cpBody *a, cpBody *b, cpVect anchorA, cpVect anchorB, cpFloat restLength, cpFloat stiffness, cpFloat damping);

/// Get the location of the first anchor relative to the first body.
CP_EXPORT cpVect cpDampedSpringGetAnchorA(const cpConstraint *constraint);
/// Set the location of the first anchor relative to the first body.
CP_EXPORT void cpDampedSpringSetAnchorA(cpConstraint *constraint, cpVect anchorA);

/// Get the location of the second anchor relative to the second body.
CP_EXPORT cpVect cpDampedSpringGetAnchorB(const cpConstraint *constraint);
/// Set the location of the second anchor relative to the second body.
CP_EXPORT void cpDampedSpringSetAnchorB(cpConstraint *constraint, cpVect anchorB);

/// Get the rest length of the spring.
CP_EXPORT cpFloat cpDampedSpringGetRestLength(const cpConstraint *constraint);
/// Set the rest length of the spring.
CP_EXPORT void cpDampedSpringSetRestLength(cpConstraint *constraint, cpFloat restLength);

/// Get the stiffness of the spring in force/distance.
CP_EXPORT cpFloat cpDampedSpringGetStiffness(const cpConstraint *constraint);
/// Set the stiffness of the spring in force/distance.
CP_EXPORT void cpDampedSpringSetStiffness(cpConstraint *constraint, cpFloat stiffness);

/// Get the damping of the spring.
CP_EXPORT cpFloat cpDampedSpringGetDamping(const cpConstraint *constraint);
/// Set the damping of the spring.
CP_EXPORT void cpDampedSpringSetDamping(cpConstraint *constraint, cpFloat damping);

/// Get the damping of the spring.
CP_EXPORT cpDampedSpringForceFunc cpDampedSpringGetSpringForceFunc(const cpConstraint *constraint);
/// Set the damping of the spring.
CP_EXPORT void cpDampedSpringSetSpringForceFunc(cpConstraint *constraint, cpDampedSpringForceFunc springForceFunc);

/// @}
