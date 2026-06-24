// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpDampedRotarySpring cpDampedRotarySpring
/// @{

/// Check if a constraint is a damped rotary springs.
CP_EXPORT cpBool cpConstraintIsDampedRotarySpring(const cpConstraint *constraint);

/// Function type used for damped rotary spring force callbacks.
typedef cpFloat (*cpDampedRotarySpringTorqueFunc)(struct cpConstraint *spring, cpFloat relativeAngle);

/// Allocate a damped rotary spring.
CP_EXPORT cpDampedRotarySpring* cpDampedRotarySpringAlloc(void);
/// Initialize a damped rotary spring.
CP_EXPORT cpDampedRotarySpring* cpDampedRotarySpringInit(cpDampedRotarySpring *joint, cpBody *a, cpBody *b, cpFloat restAngle, cpFloat stiffness, cpFloat damping);
/// Allocate and initialize a damped rotary spring.
CP_EXPORT cpConstraint* cpDampedRotarySpringNew(cpBody *a, cpBody *b, cpFloat restAngle, cpFloat stiffness, cpFloat damping);

/// Get the rest length of the spring.
CP_EXPORT cpFloat cpDampedRotarySpringGetRestAngle(const cpConstraint *constraint);
/// Set the rest length of the spring.
CP_EXPORT void cpDampedRotarySpringSetRestAngle(cpConstraint *constraint, cpFloat restAngle);

/// Get the stiffness of the spring in force/distance.
CP_EXPORT cpFloat cpDampedRotarySpringGetStiffness(const cpConstraint *constraint);
/// Set the stiffness of the spring in force/distance.
CP_EXPORT void cpDampedRotarySpringSetStiffness(cpConstraint *constraint, cpFloat stiffness);

/// Get the damping of the spring.
CP_EXPORT cpFloat cpDampedRotarySpringGetDamping(const cpConstraint *constraint);
/// Set the damping of the spring.
CP_EXPORT void cpDampedRotarySpringSetDamping(cpConstraint *constraint, cpFloat damping);

/// Get the damping of the spring.
CP_EXPORT cpDampedRotarySpringTorqueFunc cpDampedRotarySpringGetSpringTorqueFunc(const cpConstraint *constraint);
/// Set the damping of the spring.
CP_EXPORT void cpDampedRotarySpringSetSpringTorqueFunc(cpConstraint *constraint, cpDampedRotarySpringTorqueFunc springTorqueFunc);

/// @}
