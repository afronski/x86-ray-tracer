#include "InputFileParser.hpp"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <fstream>
#include <iostream>
#include <vector>
#include <sstream>

// Adding plane into objects table.
ulong AddPlane(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer = (int*)buffer;		// Int type buffer.
	float* fbuffer = (float*)buffer;	// Float type buffer.

	ibuffer[0]++;						// Increase object counter.
	ibuffer[3  + offset] = 0x100040;	// Magic number for plane.
	line >> fbuffer[4  + offset];		// A
	line >> fbuffer[5  + offset];		// B
	line >> fbuffer[6  + offset];		// C
	fbuffer[7  + offset] = 0.0f;		// -
	line >> fbuffer[8  + offset];		// D
	fbuffer[9  + offset] = 0.0f;		// -
	fbuffer[10 + offset] = 0.0f;		// -
	fbuffer[11 + offset] = 0.0f;		// -
	line >> fbuffer[12 + offset];		// R
	line >> fbuffer[13 + offset];		// G
	line >> fbuffer[14 + offset];		// B
	fbuffer[15 + offset] = 1.0f;		// A
	fbuffer[16 + offset] = 0.0f;		// -
	fbuffer[17 + offset] = 0.0f;		// -
	fbuffer[18 + offset] = 0.0f;		// -

	return 16;							// Returns offset.
}

// Adding ball into objects table.
ulong AddSphere(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer = (int*)buffer;		// Int type buffer.
	float* fbuffer = (float*)buffer;	// Float type buffer.

	ibuffer[0]++;						// Increase object counter.
	ibuffer[3  + offset] = 0x200040;	// Magic number for ball.
	line >> fbuffer[4  + offset];		// x
	line >> fbuffer[5  + offset];		// y
	line >> fbuffer[6  + offset];		// z
	fbuffer[7  + offset] = 0.0f;		// -
	line >> fbuffer[8  + offset];		// radius
	fbuffer[9  + offset] = 0.0f;		// -
	fbuffer[10 + offset] = 0.0f;		// -
	fbuffer[11 + offset] = 0.0f;		// -
	line >> fbuffer[12 + offset];		// R
	line >> fbuffer[13 + offset];		// G
	line >> fbuffer[14 + offset];		// B
	fbuffer[15 + offset] = 1.0f;		// A
	fbuffer[16 + offset] = 0.0f;		// -
	fbuffer[17 + offset] = 0.0f;		// -
	fbuffer[18 + offset] = 0.0f;		// -

	return 16;							// Returns offset.
}

// Adding cylinder into objects table.
ulong AddCylinder(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer = (int*)buffer;		// Int type buffer.
	float* fbuffer = (float*)buffer;	// Float type buffer.

	ibuffer[0]++;						// Increase object counter.
	ibuffer[3  + offset] = 0x300050;	// Magic number for ball.
	line >> fbuffer[4  + offset];		// x0
	line >> fbuffer[5  + offset];		// y0
	line >> fbuffer[6  + offset];		// z0
	fbuffer[7  + offset] = 0.0f;		// -
	line >> fbuffer[8  + offset];		// dx
	line >> fbuffer[9  + offset];		// dy
	line >> fbuffer[10 + offset];		// dz
	fbuffer[11 + offset] = 0.0f;		// -
	line >> fbuffer[12 + offset];		// Radius
	fbuffer[13 + offset] = 0.0f;		// -
	fbuffer[14 + offset] = 0.0f;		// -
	fbuffer[15 + offset] = 0.0f;		// -
	line >> fbuffer[16 + offset];		// R
	line >> fbuffer[17 + offset];		// G
	line >> fbuffer[18 + offset];		// B
	fbuffer[19 + offset] = 1.0f;		// A
	fbuffer[20 + offset] = 0.0f;		// -
	fbuffer[21 + offset] = 0.0f;		// -
	fbuffer[22 + offset] = 0.0f;		// -

	return 20;							// Returns offset.
}

