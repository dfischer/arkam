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
void setup_sdlvm(ArkVM* vm, int argc, char* argv[]);
ArkCode sdl_run(ArkVM* vm);
