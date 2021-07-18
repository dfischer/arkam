#include "arkvm.h"
#include "standard_main.h"
#include "sdl_fmsynth.h"
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <stdarg.h>
#include <getopt.h>
#include <SDL2/SDL.h>

void set_zoom(int z);
void setup_sdlvm(ArkamVM* vm, int argc, char* argv[]);
ArkamCode sdl_run(ArkamVM* vm);
