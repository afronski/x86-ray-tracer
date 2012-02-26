#include <SDL.h>
#include <iostream>
#include <sstream>

#include "main.hpp"
#include "InputFileParser.hpp"

// Default viewpport parameters.
ulong SCREEN_WIDTH		= 800;
ulong SCREEN_HEIGHT		= 600;
ulong SCREEN_BPP		= 32;
ulong SCREEN_COMPONENTS	= SCREEN_BPP / 8;

// Presentation time for popup window.
ulong PRESENTATION_TIME = 1000;

// Background color.
float BACKGROUND_R = 0.2f;
float BACKGROUND_G = 0.2f;
float BACKGROUND_B = 0.2f;

// Directories and filename.
std::string OUTPUT_FILENAME = "";
std::string INPUT_FILENAME= "";

// Clamping values to max and min colours value.
byte clampf(float val)
{
	if (val > 255.0f)
	{
		return 255;
	}
	
	if (val < 0.0f)
	{
		return 0;
	}

	return static_cast<byte>(val);
}

// Function which applies surface on screen.
void ApplySurface(int x, int y, SDL_Surface* source, SDL_Surface* destination, SDL_Rect* clip = 0)
{
    // Holds offsets.
    SDL_Rect offset;

    // Get offsets.
    offset.x = x;
    offset.y = y;

    // Blit.
    SDL_BlitSurface(source, clip, destination, &offset);
}

// Help for command line parameters.
void Help()
{
	std::cout << "Usage:                                                              " << std::endl;
	std::cout << " [scene RAY file] [output BMP file] [msPresentationTime]            " << std::endl;
	std::cout << "Scene file format:                                                  " << std::endl;
	std::cout << "     First line: [width] [height]                                   " << std::endl;
	std::cout << "     Second line: [bgR] [bgG] [bgB]                                 " << std::endl;
	std::cout << "     Third line: [cameraBiasX] [cameraBiasY]                        " << std::endl;
	std::cout << "Next lines describles primitives and lights:                        " << std::endl;
	std::cout << "pl [A] [B] [C] [D] [Red] [Green] [Blue]                             " << std::endl;
	std::cout << "   Adds plane Ax + By + Cz + D = 0 with RGB color                   " << std::endl;
	std::cout << "sp [x0] [y0] [z0] [radius] [Red] [Green] [Blue]                     " << std::endl;
	std::cout << "   Adds sphere with center x0, y0, z0) and radius, and RGB color    " << std::endl;
	std::cout << "cy [x0] [y0] [z0] [dx] [dy] [dz] [radius] [Red] [Green] [Blue]      " << std::endl;
	std::cout << "   Adds cylinder with center and RGB color                          " << std::endl;
	std::cout << "di [x0] [y0] [z0] [nx] [ny] [nz] [radius] [Red] [Green] [Blue]      " << std::endl;
	std::cout << "   Adds disc with center in (x0,y0,z0) and normal with RGB color    " << std::endl;
	std::cout << "om [x] [y] [z] [radius] [Red] [Green] [Blue]                        " << std::endl;
	std::cout << "   Adds point light with RGB color                                  " << std::endl;
	std::cout << "wo [nx] [ny] [nz] [Red] [Green] [Blue]                              " << std::endl;
	std::cout << "   Adds global light with direction (nx,ny,nz) with RGB color       " << std::endl;
	std::cout << "re [x] [y] [z] [nx] [ny] [nz] [inner] [outer] [radius] [R] [G] [B]  " << std::endl;
	std::cout << "   Adds reflector in (x,y,z) with RGB color                         " << std::endl;
	std::cout << std::endl;
}

// Procedure which handle command line parameters.
bool HandleCommandLine(int argc, char* args[])
{
	std::cout << "x86RayTracer                   (author: Wojtek 'afronski' Gawronski)" << std::endl;
	std::cout << "Contact: afronski@gmail.com                    Version: 0.4-sapphire" << std::endl;

	// If we have to small amount of arguments - display help.
	if (argc <= 3)
	{
		Help();
		return false;
	}
	else
	{
		// Parse command line.
		INPUT_FILENAME = args[1];
		INPUT_FILENAME = INPUT_FILENAME.substr(0, INPUT_FILENAME.find_first_of('.'));

		OUTPUT_FILENAME = args[2];
		OUTPUT_FILENAME = OUTPUT_FILENAME.substr(0, OUTPUT_FILENAME.find_first_of('.'));

		std::istringstream converter(args[3]);
		converter >> PRESENTATION_TIME;

		// Print informations.
		std::cout << "   Scene:             " << INPUT_FILENAME + ".ray" << std::endl;
		std::cout << "   Ouput:             " << OUTPUT_FILENAME + ".bmp" << std::endl;
		std::cout << "   Presentation time: " << PRESENTATION_TIME << std::endl;

		return true;
	}
}

