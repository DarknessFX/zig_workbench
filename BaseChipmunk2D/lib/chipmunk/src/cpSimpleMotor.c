// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

#include "chipmunk/chipmunk_private.h"

static void
preStep(cpSimpleMotor *joint, cpFloat dt)
{
	cpBody *a = joint->constraint.a;
	cpBody *b = joint->constraint.b;
	
	// calculate moment of inertia coefficient.
	joint->iSum = 1.0f/(a->i_inv + b->i_inv);
}

static void
applyCachedImpulse(cpSimpleMotor *joint, cpFloat dt_coef)
{
	cpBody *a = joint->constraint.a;
	cpBody *b = joint->constraint.b;
	
	cpFloat j = joint->jAcc*dt_coef;
	a->w -= j*a->i_inv;
	b->w += j*b->i_inv;
}

static void
applyImpulse(cpSimpleMotor *joint, cpFloat dt)
{
	cpBody *a = joint->constraint.a;
	cpBody *b = joint->constraint.b;
	
	// compute relative rotational velocity
	cpFloat wr = b->w - a->w + joint->rate;
	
	cpFloat jMax = joint->constraint.maxForce*dt;
	
	// compute normal impulse	
	cpFloat j = -wr*joint->iSum;
	cpFloat jOld = joint->jAcc;
	joint->jAcc = cpfclamp(jOld + j, -jMax, jMax);
	j = joint->jAcc - jOld;
	
	// apply impulse
	a->w -= j*a->i_inv;
	b->w += j*b->i_inv;
}

static cpFloat
getImpulse(cpSimpleMotor *joint)
{
	return cpfabs(joint->jAcc);
}

static const cpConstraintClass klass = {
	(cpConstraintPreStepImpl)preStep,
	(cpConstraintApplyCachedImpulseImpl)applyCachedImpulse,
	(cpConstraintApplyImpulseImpl)applyImpulse,
	(cpConstraintGetImpulseImpl)getImpulse,
};

cpSimpleMotor *
cpSimpleMotorAlloc(void)
{
	return (cpSimpleMotor *)cpcalloc(1, sizeof(cpSimpleMotor));
}

cpSimpleMotor *
cpSimpleMotorInit(cpSimpleMotor *joint, cpBody *a, cpBody *b, cpFloat rate)
{
	cpConstraintInit((cpConstraint *)joint, &klass, a, b);
	
	joint->rate = rate;
	
	joint->jAcc = 0.0f;
	
	return joint;
}

cpConstraint *
cpSimpleMotorNew(cpBody *a, cpBody *b, cpFloat rate)
{
	return (cpConstraint *)cpSimpleMotorInit(cpSimpleMotorAlloc(), a, b, rate);
}

cpBool
cpConstraintIsSimpleMotor(const cpConstraint *constraint)
{
	return (constraint->klass == &klass);
}

cpFloat
cpSimpleMotorGetRate(const cpConstraint *constraint)
{
	cpAssertHard(cpConstraintIsSimpleMotor(constraint), "Constraint is not a SimpleMotor.");
	return ((cpSimpleMotor *)constraint)->rate;
}

void
cpSimpleMotorSetRate(cpConstraint *constraint, cpFloat rate)
{
	cpAssertHard(cpConstraintIsSimpleMotor(constraint), "Constraint is not a SimpleMotor.");
	cpConstraintActivateBodies(constraint);
	((cpSimpleMotor *)constraint)->rate = rate;
}