// Adding cylinder into objects table.
ulong AddDisc(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer = (int*)buffer;								// Int type buffer.
	float* fbuffer = (float*)buffer;							// Float type buffer.
	float	R = 0.0f, x = 0.0f, y = 0.0f, z = 0.0f, 			// Radius, Position.
			nx = 0.0f, ny = 0.0f, nz = 0.0f;					// Normal.

	ibuffer[0]++;												// Increase object counter.
	ibuffer[3  + offset] = 0x400060;							// Magic number for ball.
	line >> x;
	fbuffer[4  + offset] = x;									// x
	line >> y;
	fbuffer[5  + offset] = y;									// y
	line >> z;
	fbuffer[6  + offset] = z;									// z
	fbuffer[7  + offset] = 0.0f;								// -
	line >> nx;
	fbuffer[8  + offset] = nx;									// nx
	line >> ny;
	fbuffer[9  + offset] = ny;									// ny
	line >> nz;
	fbuffer[10 + offset] = nz;									// nz
	fbuffer[11 + offset] = 0.0f;								// -
	fbuffer[12 + offset] = -x * nx - y * ny -z * nz;			// -x * nx - y * ny -z * nz
	fbuffer[13 + offset] = 0.0f;								// -
	fbuffer[14 + offset] = 0.0f;								// -
	fbuffer[15 + offset] = 0.0f;								// -
	line >> R;
	fbuffer[16 + offset] = R * R;								// Radius * Radius
	fbuffer[17 + offset] = 0.0f;								// -
	fbuffer[18 + offset] = 0.0f;								// -
	fbuffer[19 + offset] = 0.0f;								// -
	line >> fbuffer[20 + offset];								// R
	line >> fbuffer[21 + offset];								// G
	line >> fbuffer[22 + offset];								// B
	fbuffer[23  + offset] = 1.0f;								// A
	fbuffer[24  + offset] = 0.0f;								// -
	fbuffer[25  + offset] = 0.0f;								// -
	fbuffer[26  + offset] = 0.0f;								// -

	return 24;													// Returns offset.
}

// Adding omni light into table.
ulong AddOmniLight(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer=(int*)buffer;			// Int type buffer.
	float* fbuffer=(float*)buffer;		// Float type buffer.
	float R = 0.0f;						// Radius.

	ibuffer[0]++;						// Increase object counter.
	ibuffer[3  + offset] = 0x10030;		// Magic number for omni light.
	line >> fbuffer[4  + offset];		// x
	line >> fbuffer[5  + offset];		// y
	line >> fbuffer[6  + offset];		// z
	fbuffer[7  + offset] = 0.0f;		// -
	line >> R;
	line >> fbuffer[8  + offset];		// r
	line >> fbuffer[9  + offset];		// g
	line >> fbuffer[10 + offset];		// b
	fbuffer[11 + offset] = 1.0f;		// a
	fbuffer[12 + offset] = R;			// radius
	fbuffer[13 + offset] = 0.0f;		// -
	fbuffer[14 + offset] = 0.0f;		// -

	return 12;							// Returns offset.
}

// Adding world light into table.
ulong AddWorldLight(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer=(int*)buffer;			// Int type buffer.
	float* fbuffer=(float*)buffer;		// Float type buffer.

	ibuffer[0]++;						// Increase object counter.
	ibuffer[3  + offset] = 0x20030;		// Magic number for world light.
	line >> fbuffer[4  + offset];		// nx
	line >> fbuffer[5  + offset];		// ny
	line >> fbuffer[6  + offset];		// nz
	fbuffer[7  + offset] = 0.0f;		// -
	line >> fbuffer[8  + offset];		// r
	line >> fbuffer[9  + offset];		// g
	line >> fbuffer[10 + offset];		// b
	fbuffer[11 + offset] = 1.0f;		// a
	fbuffer[12 + offset] = 0.0f;		// -
	fbuffer[13 + offset] = 0.0f;		// -
	fbuffer[14 + offset] = 0.0f;		// -

	return 12;							// Returns offset.
}