int main(int argc, char* args[])
{
	if (HandleCommandLine(argc, args))
	{
		// Main screen surface.
		SDL_Surface* screen = 0;
		SDL_Surface* surface = 0;
		SDL_Surface* copy = 0;

		// Buffers for reading data from file.
		float* camera = new float[2];
		int* objects = 0;
		int* lights = 0;

		std::string input = INPUT_FILENAME + ".ray";
		if (!ReadInputFile(	input, objects, lights, camera,
							BACKGROUND_R, BACKGROUND_G, BACKGROUND_B,
							SCREEN_WIDTH, SCREEN_HEIGHT))
		{
			MessageBox(0, "Cannot read input file!", "InputFileParser::Error", MB_OK | MB_ICONERROR);
			return -1;
		}

		// SDL initialization.
		SDL_Init(SDL_INIT_EVERYTHING);
		SDL_WM_SetCaption("x86RayTracer", "x86RayTracer");

		screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, SDL_SWSURFACE);

		// Creates our own surfaces.
		surface = SDL_CreateRGBSurface(SDL_SWSURFACE, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, 0, 0, 0, 0);
		copy = SDL_CreateRGBSurface(SDL_SWSURFACE, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, 0, 0, 0, 0);

		// Measuring execution time.
		UINT64 ticksPerSecond = 1000, ticks, passTicks;
		if (!QueryPerformanceFrequency((LARGE_INTEGER*) &ticksPerSecond))
		{
			ticksPerSecond = 1000;
		}

		// Allocate memory for screen buffer.
		float* screenBuffer = (float*)_aligned_malloc(sizeof(float) * SCREEN_WIDTH * SCREEN_HEIGHT * SCREEN_COMPONENTS, 16);

		// Internal RayTracer method with time calculation.
		QueryPerformanceCounter((LARGE_INTEGER*) &ticks);
			Render(	SCREEN_WIDTH,
					SCREEN_HEIGHT,
					screenBuffer,
					BACKGROUND_R,
					BACKGROUND_G,
					BACKGROUND_B,
					objects,
					camera,
					lights);
		QueryPerformanceCounter((LARGE_INTEGER*) &passTicks);

		// Calculate time and rays/sec parameter.
		double time = static_cast<double>(passTicks - ticks) / static_cast<double>((static_cast<__int64>(ticksPerSecond)));
		double raysPerSec = static_cast<double>(SCREEN_WIDTH * SCREEN_HEIGHT) / time;
		double intersectionsPerSec = raysPerSec * objects[0];

		// Displaying informations.
		std::cout << std::fixed << "   Measured time:     " << time << "s" << std::endl;
		std::cout << std::fixed << "   Rays/s:            " << raysPerSec / 1000000.0 << "M" << std::endl;
		std::cout << std::fixed << "   Intersections/s:   " << intersectionsPerSec / 1000000.0 << "M" << std::endl;

		// If the surface must be locked.
		if (SDL_MUSTLOCK(surface))
		{
			// Lock the surface.
			SDL_LockSurface(surface);
		}

		// If the surface must be locked.
		if (SDL_MUSTLOCK(copy))
		{
			// Lock the surface.
			SDL_LockSurface(copy);
		}

		// Copy float buffer into surface (RGB to BGR).
		for (unsigned int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT * SCREEN_COMPONENTS; i += SCREEN_COMPONENTS)
		{
			((byte*)(copy->pixels))[i    ]	= clampf(screenBuffer[i + 2] * 255.0f);
			((byte*)(copy->pixels))[i + 1]	= clampf(screenBuffer[i + 1] * 255.0f);
			((byte*)(copy->pixels))[i + 2]	= clampf(screenBuffer[i    ] * 255.0f);
		}

		// Vertical flip.
		for (unsigned int x = 0; x < SCREEN_WIDTH; ++x)
		{
			for (unsigned int y = 0, ry = SCREEN_HEIGHT - 1; y < SCREEN_HEIGHT; --ry, ++y)
			{
				((Uint32*)(surface->pixels))[ry * SCREEN_WIDTH + x] = ((Uint32*)(copy->pixels))[y * SCREEN_WIDTH + x];
			}
		}

		// Unlock surface.
		if (SDL_MUSTLOCK(copy))
		{
			SDL_UnlockSurface(copy);
		}

		// Unlock surface.
		if (SDL_MUSTLOCK(surface))
		{
			SDL_UnlockSurface(surface);
		}

		// Apply surface on screen.
		ApplySurface(0, 0, surface, screen);

		if (SDL_Flip( screen ) == -1)
		{
			MessageBox(0, "Cannot flip screen buffer!", "x86RayTracer::Error", MB_OK | MB_ICONERROR);
			return -2;
		}

		// Show result with specified time.
		SDL_Delay(PRESENTATION_TIME);

		// Save "screen" surface to *.bmp file.
		std::string outputFilePath = OUTPUT_FILENAME + ".bmp";
		SDL_SaveBMP(screen, outputFilePath.c_str());

		// Clean up and quit.
		SDL_FreeSurface(screen);

		// Clean up buffers.
		delete [] camera;
		_aligned_free(screenBuffer);
		_aligned_free(lights);
		_aligned_free(objects);
	}

	SDL_Quit();

	return 0;
}