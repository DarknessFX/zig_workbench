// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Scott Lembcke and Howling Moon Software

#include <string.h>

#include "chipmunk/chipmunk_private.h"


cpArray *
cpArrayNew(int size)
{
	cpArray *arr = (cpArray *)cpcalloc(1, sizeof(cpArray));
	
	arr->num = 0;
	arr->max = (size ? size : 4);
	arr->arr = (void **)cpcalloc(arr->max, sizeof(void*));
	
	return arr;
}

void
cpArrayFree(cpArray *arr)
{
	if(arr){
		cpfree(arr->arr);
		arr->arr = NULL;
		
		cpfree(arr);
	}
}

void
cpArrayPush(cpArray *arr, void *object)
{
	if(arr->num == arr->max){
		arr->max = 3*(arr->max + 1)/2;
		arr->arr = (void **)cprealloc(arr->arr, arr->max*sizeof(void*));
	}
	
	arr->arr[arr->num] = object;
	arr->num++;
}

void *
cpArrayPop(cpArray *arr)
{
	arr->num--;
	
	void *value = arr->arr[arr->num];
	arr->arr[arr->num] = NULL;
	
	return value;
}

void
cpArrayDeleteObj(cpArray *arr, void *obj)
{
	for(int i=0; i<arr->num; i++){
		if(arr->arr[i] == obj){
			arr->num--;
			
			arr->arr[i] = arr->arr[arr->num];
			arr->arr[arr->num] = NULL;
			
			return;
		}
	}
}

void
cpArrayFreeEach(cpArray *arr, void (freeFunc)(void*))
{
	for(int i=0; i<arr->num; i++) freeFunc(arr->arr[i]);
}

cpBool
cpArrayContains(cpArray *arr, void *ptr)
{
	for(int i=0; i<arr->num; i++)
		if(arr->arr[i] == ptr) return cpTrue;
	
	return cpFalse;
}
