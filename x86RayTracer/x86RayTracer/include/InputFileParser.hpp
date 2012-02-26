#pragma once

#include <string>

typedef unsigned char byte;
typedef unsigned long ulong;

// Reading objects from file.
bool ReadInputFile(std::string filename, int*& objects, int*& lights, float*& camera, float& R, float& G, float& B, ulong& width, ulong& height);