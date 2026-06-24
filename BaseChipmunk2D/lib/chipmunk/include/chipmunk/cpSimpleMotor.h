// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

/// @defgroup cpSimpleMotor cpSimpleMotor
/// @{

/// Opaque struct type for damped rotary springs.
typedef struct cpSimpleMotor cpSimpleMotor;

/// Check if a constraint is a damped rotary springs.
CP_EXPORT cpBool cpConstraintIsSimpleMotor(const cpConstraint *constraint);

/// Allocate a simple motor.
CP_EXPORT cpSimpleMotor* cpSimpleMotorAlloc(void);
/// initialize a simple motor.
CP_EXPORT cpSimpleMotor* cpSimpleMotorInit(cpSimpleMotor *joint, cpBody *a, cpBody *b, cpFloat rate);
/// Allocate and initialize a simple motor.
CP_EXPORT cpConstraint* cpSimpleMotorNew(cpBody *a, cpBody *b, cpFloat rate);

/// Get the rate of the motor.
CP_EXPORT cpFloat cpSimpleMotorGetRate(const cpConstraint *constraint);
/// Set the rate of the motor.
CP_EXPORT void cpSimpleMotorSetRate(cpConstraint *constraint, cpFloat rate);

/// @}