// Adding spot light into table.
ulong AddSpotLight(void* buffer, ulong offset, std::stringstream& line)
{
	int* ibuffer=(int*)buffer;												// Int type buffer.
	float* fbuffer=(float*)buffer;											// Float type buffer.
	float	AngleIn = 0.0f,													// Angles for lighting cone.
			AngleOut = 0.0f;

	ibuffer[0]++;															// Increase object counter.
	ibuffer[3  + offset] = 0x30050;											// Magic number for spot light.
	line >> fbuffer[4  + offset];											// x
	line >> fbuffer[5  + offset];											// y
	line >> fbuffer[6  + offset];											// z
	fbuffer[7  + offset] = 0.0f;											// -
	line >> fbuffer[8  + offset];											// nx
	line >> fbuffer[9  + offset];											// ny
	line >> fbuffer[10 + offset];											// nz
	fbuffer[11 + offset] = 0.0f;											// -
	line >> AngleIn;
	line >> AngleOut;
	fbuffer[12 + offset] = cos(AngleOut * 0.008726646259971647884f);		// AngleIn
	fbuffer[13 + offset] = 0.0f;											// -	
	fbuffer[14 + offset] = cos(AngleIn * 0.008726646259971647884f);			// AngleOut
	fbuffer[15 + offset] = 0.0f;											// -
	line >> fbuffer[16  + offset];											// r
	line >> fbuffer[17  + offset];											// g
	line >> fbuffer[18  + offset];											// b
	fbuffer[19 + offset] = 1.0f;											// a
	line >> fbuffer[20  + offset];											// radius
	fbuffer[21  + offset] = 0.0f;											// -
	fbuffer[22  + offset] = 0.0f;											// -

	return 20;																// Returns offset.
}

// Reading input file.
bool ReadInputFile(std::string filename, int*& objects, int*& lights, float*& camera, float& R, float& G, float& B, ulong& width, ulong& height)
{
	std::ifstream inputFile(filename.c_str());
	bool fileGood = inputFile.good();
	std::vector<std::string> wholeFile;

	// Reserve memory for buffer.
	wholeFile.reserve(1000);

	if (fileGood)
	{
		char line[256];

		// Read whole file into buffer.
		while(true)
		{
			inputFile.getline(line, 256);
			wholeFile.push_back(line);

			if (inputFile.eof()) break;
		}
	}

	// Calculates sizes.
	int lengthLights = 0, lengthObjects = 0;
	std::string prefix = "";

	for(unsigned int i = 3; i < wholeFile.size(); ++i)
	{
		prefix = wholeFile[i].substr(0, 2);

		if (prefix == "om") { lengthLights += 12; continue; }
		if (prefix == "wo") { lengthLights += 12; continue; }
		if (prefix == "re") { lengthLights += 20; continue; }

		if (prefix == "sp") { lengthObjects += 16; continue; }
		if (prefix == "pl") { lengthObjects += 16; continue; }
		if (prefix == "cy") { lengthObjects += 20; continue; }
		if (prefix == "di") { lengthObjects += 24; continue; }
	}

	// Parse first 3 lines.
	std::stringstream converter_size(wholeFile[0]);
	converter_size >> width >> height;

	std::stringstream converter_background(wholeFile[1]);
	converter_background >> R >> G >> B;

	std::stringstream converter_camera(wholeFile[2]);
	converter_camera >> camera[0] >> camera[1];

	// SSE alignment allocation with clearing item counters.
	objects = (int *)_aligned_malloc(sizeof(int)*(lengthObjects + 4), 16);
	objects[0] = 0;

	lights = (int *)_aligned_malloc(sizeof(int)*(lengthLights + 4), 16);
	lights[0] = 0;

	// Filling buffers.
	ulong objectsOffset = 0, lightsOffset = 0;
	std::stringstream line_converter;

	for(unsigned int i = 3; i < wholeFile.size(); ++i)
	{
		if (!wholeFile[i].empty())
		{
			prefix = wholeFile[i].substr(0, 2);
		
			line_converter.clear();
			line_converter.str(wholeFile[i].substr(2));

			if (prefix == "om")
			{
				lightsOffset += AddOmniLight(lights, lightsOffset, line_converter);
				continue;
			}

			if (prefix == "wo")
			{
				lightsOffset += AddWorldLight(lights, lightsOffset, line_converter);
				continue;
			}

			if (prefix == "re")
			{
				lightsOffset += AddSpotLight(lights, lightsOffset, line_converter);
				continue;
			}

			if (prefix == "sp")
			{
				objectsOffset += AddSphere(objects, objectsOffset, line_converter);
				continue;
			}

			if (prefix == "pl")
			{
				objectsOffset += AddPlane(objects, objectsOffset, line_converter);
				continue;
			}

			if (prefix == "cy")
			{
				objectsOffset += AddCylinder(objects, objectsOffset, line_converter);
				continue;
			}

			if (prefix == "di")
			{
				objectsOffset += AddDisc(objects, objectsOffset, line_converter);
				continue;
			}
		}
	}

	return fileGood;
}