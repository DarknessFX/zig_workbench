#include <stdio.h>


// DEVICE
extern "C" __global__ void _helloWorld(int arg1, float arg2) {
  printf("CUDA Function called with \narg1: %d\narg2: %.2f\n", arg1, arg2);
}

// HOST
// Helper function to be able to call << >> commands.
extern "C" __declspec(dllexport) void helloWorld(int arg1, float arg2) {
  _helloWorld<<<1, 1>>>(arg1, arg2);
  cudaDeviceSynchronize();
}