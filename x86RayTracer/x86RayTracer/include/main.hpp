#pragma once
#define WIN32_LEAN_AND_MEAN

#include <windows.h>

extern "C" int Render(unsigned long width, unsigned long height, float* screen,
                      float bgR, float bgG, float bgB,
                      int* primitives, float* camera, int* lights);